# Vav


  Vav is an unbound collection of PEG rules, which may constitute a proper
Grammar\.


## Rationale

  The various operations and rearrangements which I propose to perform on
PEGs is unrelated, in terms of implementation, to the use of that PEG through
binding it to some engine\.

This is largely a matter of breaking the existing architecture down into its
constituent parts\.


#### Code Drop

This is an example of qoph, not vav, and yet\.

```lua
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
```


### pegpeg

A fresh, cleaner implementation of the PEG grammar extension we use in
Espalier\.

Interpreted by the old engine \(like everything else\!\)\.\. for now\.k

```lua
local pegpeg = require "espalier:peg/pegpeg"
```

### Metis

Vav takes over as, well, the Vav combinator, for now we can focus on
middleware for our nice tight new IR

```lua
local Metis = require "espalier:peg/metis"
```

There's more to this but in terms of wiring up:

```lua
local Vav = require "espalier:peg" (pegpeg, Metis)
```

```lua
return Vav
```

