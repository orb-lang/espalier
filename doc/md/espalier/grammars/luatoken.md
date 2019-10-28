# Lua tokenizer

```lua
local Peg = require "espalier/grammars/peg"
```
```lua
local lua_tok_str = [[
lua = _ (token _)+
`token` = keyword / operator

keyword = "function" / "local" / "for" / "in" / "do"
           / "and" / "or" / "not" / "true" / "false"
           / "while" / "break" / "if" / "then" / "else" / "elseif"
           / "goto" / "repeat" / "until" / "return" / "nil"
           / "end"

operator = "+" / "-" / "*" / "/" / "%" / "^" / "#"
           / "==" / "~=" / "<=" / ">=" / "<" / ">"
           / "=" / "(" / ")" / "{" / "}" / "[" / "]"
           / ";" / ":" / "..." / ".." / "." / ","

 _     = { \t\n,}*

]]
```
```lua
return Peg(lua_tok_str):toGrammar()
```
