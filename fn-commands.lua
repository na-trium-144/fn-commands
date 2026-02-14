--[[
MIT License

Copyright (c) 2026 na-trium-144

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local M = {}

-- should match with module version (the version in package.json and git tag)
M.version = "0.1.0"

-- should match with the latest chart version of Falling Nikochan API
M.chartVersion = 15

local function fileVersionSupported(major, minor)
  local thisMajor, thisMinor = string.match(M.version, "(%d+)%.(%d+)")
  return tonumber(major) == tonumber(thisMajor) and tonumber(minor) <= tonumber(thisMinor)
end

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

local function stepZero()
  return { fourth = 0, numerator = 0, denominator = 1 }
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

function M.init()
  M.state = {
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
  _G.fnState = M.state
end
_G.fnInit = M.init

M.init()

-- parse chart file and return in ChartEdit format
function M.chart(obj)
  local objMajor, objMinor = string.match(obj.version, "(%d+)%.(%d+)")
  if not fileVersionSupported(objMajor, objMinor) then
    error("fn-commands version " .. M.version .. " cannot load chart file version " .. obj.version)
  end
  obj.falling = "nikochan"
  obj.ver = M.chartVersion
  obj.version = nil
  obj.levelsFreeze = {}
  for i = 1, #obj.levels do
    M.init()
    obj.levels[i].content()
    table.insert(obj.levelsFreeze, {
      notes = M.state.notes,
      rest = M.state.rest,
      bpmChanges = M.state.bpmChanges,
      speedChanges = M.state.speedChanges,
      signature = M.state.signature,
    })
    obj.levels[i].content = nil
  end
  obj.levelsMeta = obj.levels
  obj.levels = nil
  obj.published = false
  obj.locale = "" -- actually unused
  -- obj.lua needs to be set manually.
  return obj
end
_G.fnChart = M.chart

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
    table.insert(M.state.notes, {
      hitX = hitX,
      hitVX = hitVX,
      hitVY = hitVY,
      big = big,
      step = copyStep(M.state.step),
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

    table.insert(M.state.rest, {
      begin = copyStep(M.state.step),
      duration = duration,
      luaLine = line,
    })

    M.state.step = stepAdd(M.state.step, duration)
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
    table.insert(M.state.signature, {
      bars = bars,
      offset = stepSimplify({
        fourth = 0,
        numerator = offsetNum * 4,
        denominator = offsetDen,
      }),
      step = copyStep(M.state.step),
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
    table.insert(M.state.bpmChanges, {
      bpm = bpm,
      step = copyStep(M.state.step),
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
    table.insert(M.state.speedChanges, {
      bpm = speed,
      step = copyStep(M.state.step),
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
    table.insert(M.state.speedChanges, {
      bpm = speed,
      step = copyStep(M.state.step),
      timeSec = 0,
      luaLine = line,
      interp = true,
    })
  else
    error("invalid argument for Accel()") -- 元コードのエラーメッセージに準拠
  end
end

-- Setup Globals

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
