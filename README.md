# fn-commands

Lua library for describing chart content of [Falling Nikochan](https://github.com/na-trium-144/falling-nikochan).

Falling Nikochan uses this library with Lua 5.4 internally, but it does not depend on other libraries and can be used in any Lua environment.

## Running Tests

Tests cannot run on Lua 5.4, because [rxi-json-lua](https://github.com/rxi/json.lua) does not support it.
Use Lua 5.1, 5.2, or 5.3.

```bash
luarocks test --local
```
