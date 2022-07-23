





















---
-- Adds hooks to a grammar to print debugging information
--
-- Debugging LPeg grammars can be difficult. Calling this function on your
-- grammmar will cause it to print ENTER and LEAVE statements for each rule, as
-- well as position and subject after each successful rule match.
--
-- For convenience, the modified grammar is returned; a copy is not made
-- though, and the original grammar is modified as well.
--
-- @param grammar The LPeg grammar to modify
-- @param printer A printf-style formatting printer function to use.
--                Default: stdnse.debug1
-- @return The modified grammar.
function debug (grammar, printer)
  printer = printer or printf
  -- Original code credit: http://lua-users.org/lists/lua-l/2009-10/msg00774.html
  for k, p in pairs(grammar) do
    local enter = lpeg.Cmt(lpeg.P(true), function(s, p, ...)
      printer("ENTER %s", k) return p end)
    local leave = lpeg.Cmt(lpeg.P(true), function(s, p, ...)
      printer("LEAVE %s", k) return p end) * (lpeg.P("k") - lpeg.P "k");
    grammar[k] = lpeg.Cmt(enter * p + leave, function(s, p, ...)
      printer("---%s---", k) printer("pos: %d, [%s]", p, s:sub(1, p-1)) return p end)
  end
  return grammar
end











local pegpeg = require "espalier:peg/pegpeg"








local Metis = require "espalier:peg/metis"





local Vav = require "espalier:peg" (pegpeg, Metis)



return Vav

