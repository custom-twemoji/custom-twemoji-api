# frozen_string_literal: true

# Conversion of svgpath
# https://github.com/fontello/svgpath/blob/2.3.1/lib/matrix.js

# combine 2 matrixes
# m1, m2 - [a, b, c, d, e, g]
#
def combine(m1, m2)
  [
    m1[0] * m2[0] + m1[2] * m2[1],
    m1[1] * m2[0] + m1[3] * m2[1],
    m1[0] * m2[2] + m1[2] * m2[3],
    m1[1] * m2[2] + m1[3] * m2[3],
    m1[0] * m2[4] + m1[2] * m2[5] + m1[4],
    m1[1] * m2[4] + m1[3] * m2[5] + m1[5]
  ]
end


class Matrix
  attr_accessor :queue, :cache

  def initialize
    return new Matrix() unless self.instance_of? Matrix
    @queue = []  # list of matrixes to apply
    @cache = nil # combined matrix cache
  end

  def matrix(m)
    if (
      m[0] == 1 &&
      m[1] == 0 &&
      m[2] == 0 &&
      m[3] == 1 &&
      m[4] == 0 &&
      m[5] == 0
    )
      return self
    end

    @cache = nil
    @queue.push(m)

    self
  end

  def translate(tx, ty)
    if (tx != 0 || ty != 0)
      @cache = nil
      @queue.push([ 1, 0, 0, 1, tx, ty ])
    end

    self
  end

  def scale(sx, sy)
    if (sx != 1 || sy != 1)
      @cache = nil
      @queue.push([ sx, 0, 0, sy, 0, 0 ])
    end

    self
  end

  def rotate(angle, rx, ry)
    if angle != 0
      translate(rx, ry)

      rad = angle * Math.PI / 180
      cos = Math.cos(rad)
      sin = Math.sin(rad)

      @queue.push([ cos, sin, -sin, cos, 0, 0 ])
      @cache = nil

      translate(-rx, -ry)
    end

    self
  end

  def skewX(angle)
    if angle != 0
      @cache = nil
      @queue.push([ 1, 0, Math.tan(angle * Math.PI / 180), 1, 0, 0 ])
    end

    self
  end


  def skewY(angle)
    if angle != 0
      @cache = nil
      @queue.push([ 1, Math.tan(angle * Math.PI / 180), 0, 1, 0, 0 ])
    end

    self
  end


  # Flatten queue
  def toArray()
    return @cache if @cache

    if @queue.length == 0
      @cache = [ 1, 0, 0, 1, 0, 0 ]
      return @cache
    end

    @cache = @queue[0]

    return @cache if @queue.length == 1

    (1..@queue.length-1).each do |i|
      @cache = combine(@cache, @queue[i])
    end

    @cache
  end

  # Apply list of matrixes to (x,y) point.
  # If `isRelative` set, `translate` component of matrix will be skipped
  def calc(x, y, isRelative)
    # Don't change point on empty transforms queue
    return [ x, y ] if @queue.length == 0

    # Calculate final matrix, if not exists
    #
    # NB. if you deside to apply transforms to point one-by-one,
    # they should be taken in reverse order

    @cache = toArray() unless @cache
    m = @cache

    # Apply matrix to point
    [
      x * m[0] + y * m[2] + (isRelative ? 0 : m[4]),
      x * m[1] + y * m[3] + (isRelative ? 0 : m[5])
    ]
  end
end
