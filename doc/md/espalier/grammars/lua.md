# A Grammar For Lua

While the most important grammar for pegylator is pegylator itself, it's
time to make a Lua language parser.


The hard work is done on this, it's a matter of translation into the
Pegylator paradigm.


While this a hell of a lot of work, the complete BNF of Lua is available,
and reproduced here.


This will also serve as a template for Lun, and an opportunity to add some
repl-specific syntax; ideally to replace Lex Luathor with something more
general-purpose.

```lua
local Peg = require "espalier/grammars/peg"
```
```lua
local lua_str = [[
lua = symbol
symbol = ([A-Z] / [a-z] / "_") ([A-Z] / [a-z] / [0-9] /"_" )*
]]
```
```lua
return Peg(lua_str):toGrammar()
```
