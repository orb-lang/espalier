















local Peg = require "espalier/grammars/peg"



local lua_str = [[
lua = _ chunk+
chunk = (expr / symbol / number / string)+ _

expr  = unop _ expr
      / value (_ binop _ expr)*
unop  = "-" / "#" / "not"
binop = "and" / "or" / ".." / "<=" / ">=" / "~=" / "=="
      / "+" / "-" / "/" / "*" / "^" / "%" / "<" / ">"

value = nil / bool / vararg / number / string / symbol
  ; / function / tableconstructor / functioncall / var
  ; / "(" _ expr _ ")"
nil   = "nil"
bool  = "true" / "false"
vararg = "..."

string = singlestring / doublestring / longstring
`singlestring` = "'" ("\\" "'" / (!"'" 1))* "'"
`doublestring` = '"' ('\\' '"' / (!'"' 1))* '"'
`longstring` = "placeholder"

symbol = ([A-Z] / [a-z] / "_") ([A-Z] / [a-z] / [0-9] /"_" )*

number = real / hex / integer
`integer` = [0-9]+
`real` = integer "." integer* (("e" / "E") "-"? integer)?
`hex` = "0" ("x" / "X") higit+ ("." higit*)? (("p" / "P") "-"? higit+)?
`higit` = [0-9] / [a-f] / [A-F]

`_` = { \t\n\r}*
]]



return Peg(lua_str)
