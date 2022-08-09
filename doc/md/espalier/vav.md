# Vav


  Vav is an unbound collection of PEG rules, which may constitute a proper
Grammar\.


## Rationale

  The various operations and rearrangements which I propose to perform on
PEGs is unrelated, in terms of implementation, to the use of that PEG through
binding it to some engine\.

This is largely a matter of breaking the existing architecture down into its
constituent parts\.


### pegpeg

A fresh, cleaner implementation of the PEG grammar extension we use in
Espalier\.

Interpreted by the old engine \(like everything else\!\)\.\. for now\.k

```lua
local pegpeg = require "espalier:peg/pegpeg"
```


### Metis

Vav takes over as, well, the Vav combinator, for now we can focus on
middleware for our nice tight new IR\.

```lua
local Metis = require "espalier:peg/metis"
```

The inevitable metacircularity is delayed by using the existing peg/grammar
system for the rules themselves\.

```lua
local VavPeg = require "espalier:peg" (pegpeg, Metis) . parse
```


### Vav

```lua
local function Vav(peg_string)
   local rules = VavPeg(peg_string)
   rules.pegparse = VavPeg
   rules.peg_str = peg_string
   -- we'll have checks here
   rules :synthesize()
   return rules
end
```

```lua
return Vav
```

