# Vav


  Vav is an unbound collection of PEG rules, which may constitute a proper
Grammar\.


## Rationale

  The various operations and rearrangements which I propose to perform on
PEGs is unrelated, in terms of implementation, to the use of that PEG through
binding it to some engine\.

This is largely a matter of breaking the existing architecture down into its
constituent parts\.


#### imports

```lua
local core, cluster = use("qor:core", "cluster:cluster")

local pegpeg = use "espalier:peg/pegpeg"
local Metis = use "espalier:peg/metis"
```

The inevitable metacircularity is delayed by using the existing peg/grammar
system for the rules themselves\.

```lua
local VavPeg = use "espalier:peg" (pegpeg, Metis) . parse
```

The same with our Grammar module, which is a precomposed Qoph in the latest
fashion\.

```lua
local Grammar = use "espalier:espalier/grammar"
```

We're juuuust about to swallow our own tails here\.


## Vav

```lua
local new, Vav, Vav_M = cluster.order()

Vav.pegparse = VavPeg


cluster.construct(new,
   function(_new, vav, peh)
     vav.rules = VavPeg(peh) :hoist()
     vav.peh = peh
     -- we'll have checks here
     vav.synth = vav.rules :synthesize()

      return vav
   end)
```


## Vav interface \#Unstable

The need for an intermediate Node to generate the synth nodes from will not
be indefinite\.

Vav will be the container for all the components, however\.


### Vav:dji\(\)

For today's purposes, produces and attaches a grammar\.

```lua
function Vav.dji(vav)
   if not vav.lpeg_engine then
      vav.lpeg_engine = vav.synth :toLpeg() :string()
   end
   -- we need more than this, notably the metis, but.
   vav.parse, vav.grammar = Grammar(vav.lpeg_engine)
   return vav.parse
end
```


```lua
return new
```

