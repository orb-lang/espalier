


local lua_tok_str = [[
lua = (token _)+
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



return lua_tok_str
