















local Peg = require "espalier/grammars/peg"



local lua_str = [[
lua = symbol / number
symbol = ([A-Z] / [a-z] / "_") ([A-Z] / [a-z] / [0-9] /"_" )*
number = real / hex / hexit / integer
`integer` = [0-9]+
`real` = integer "." integer* (("e" / "E") "-"? integer)*
`hex` = "placeholder"
`hexit` = "placeholder"
]]



return Peg(lua_str):toGrammar()
