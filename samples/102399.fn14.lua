require("fn-commands")
return fnChart({
  version = "0.1",
  offset = 0.5,
  ytId = "kcuF1gta0fQ",
  title = "Get Started!",
  composer = "na-trium-144",
  chartCreator = "na-trium-144",
  zoom = 0,
  levels = {
    {
      name = "",
      type = "Single",
      unlisted = false,
      ytBegin = 0,
      ytEndSec = 10,
      ytEnd = "note",
      snapDivider = 4,
      content = function() -- LEVEL_CODE_BEGIN --
        BPM(170)
        Accel(120)
        Beat({ { 4, 4, 4, 4 } })
        Step(16, 4)
        for i = 0, 3 do
          Note(-3 + i, 1, 3, false)
          Step(3, 8)
          Note(-3 + i, 1, 3, false)
          Step(5, 8)
        end
      end, -- LEVEL_CODE_END --
    },
    {
      name = "",
      type = "Double",
      unlisted = false,
      ytBegin = 0,
      ytEndSec = 10,
      ytEnd = "note",
      snapDivider = 4,
      content = function() -- LEVEL_CODE_BEGIN --
        BPM(170)
        Accel(170)
        Beat({ { 4, 4, 4, 4 } })
        Step(16, 4)
        for i = 0, 2 do
          Note(-3 + i, 1, 3, false)
          Step(3, 8)
          Note(-3 + i, 1, 3, false)
          Step(3, 8)
          Note(-3 + i, 1, 3, false)
          Step(2, 8)
        end
      end, -- LEVEL_CODE_END --
    },
  },
  copyBuffer = {
    [0] = { -3, 1, 3, false, true },
    [1] = nil,
    [2] = nil,
    [3] = nil,
    [4] = nil,
    [5] = nil,
    [6] = nil,
    [7] = nil,
    [8] = nil,
    [9] = nil,
  },
})
