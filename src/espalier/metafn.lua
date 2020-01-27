











local Node = require "espalier:espalier/node"

local function metafn(grammar, errstring)
   return function (t)
      local match = grammar(t.str, t.first, t.last)
      if match then
         if match.last == t. last then
            return match
         else
            match.id = match.id .. "-INCOMPLETE"
            return match
         end
      end
      if errstring then
         t.id = errstring
      end
      return setmetatable(t, Node)
   end
end

return metafn
