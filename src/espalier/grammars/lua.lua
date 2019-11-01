















local Peg = require "espalier/grammars/peg"



local lua_str = [[
lua = _ chunk+
chunk = (expr / symbol / number / string)+ _

expr  = unop _ expr _
      / value _ (binop _ expr)* _
unop  = "-" / "#" / "not"
binop = "and" / "or" / ".." / "<=" / ">=" / "~=" / "=="
      / "+" / "-" / "/" / "*" / "^" / "%" / "<" / ">"

value = bleh / Nil / bool / vararg / number / string
      / functioncall / symbol
  ; / function / tableconstructor / var
  ; / "(" _ expr _ ")"
Nil   = "nil"
bool  = "true" / "false"
vararg = "..."
functioncall = prefix _ suffix? _ call

bleh = "!" args

prefix  = "(" expr ")" / symbol
index   = "[" expr "]" / "." _ symbol
suffix  = call / index
call    = args / ":" _ symbol _ args

args = "(" _ (explist _)? ")" / string
    ;/ tableconstructor

explist = expr ("," expr)*

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
