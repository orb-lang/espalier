















local Peg = require "espalier/grammars/peg"



local lua_str = [=[
lua = shebang* _ chunk _ finalcomment* Error*
shebang = "#" (!"\n" 1)* "\n"
chunk = _ (statement _ ";"?)* (_ laststatement (_ ";")?)?

Error = 1+

finalcomment = "--" 1* !1

statement = "do" t chunk "end" t
          / "while" t expr "do" t chunk "end" t
          / "repeat" t chunk "until" t expr
          / "if" t expr "then" t chunk
            ("elseif" t expr "then" t chunk)*
            ("else" t chunk)* "end" t
          / "for" t _ symbol _ "=" expr _ "," _ expr _ ("," _ expr)?
            _ "do" t chunk "end" t
          / "for" t _ symbollist _ "in" t expr "do" t chunk "end" t
          / "function" t _ funcname _ funcbody
          / "local" t _ "function" t _ symbol _ funcbody
          / "local" t _ symbollist _ ("=" _ explist)?
          / varlist _ "=" _ explist
          / functioncall

laststatement = "return" t (_ explist)?
              / "break" t

funcname = symbol _ ("." _ symbol)* (":" _ symbol)?
varlist  = var (_ "," _ var)*

`expr`  = _ unop _ expr _
      / _ value _ (binop _ expr)* _
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

`_` = comment+ / whitespace
comment = whitespace "--" (!"\n" 1)* "\n" whitespace
        / longcomment
`longcomment` = "--[[placeholder]]"
`whitespace` = { \t\n\r}*

keyword = ("and" / "break" / "do" / "else" / "elseif"
        / "end" / "false" / "for" / "function" / "if" / "in"
        / "local" / "nil" / "not" / "or" / "repeat"
        / "return" / "then" / "true" / "until" / "while")
        t
`t` = !([A-Z] / [a-z] / [0-9] / "_")
]=]



return Peg(lua_str)
