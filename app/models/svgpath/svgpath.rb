# frozen_string_literal: true

# Conversion of svgpath
# https://github.com/fontello/svgpath/blob/2.3.1/lib/svgpath.js

require_relative 'path_parse'
# Seems unused
# require_relative 'transform_parse'
require_relative 'matrix'
# Seems unused
# require_relative 'a2c'
require_relative 'ellipse'

class Float
  def prettify
    to_i == self ? to_i : self
  end
end

class String
  def prettify
    self
  end
end

class Integer
  def prettify
    self
  end
end

class SvgPath
  attr_accessor :segments, :err, :stack

  def initialize(path)
    return SvgPath.new(path) unless self.instance_of? SvgPath

    pstate = pathParse(path)

    # Array of path segments.
    # Each segment is array [command, param1, param2, ...]
    @segments = pstate[:segments]

    # Error message on parse error.
    @err = pstate[:err]

    # Transforms stack for lazy evaluation
    @stack = []
  end

  def abs_proc(s, index, x, y)
    name = s[0]
    nameUC = name.upcase

    # Skip absolute commands
    return if name == nameUC

    s[0] = nameUC

    case name
    when 'v'
      # v has shifted coords parity
      s[1] += y
      return
    when 'a'
      # ARC is: ['A', rx, ry, x-axis-rotation, large-arc-flag, sweep-flag, x, y]
      # touch x, y only
      s[6] += x
      s[7] += y
      return
    else
      (1..s.length-1).each do |i|
        # odd values are X, even - Y
        s[i] += (i % 2 == 0) ? y : x
      end
    end

    self
  end

  # Converts segments from relative to absolute
  def abs
    iterate(true, method(:abs_proc))

    self
  end

  def to_s
    elements = []

    evaluateStack()

    (0..@segments.length-1).each do |i|
      # remove repeating commands names
      cmd = @segments[i][0]
      skipCmd =
        i > 0 &&
        cmd != 'm' &&
        cmd != 'M' &&
        cmd == @segments[i - 1][0]
      elements = elements.concat(
        skipCmd ? @segments[i][1..-1] : @segments[i]
      )
    end

    # Optimizations: remove spaces around commands & before `-`
    #
    # We could also remove leading zeros for `0.5`-like values,
    # but their count is too small to spend time for.
    # elements.join(' ')
    #   .replace(/ ?([achlmqrstvz]) ?/gi, '$1')
    #   .replace(/ \-/g, '-')
    # workaround for FontForge SVG importing bug
    #   .replace(/zm/g, 'z m');

    elements = elements.map(&:prettify).join(' ')
    elements.gsub!(/ ?[achlmqrstvz] ?/i) { |found| found.delete(' ') }
    elements.gsub!(/ -/) { |found| found.delete(' ') }
    elements.gsub!(/zm/) { |found| found.chars.join(' ') }
    elements
  end

  private

  def matrix_proc(s, index, x, y)
    case s[0]
    # Process 'asymmetric' commands separately
    when 'v'
      p      = m.calc(0, s[1], true)
      result = (p[0] === 0) ? [ 'v', p[1] ] : [ 'l', p[0], p[1] ]
    when 'V'
      p      = m.calc(x, s[1], false)
      result = (p[0] === m.calc(x, y, false)[0]) ? [ 'V', p[1] ] : [ 'L', p[0], p[1] ]
    when 'h'
      p      = m.calc(s[1], 0, true)
      result = (p[1] === 0) ? [ 'h', p[0] ] : [ 'l', p[0], p[1] ]
    when 'H'
      p      = m.calc(s[1], y, false)
      result = (p[1] === m.calc(x, y, false)[1]) ? [ 'H', p[0] ] : [ 'L', p[0], p[1] ]
    when 'a', 'A'
      # ARC is: ['A', rx, ry, x-axis-rotation, large-arc-flag, sweep-flag, x, y]

      # Drop segment if arc is empty (end point === start point)
      # if ((s[0] === 'A' && s[6] === x && s[7] === y) ||
      #     (s[0] === 'a' && s[6] === 0 && s[7] === 0)) {
      #   return [];
      # }

      # Transform rx, ry and the x-axis-rotation
      ma = Array(m)
      e = ellipse(s[1], s[2], s[3]).transform(ma)

      # flip sweep-flag if matrix is not orientation-preserving
      if (ma[0] * ma[3] - ma[1] * ma[2] < 0)
        s[5] = s[5] ? '0' : '1'
      end

      # Transform end point as usual (without translation for relative notation)
      p = m.calc(s[6], s[7], s[0] === 'a')

      # Empty arcs can be ignored by renderer, but should not be dropped
      # to avoid collisions with `S A S` and so on. Replace with empty line.
      if (
        (s[0] === 'A' && s[6] === x && s[7] === y) ||
        (s[0] === 'a' && s[6] === 0 && s[7] === 0)
      )
        result = [ s[0] === 'a' ? 'l' : 'L', p[0], p[1] ]
      end

      # if the resulting ellipse is (almost) a segment ...
      if e.isDegenerate()
        # replace the arc by a line
        result = [ s[0] === 'a' ? 'l' : 'L', p[0], p[1] ]
      else
        # if it is a real ellipse
        # s[0], s[4] and s[5] are not modified
        result = [ s[0], e.rx, e.ry, e.ax, s[4], s[5], p[0], p[1] ]
      end
    when 'm'
      # Edge case. The very first `m` should be processed as absolute, if happens.
      # Make sense for coord shift transforms.
      isRelative = index > 0

      p = m.calc(s[1], s[2], isRelative)
      result = [ 'm', p[0], p[1] ]
    else
      name       = s[0]
      result     = [name]
      isRelative = (name.downcase === name)

      # Apply transformations to the segment
      (1..s.length-1).step(2) do |i|
        p = m.calc(s[i], s[i + 1], isRelative)
        result.push(p[0], p[1])
      end
    end

    @segments[index] = result
  end

  def matrix(m)
    # Quick leave for empty matrix
    return unless m.queue.length > 0

    iterate(true, method(:matrix_proc))
  end

  # Apply stacked commands
  def evaluateStack
    return unless @stack.length > 0

    if @stack.length == 1
      matrix(@stack[0])
      @stack = []
      return
    end

    m = Matrix.new
    i = @stack.length

    while (i >= 0) do
      m.matrix(Array(@stack[i]))

      i -= 1
    end

    matrix(m)
    @stack = []
  end

  # Apply iterator function to all segments. If function returns result,
  # current segment will be replaced to array of returned segments.
  # If empty array is returned, current segment will be deleted.
  def iterate(keepLazyStack, iterator)
    segments = @segments
    replacements = Hash.new
    needReplace = false
    lastX = 0
    lastY = 0
    countourStartX = 0
    countourStartY = 0

    evaluateStack() unless keepLazyStack

    segments.each_with_index do |s, index|
      res = iterator.call(s, index, lastX, lastY)

      if res.kind_of?(Array)
        replacements[index] = res
        needReplace = true
      end

      isRelative = (s[0] == s[0].downcase)

      # calculate absolute X and Y
      case s[0]
      when 'm', 'M'
        lastX = s[1] + (isRelative ? lastX : 0)
        lastY = s[2] + (isRelative ? lastY : 0)
        countourStartX = lastX
        countourStartY = lastY
        next
      when 'h', 'H'
        lastX = s[1] + (isRelative ? lastX : 0)
        next
      when 'v', 'V'
        lastY = s[1] + (isRelative ? lastY : 0)
        next
      when 'z', 'Z'
        # That make sense for multiple contours
        lastX = countourStartX
        lastY = countourStartY
        next
      else
        lastX = s[s.length - 2] + (isRelative ? lastX : 0)
        lastY = s[s.length - 1] + (isRelative ? lastY : 0)
      end
    end

    # Replace segments if iterator return results
    return self unless needReplace

    newSegments = []

    (0..segments.length-1).each do |i|
      # May be wrong
      if (defined?(replacements[i]) != nil)
        (0..replacements[i].length).each do |j|
          newSegments.push(replacements[i][j])
        end
      else
        newSegments.push(segments[i])
      end
    end

    @segments = newSegments

    self
  end
end
