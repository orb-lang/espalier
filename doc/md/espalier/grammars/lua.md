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
lua = _ chunk+
chunk = (expr / symbol / number / string)+ _

`expr`  = unop _ expr _
      / value _ (binop _ expr)* _
unop  = "-" / "#" / "not"
binop = "and" / "or" / ".." / "<=" / ">=" / "~=" / "=="
      / "+" / "-" / "/" / "*" / "^" / "%" / "<" / ">"

`value` = Nil / bool / vararg / number / string
       / tableconstructor / Function
       / functioncall / var
       / "(" _ expr _ ")"
Nil   = "nil"
bool  = "true" / "false"
vararg = "..."
functioncall = prefix (_ suffix &(_ suffix))* _ call
tableconstructor = "{" _ fieldlist* _ "}"
Function = "function" _ funcbody
var = prefix (_ suffix &(_ suffix))* index
    / symbol


`fieldlist` = field (_ ("," / ";") _ field)*
field = key _ "=" _ val
      / expr
key = "[" expr "]" / symbol
val = expr

`prefix`  = "(" expr ")" / symbol
index   = "[" expr "]" / "." _ symbol
`suffix`  = call / index
`call`    = args / method
method    = ":" _ symbol _ args

args = "(" _ (explist _)? ")" / string
    ;/ tableconstructor
`explist` = expr ("," expr)*

`funcbody` = parameters _ chunk _ "end"
parameters = "(" _ (symbollist (_ "," _ vararg)*)* ")"
          / "(" _ vararg _ ")"
`symbollist` = (symbol ("," _ symbol)*)


string = singlestring / doublestring / longstring
`singlestring` = "'" ("\\" "'" / (!"'" 1))* "'"
`doublestring` = '"' ('\\' '"' / (!'"' 1))* '"'
`longstring` = "placeholder"

symbol = !keyword ([A-Z] / [a-z] / "_") ([A-Z] / [a-z] / [0-9] /"_" )*

number = real / hex / integer
`integer` = [0-9]+
`real` = integer "." integer* (("e" / "E") "-"? integer)?
`hex` = "0" ("x" / "X") higit+ ("." higit*)? (("p" / "P") "-"? higit+)?
`higit` = [0-9] / [a-f] / [A-F]

`_` = { \t\n\r}*

keyword = "and" / "break" / "do" / "else" / "elseif"
        / "end" / "false" / "for" / "function" / "if" / "in"
        / "local" / "nil" / "not" / "or" / "repeat"
        / "return" / "then" / "true" / "until" / "while"
]]
```
```lua
return Peg(lua_str)
```
