# Vav

  The Vav combinator takes Peh, a rule specification, and Mem\.

Mem is a [clade](https://gitlab.com/special-circumstance//cluster/-/blob/trunk/doc/md/clade.md), Peh is string recognized by the Dji
of our PEG specification [pegpeg](https://gitlab.com/special-circumstance/espalier/-/blob/trunk/doc/md/peg/pegpeg.md)\.



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

local Qoph = use "espalier:peg/bootstrap"
```

The inevitable metacircularity is delayed by using the existing peg/grammar
system for the rules themselves\.

```lua
local VavPeg = use "espalier:peg" (pegpeg, Metis)
local Vpeg = VavPeg.parse
```

The same with our Grammar module, which is a precomposed Qoph in the latest
fashion\.

```lua
local Grammar = use "espalier:espalier/grammar"
```

We're juuuust about to swallow our own tails here\.


### Vav combinator: Vav Peh Mem

Vav is the entire front, resolving everything which is proper to the grammar\.

Peh is the structural specification, Mem provides \(specific\) match\-time
behaviors\.

The Vav combinator parses Peh, for rule analysis, and reconciles Mem
against the present rules\.

I'm leaning toward `:Mem(mem)` being the interface, as the idiomatic
equivalent of currying Vav to Peh, performing various transformrations, and
then supplying mem\.


## Vav

```lua
local new, Vav, Vav_M = cluster.order()

Vav.pegparse = VavPeg

local _reconcile;

cluster.construct(new,
   function(_new, vav, peh, mem)
      vav.peh = peh
      vav.grammar = VavPeg(peh)
      if vav.grammar then
         vav.grammar :hoist()
         vav.synth = vav.grammar :synthesize()
         -- signature is slightly odd here b/c :analyze returns anomalies
         -- so a nil means that all is well
         if (not vav.synth:analyze()) then
            if mem then
               -- first example of using a method off the seed
               _new.Mem(vav, mem)
            end
         end
      else
         vav.failedParse = true
      end
      -- we'll have checks here

      return vav
   end)
```


#### Vav:Mem\(mem\)

  The parameter `mem` is a clade,

  -  Any key in `mem` must be a rule name *or* a trait \(key in tav\)
  -  Any field in tav sets must be a rule name
  -  Keys in tav must **not** be rule names


Initially, any violation throws an error\.  By design, Vav throws errors when
asked to do the impossible, which this isn't\.  Eventually, we'll collect the
errors, if any, and return one of `vav` or `nil, errors`\.

```lua
function _reconcile(vav, mem, tav)
   tav = tav or {}
   local ruleMap = assert(vav.synth.ruleMap)
   local traits = {}
   for name, meta in pairs(mem) do
      if not ruleMap[name] then
         -- rethink all of this with clades!
         error("Grammar has no '" .. name .. "' rule.")
      end
   end
   -- extend the clade for remaining rules
   local _;
   for name in pairs(ruleMap) do
      -- statement-oriented languages amirites
      _ = mem[name]
   end
   -- decorate with tavs
   for trait, members in pairs(tav) do
      for elem in pairs(members) do
         if not ruleMap[elem] then
            error("Trait '" .. trait
                  .. "' has unknown member '" .. elem .. "'.")
         end
         mem[elem].trait = true
      end
   end
end
```



## Vav interface \#Unstable

The need for an intermediate Node to generate the synth nodes from will not
be indefinite\.

Vav will be the container for all the components, however\.


### Vav:complete\(\)

Answers whether the Vav combinator is reconciled with Mem and ready to be
combined with Qoph to produce Dji\.


```lua
function Vav.complete(vav)
   -- obvious stub
   return true
end
```


### Pass\-throughs


#### Vav:constrain\(\)

A pass\-through which we'll be using for awhile at least\.

```lua
function Vav.constrain(vav)
   return vav.synth:constrain()
end
```


#### Vav:anomalies\(\)

```lua
function Vav.anomalies(vav)
   return vav.synth:anomalies()
end
```


### Vav:dji\(\)

For today's purposes, produces and attaches a grammar\.

```lua
function Vav.dji(vav)
   return Qoph(vav)
end
```


#### Vav:toLpeg\(\)

```lua
function Vav.toLpeg(vav)
   if vav.lpeg_engine then
      return vav.lpeg_engine
   end
   vav.lpeg_engine = vav.synth :toLpeg() :string()
   if not vav.lpeg_engine then
      error "Lpeg function was not created"
   end

   return vav.lpeg_engine
end
```


### Vav:try\(rule?\)

Generates a \(hopefully\) usable parser, even in the absence of the full
panoply of rules\.

If the string `rule` is supplied, Vav will return a grammar for that rule\.

```lua
function Vav.try(vav, rule)
   local synth = vav.synth
   if not synth.calls then
      synth:analyze()
   end

   local anomalous = synth:anomalies()
   if anomalous and anomalous.missing then
      synth:makeDummies()
   elseif not rule then
      return vav:dji()
   end
   if rule then
      local peh = synth:pehFor(rule)
      local ruleVav = new(peh)
      return ruleVav :try(), ruleVav
   end
   vav.peh_dummy = vav.peh .. vav.synth.dummy_rules
   vav.dummy = new(vav.peh_dummy)
   vav.test_engine = vav.dummy.synth :toLpeg() :string()
   vav.test_parse, vav.test_pattern = Grammar(vav.test_engine)
   return vav.test_parse
end
```

```lua
return new
```

