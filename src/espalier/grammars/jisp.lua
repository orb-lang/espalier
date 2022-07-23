


















local j_object = [[
   object <- "{" _ pair _ "}"
]]















local j_whitespace = [[
  `_` <- { \t\n\r}*
]]























local j_pair = [[
pair <- key _ ":" _ value _ ","
key <- string
value <- string
string <- '"' (!'"' 1) '"'
]]
