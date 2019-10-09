















local Peg = require "espalier/grammars/peg"



local lua_str = [[
lua = symbol
symbol = ([A-Z] / [a-z] / "_") ([A-Z] / [a-z] / [0-9] /"_" )*
]]



return Peg(lua_str):toGrammar()
