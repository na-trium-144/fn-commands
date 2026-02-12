local M = {}

-- ---------------------------------------------------------
-- Helper Functions
-- ---------------------------------------------------------

local function copyStep(s)
  return {
    fourth = s.fourth,
    numerator = s.numerator,
    denominator = s.denominator,
  }
end

local function gcd(a, b)
  while b ~= 0 do
    a, b = b, a % b
  end
  return a
end

local function stepSimplify(s)
  local integerPart = math.floor(s.numerator / s.denominator)
  s.fourth = s.fourth + integerPart
  s.numerator = s.numerator - (integerPart * s.denominator)

  if s.numerator > 0 then
    local common = gcd(s.numerator, s.denominator)
    s.numerator = s.numerator / common
    s.denominator = s.denominator / common
  end

  if s.numerator == 0 then
    s.denominator = 1
  end

  return {
    fourth = s.fourth,
    numerator = s.numerator,
    denominator = s.denominator,
  }
end

local function stepAdd(s1, s2)
  local sa = {
    fourth = s1.fourth + s2.fourth,
    numerator = (s1.numerator * s2.denominator) + (s2.numerator * s1.denominator),
    denominator = s1.denominator * s2.denominator,
  }
  return stepSimplify(sa)
end

local function isInteger(n)
  return type(n) == "number" and math.floor(n) == n
end

-- ---------------------------------------------------------
-- State Management (Initialization)
-- ---------------------------------------------------------

function M.fnNewState()
  return {
    notes = {},
    rest = {},
    signature = {},
    bpmChanges = {},
    speedChanges = {},
    step = {
      fourth = 0,
      numerator = 0,
      denominator = 1,
    },
  }
end
M.fnState = M.fnNewState()

-- ---------------------------------------------------------
-- Main Functions
-- ---------------------------------------------------------

function M.Note(hitX, hitVX, hitVY, big, fall)
  M.NoteStatic(nil, hitX, hitVX, hitVY, big, fall)
end
function M.NoteStatic(line, hitX, hitVX, hitVY, big, fall)
  if fall == nil and big ~= nil then
    fall = false
  end

  if
    (type(line) == "number" or line == nil)
    and type(hitX) == "number"
    and type(hitVX) == "number"
    and type(hitVY) == "number"
    and type(big) == "boolean"
    and type(fall) == "boolean"
  then
    table.insert(M.fnState.notes, {
      hitX = hitX,
      hitVX = hitVX,
      hitVY = hitVY,
      big = big,
      step = copyStep(M.fnState.step),
      luaLine = line,
      fall = fall,
    })
  else
    error("invalid argument for Note()")
  end
end

function M.Step(num, den)
  M.StepStatic(nil, num, den)
end
function M.StepStatic(line, num, den)
  if
    (type(line) == "number" or line == nil)
    and type(num) == "number"
    and type(den) == "number"
    and num >= 0
    and isInteger(num)
    and den > 0
    and isInteger(den)
  then
    local duration = {
      fourth = 0,
      numerator = num * 4,
      denominator = den,
    }

    table.insert(M.fnState.rest, {
      begin = copyStep(M.fnState.step),
      duration = duration,
      luaLine = line,
    })

    M.fnState.step = stepAdd(M.fnState.step, duration)
  else
    error("invalid argument for Step()")
  end
end

function M.Beat(bars, offsetNum, offsetDen)
  M.BeatStatic(nil, bars, offsetNum, offsetDen)
end
function M.BeatStatic(line, bars, offsetNum, offsetDen)
  -- デフォルト引数の処理
  if offsetNum == nil and offsetDen == nil then
    offsetNum = 0
    offsetDen = 1
  end

  -- barsの構造チェック (Array<Array<number>> かつ 値が 4,8,16)
  local isBarsValid = type(bars) == "table"
  if isBarsValid then
    for _, subArr in ipairs(bars) do
      if type(subArr) ~= "table" then
        isBarsValid = false
        break
      end
      for _, val in ipairs(subArr) do
        if val ~= 4 and val ~= 8 and val ~= 16 then
          isBarsValid = false
          break
        end
      end
      if not isBarsValid then
        break
      end
    end
  end

  -- バリデーション
  if
    (type(line) == "number" or line == nil)
    and isBarsValid
    and type(offsetNum) == "number"
    and offsetNum >= 0
    and type(offsetDen) == "number"
    and offsetDen > 0
  then
    table.insert(M.fnState.signature, {
      bars = bars,
      offset = stepSimplify({
        fourth = 0,
        numerator = offsetNum * 4,
        denominator = offsetDen,
      }),
      step = copyStep(M.fnState.step),
      barNum = 0,
      luaLine = line,
    })
  else
    error("invalid argument for Beat()")
  end
end

function M.BPM(bpm)
  M.BPMStatic(nil, bpm)
end
function M.BPMStatic(line, bpm)
  if (type(line) == "number" or line == nil) and type(bpm) == "number" and bpm > 0 then
    table.insert(M.fnState.bpmChanges, {
      bpm = bpm,
      step = copyStep(M.fnState.step),
      timeSec = 0,
      luaLine = line,
    })
  else
    error("invalid argument for BPM()")
  end
end

function M.Accel(speed)
  M.AccelStatic(nil, speed)
end
function M.AccelStatic(line, speed)
  if (type(line) == "number" or line == nil) and type(speed) == "number" then
    table.insert(M.fnState.speedChanges, {
      bpm = speed,
      step = copyStep(M.fnState.step),
      timeSec = 0,
      luaLine = line,
      interp = false,
    })
  else
    error("invalid argument for Accel()")
  end
end

function M.AccelEnd(speed)
  M.AccelEndStatic(nil, speed)
end
function M.AccelEndStatic(line, speed)
  if (type(line) == "number" or line == nil) and type(speed) == "number" then
    table.insert(M.fnState.speedChanges, {
      bpm = speed,
      step = copyStep(M.fnState.step),
      timeSec = 0,
      luaLine = line,
      interp = true,
    })
  else
    error("invalid argument for Accel()") -- 元コードのエラーメッセージに準拠
  end
end

-- Setup Globals

_G.fnState = M.fnState
_G.fnNewState = M.fnNewState

_G.Note = M.Note
_G.NoteStatic = M.NoteStatic
_G.Step = M.Step
_G.StepStatic = M.StepStatic
_G.Beat = M.Beat
_G.BeatStatic = M.BeatStatic
_G.BPM = M.BPM
_G.BPMStatic = M.BPMStatic
_G.Accel = M.Accel
_G.AccelStatic = M.AccelStatic
_G.AccelEnd = M.AccelEnd
_G.AccelEndStatic = M.AccelEndStatic

return M
