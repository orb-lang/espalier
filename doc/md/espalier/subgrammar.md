# Subgrammar


  A metatable function can do anything, and so long as it returns a valid
Node over the appropriate range, everything else should still work\.

The simplest way to achieve this is to wrap a Grammar in a function\.

This helper method achieves this, taking a grammar and an optional error
string, returning a function suitable for use as a metatable\.

```lua
local Node = require "espalier:espalier/node"
local Peg = require "espalier:espalier/peg"

local function subgrammar(grammar, meta, errstring)
   if type(grammar) == 'string' then
      -- try to coerce to Peg fn
      grammar = Peg(grammar)
   end
   meta = meta or Node
   return function (t)
      local match = grammar(t.str, t.first, t.last)
      if match then
         if match.last == t.last then
            return match
         else
            match.should_be = match.id
            match.id = "INCOMPLETE"
            return match
         end
      end
      if errstring then
         t.errstring = errstring
         t.should_be = t.id
         t.id        = "NOMATCH"
      end
      return setmetatable(t, meta)
   end
end

return subgrammar
```
