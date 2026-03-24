# fn-commands

[![NPM Version](https://img.shields.io/npm/v/fn-commands)](https://www.npmjs.com/package/fn-commands)
[![LuaRocks](https://img.shields.io/luarocks/v/na-trium-144/fn-commands)](https://luarocks.org/modules/na-trium-144/fn-commands)

Lua library for describing chart content of [Falling Nikochan](https://github.com/na-trium-144/falling-nikochan).

Falling Nikochan uses this library with Lua 5.4 internally, but it does not depend on other libraries and can be used in any Lua environment.

## API

### Chart Data

```lua
require("fn-commands")
return fnChart({
  version = "0.2", -- fn-commands library throws error if this is newer than library version
  offset = 0.5,
  ytId = "123456789ab",
  title = "song title",
  composer = "song composer",
  chartCreator = "chart creator",
  zoom = 0, -- only used in chart editor
  levels = {
    {
      name = "optional level name",
      type = "Single",
      unlisted = false,
      ytBegin = 0,
      ytEndSec = 10,
      ytEnd = "note", -- only used in chart editor
      snapDivider = 4, -- only used in chart editor
      content = function() -- LEVEL_CODE_BEGIN --
        BPM(170)
        -- ...
      end, -- LEVEL_CODE_END --
    },
  },
  copyBuffer = {
    ["0"] = { -3, 1, 3, false, true },
    ["1"] = nil,
    -- ...
  },
})
```

Executing this will give you data that matches [the Chart15 format used by the /api/chartFile API](https://nikochan.utcode.net/api#POST/chartFile/%7Bcid%7D), except that the `lua` field is missing.
Please insert the `lua` field as shown below, using a regular expression to extract the content portion of the original code:

```js
{
  ...luaExecResult,
  lua: rawCode.match(/LEVEL_CODE_BEGIN(?:(?!LEVEL_CODE_BEGIN)[\w\W])\*?LEVEL_CODE_END/g) ?? [],
}
```

### Level Data

- `Note(x, vx, vy, big, fall)`: Places a note.
  - Specify x, vx, vy as numbers, and big, fall as `true` or `false`.
- `Step(a, b)`: Represents a rest for a b-note.
  - a must be an integer greater than or equal to 0, and b must be an integer greater than or equal to 1.
- `BPM(bpm value)`: Changes the BPM. Must be a positive number.
- `Accel(speed value)`: Changes the speed. 0 and negative values can also be used.
- `AccelBegin(speed value)` 〜 `AccelEnd(speed value)`: Smooth speed change.
  - (Due to specifications, `Accel` and `AccelBegin` are the same. The change starts from the last `Accel` or `AccelBegin` before `AccelEnd`.)
- `Beat(beat)` or `Beat(beat, a, b)`: Changes the beat.
  - For example, `{{4, 4, 4, 4}}` is 4/4 beat,
  `{{4, 4, 4, 8}}` is 7/8 beat,
  `{{4, 4, 4, 4}, {4, 4, 4}}` is 4/4 + 3/4 beat.
    - (Counts from left to right, the opposite of <BeatSlime size={4} />)
  - You can specify a beat count offset ( a / b ) after the beat.
  a is an integer 0 or greater, and b is an integer 1 or greater.

## Running Tests

```bash
luarocks test --local
```
