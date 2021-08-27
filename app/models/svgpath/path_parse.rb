# frozen_string_literal: true

# Conversion of svgpath
# https://github.com/fontello/svgpath/blob/2.3.1/lib/path_parse.js

PARAM_COUNTS = {
  'a' => 7,
  'c' => 6,
  'h' => 1,
  'l' => 2,
  'm' => 2,
  'r' => 4,
  'q' => 4,
  's' => 4,
  't' => 2,
  'v' => 1,
  'z' => 0
}

SPECIAL_SPACES = [
  0x1680, 0x180E, 0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005, 0x2006,
  0x2007, 0x2008, 0x2009, 0x200A, 0x202F, 0x205F, 0x3000, 0xFEFF
]

# Returns array of segments:
# [
#   [ command, coord1, coord2, ... ]
# ]
def pathParse(svgPath)
  state = State.new(svgPath);
  max = state.max;

  skipSpaces(state)

  while (
    state.index < max &&
    (state.err.length == 0 || defined?(state.err.length).nil?)
  ) do
    scanSegment(state)
  end

  if state.err.length > 0
    state.result = []
  elsif state.result.length > 0
    if 'mM'.index(state.result[0][0]) < 0
      state.err = 'SvgPath: string should start with `M` or `m`'
      state.result = []
    else
      state.result[0][0] = 'M'
    end
  end

  {
    err: state.err,
    segments: state.result
  }
end

private

def isSpace(ch)
  return (ch == 0x0A) || (ch == 0x0D) || (ch == 0x2028) || (ch == 0x2029) || # Line terminators
    # White spaces
    (ch == 0x20) || (ch == 0x09) || (ch == 0x0B) || (ch == 0x0C) || (ch == 0xA0) ||
    (ch >= 0x1680 && SPECIAL_SPACES.index(ch) >= 0)
end

def isCommand(code)
  code_to_check = (code | 0x20)
  case code_to_check
  # m, z, l, v, c, s, q, t, a, r
  when 0x6D, 0x7A, 0x6C, 0x68, 0x76, 0x63, 0x73, 0x71, 0x74, 0x61, 0x72
    true
  else
    false
  end
end

def isArc(code)
  (code | 0x20) == 0x61
end

def isDigit(code)
  # 0..9
  (code >= 48 && code <= 57)
end

def isDigitStart(code)
  (code >= 48 && code <= 57) || # 0..9
    code == 0x2B || # +
    code == 0x2D || # -
    code == 0x2E # .
end

class State
  attr_accessor :index, :path, :max, :result, :param, :err, :segmentStart, :data

  def initialize(path)
    @index  = 0
    @path   = path
    @max    = path.length
    @result = []
    @param  = 0.0
    @err    = ''
    @segmentStart = 0
    @data   = []
  end
end

def skipSpaces(state)
  while (state.index < state.max && isSpace(state.path[state.index].ord)) do
    state.index += 1
  end
end

def scanFlag(state)
  ch = state.path[state.index].ord

  if ch == 0x30 # 0
    state.param = 0
    state.index += 1
    return
  end

  if ch == 0x31 # 1
    state.param = 1
    state.index += 1
    return
  end

  state.err = "SvgPath: arc flag can be 0 or 1 only (at pos #{state.index})"
end

def scanParam(state)
  start = state.index
  index = start
  max = state.max
  zeroFirst = false
  hasCeiling = false
  hasDecimal = false
  hasDot = false

  if index >= max
    state.err = "SvgPath: missed param (at pos #{index})"
    return
  end
  ch = state.path[index].ord

  if (
    ch == 0x2B || # +
    ch == 0x2D # -
  )
    index += 1
    ch = (index < max) ? state.path[index].ord : 0
  end

  # This logic is shamelessly borrowed from Esprima
  # https://github.com/ariya/esprimas
  #
  if (
    !isDigit(ch) &&
    ch != 0x2E # .
  )
    state.err = "SvgPath: param should start with 0..9 or `.` (at pos #{index})"
    return
  end

  if ch != 0x2E # .
    zeroFirst = (ch == 0x30) # 0
    index += 1

    ch = (index < max) ? state.path[index].ord : 0

    if (zeroFirst && index < max)
      # decimal number starts with '0' such as '09' is illegal.
      if (ch && isDigit(ch))
        state.err = "SvgPath: numbers started with `0` such as `09` are illegal (at pos #{start})"
        return
      end
    end

    while (index < max && isDigit(state.path[index].ord)) do
      index += 1
      hasCeiling = true
    end
    ch = (index < max) ? state.path[index].ord : 0
  end

  if ch == 0x2E # .
    hasDot = true
    index += 1
    while (
      !(state.path[index].nil?) &&
      isDigit(state.path[index].ord)
    ) do
      index += 1
      hasDecimal = true
    end

    ch = (index < max) ? state.path[index].ord : 0
  end

  if (
    ch == 0x65 || # e
    ch == 0x45 # E
  )
    if (hasDot && !hasCeiling && !hasDecimal)
      state.err = "SvgPath: invalid float exponent (at pos #{index})"
      return
    end

    index += 1

    ch = (index < max) ? state.path[index].ord : 0
    if (
      ch == 0x2B || # +
      ch == 0x2D # -
    )
      index += 1
    end
    if (index < max && isDigit(state.path[index].ord))
      while (index < max && isDigit(state.path[index].ord)) do
        index += 1
      end
    else
      state.err = "SvgPath: invalid float exponent (at pos #{index})"
      return
    end
  end

  state.index = index
  state.param = Float(state.path[start..index-1]) + 0.0
end

class Array
  def splice(start, len, *replace)
    ret = self[start, len]
    self[start, len] = replace
    ret
  end
end

def finalizeSegment(state)
  # Process duplicated commands (without command name)

  # This logic is shamelessly borrowed from Raphael
  # https://github.com/DmitryBaranovskiy/raphael/
  #
  cmd   = state.path[state.segmentStart]
  cmdLC = cmd.downcase
  params = state.data

  if (cmdLC == 'm' && params.length > 2)
    state.result.push([ cmd, params[0], params[1] ])
    params = params[2..-1]
    cmdLC = 'l'
    cmd = (cmd == 'm') ? 'l' : 'L'
  end

  if cmdLC == 'r'
    state.result.push([ cmd ].concat(params))
  else
    while params.length >= PARAM_COUNTS[cmdLC] do
      state.result.push(
        [ cmd ].concat(
          params.splice(0, PARAM_COUNTS[cmdLC])
        )
      )
      break if PARAM_COUNTS[cmdLC] == 0
    end
  end
end

def scanSegment(state)
  max = state.max

  state.segmentStart = state.index
  cmdCode = state.path[state.index].ord
  is_arc = isArc(cmdCode)

  unless isCommand(cmdCode)
    state.err = "SvgPath: bad command #{state.path[state.index]} (at pos #{state.index})"
    return
  end

  need_params = PARAM_COUNTS[state.path[state.index].downcase]

  state.index += 1
  skipSpaces(state)

  state.data = []

  unless need_params
    # Z
    finalizeSegment(state)
    return
  end

  comma_found = false

  while (true) do
    for i in (need_params).downto(1)
      if (is_arc && (i == 3 || i == 4))
        scanFlag(state)
      else
        scanParam(state)
      end

      return if state.err.length > 0
      state.data.push(state.param)

      skipSpaces(state)
      comma_found = false

      if (
        state.index < max &&
        state.path[state.index].ord == 0x2C # ,
      )
        state.index += 1
        skipSpaces(state)
        comma_found = true
      end
    end

    # after ',' param is mandatory
    next if comma_found

    break if state.index >= state.max

    # Stop on next segment
    break unless isDigitStart(state.path[state.index].ord)
  end

  finalizeSegment(state)
end
