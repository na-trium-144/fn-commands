package = "fn-commands"
version = "dev-1"
source = {
   url = "git+https://github.com/na-trium-144/fn-commands.git"
}
description = {
   summary = "Lua library for describing chart content of Falling Nikochan",
   detailed = [[
      Lua library for describing chart content of Falling Nikochan
   ]],
   homepage = "https://github.com/na-trium-144/fn-commands",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["fn-commands"] = "fn-commands.lua"
   }
}
