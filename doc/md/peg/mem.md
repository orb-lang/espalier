# Mem


The tools of higher combination\.

```lua
local Clade, Node = use ("cluster:clade", "espalier:peg/node")
```


#### Clade Extension

```lua
local function postindex(tab, field)
   tab[field].tag = field
   return tab[field]
end

local contract = {postindex = postindex, seed_fn = true}

local MemClade = Clade(Node, contract):extend(contract)
local Mem = MemClade.tape
local Basis = Mem[1]
local Mem_M = MemClade.meta[1]

Basis.v = 1
```

This is where we crack our knuckles and start porting\.


#### imports

```lua
local core = use "qor:core"
local table = core.table
local Set = core.set
local Deque = use "deque:deque"
local insert, remove, concat = assert(table.insert),
                               assert(table.remove),
                               assert(table.concat)
local s = use "status:status" ()
s.verbose = false
```


##### normalize

  Causes any `-` in a name to become `_`, allowing us to treat them as
interchangeable\.  This is my crank compromise between ordinary string
matching and creations such as Nim's symbol equivalence and unified call
syntax\.

```lua
local gsub = assert(string.gsub)

local function normalize(str)
   return gsub(str, "%-", "%_")
end
```


### Qualia

Aka Traits,

```lua
local Q = {}
```


#### Q\.nofail

Any rule type which matches the empty string\.

Note there is one type of repeat rule `name%0..5` which is also optional but
we must detect this \(we do not as yet\)\.

```lua
Q.nofail = Set {'zero_plus', 'optional'}
```


#### Q\.predicate

A match which will never advance the cursor, but which can succeed or fail\.

```lua
Q.predicate = Set {'and', 'not'}
```


#### Q\.failsucceeds

A rule which succeeds by failing, aka `not`\.

There is a reason to have a category of one, which is that this condition
propagates beyond its definition during rule constraint\.

```lua
Q.failsucceeds = Set {'not'}
```


#### Q\.nullable

A rule which can match without advancing the cursor\.

```lua
Q.nullable = Q.predicate + Q.nofail
```


#### Q\.compound

```lua
Q.compound = Set {'cat', 'alt'}
```


#### Q\.terminal

Rules which produce a definite amount of cursor movement in and of themselves\.

```lua
Q.terminal = Set {'literal', 'set', 'range', 'number'}
```


#### Q\.unbounded

Rules which can consume arbitrary amounts of input inherently\.

This doesn't account for recursive analysis: ` A <- "a" A` type grammars can
be identified, and will be, but not by class\.

```lua
Q.unbounded = Set { 'zero_plus', 'one_plus' }
```

Which we can also represent inside\-out as traits pertaining to a class:

```lua
local Prop = {}
for trait, classSet in pairs(Q) do
   for class in pairs(classSet) do
      Prop[class] = Prop[class] or {}
      insert(Prop[class], trait)
   end
end
for class, array in pairs(Prop) do
   Prop[class] = Set(array)
end
```


## Mem Basis


##### mem:parentRule\(\)

Returns the parent rule of the part\.

```lua
function Basis.parentRule(mem)
   if mem.tag == 'rule' then return nil, 'this is a rule' end
   if mem.tag == 'grammar' then return nil, 'this is a grammar' end
   local parent = mem.parent
   repeat
      if parent.tag == 'rule' then
         return parent
      else
         parent = parent.parent
      end
   until parent:isRoot()

   return nil, 'mistakes were made (new tree structure?)'
end
```


##### mem:nameOfRule\(\) \#deprecated :withinRule\(\)

Returns the name of the enclosing rule\.

```lua
function Basis.nameOfRule(mem)
   local rule, why = mem:parentRule()
   if not rule then
      return nil, why
   end
   return rule.token
end

function Basis.withinRule(mem)
   s:chat "use .nameOfRule"
   return mem:nameOfRule()
end
```


#### mem:nameOf\(\)



```lua
function Basis.nameOf(mem)
   return mem.name or mem.tag
end
```


##### Synthesis

Here we decorate particular Nodes with useful representations and
contextual information\.

```lua
local SpecialSnowflake = Set {'set', 'range', 'name',
                               'number', 'literal', 'rule_name'}

local function extraSpecial(node)
   local c = node.tag
   if c == 'range' then
      node.from_char, node.to_char = node[1]:span(), node[2]:span()
   elseif c == 'set' then
      node.value = node:span()
   elseif c == 'name' or c == 'rule_name' then
      node.token = normalize(node:span())
   else
      node.token = node:span()
   end
end
```

```lua
local analyzeElement;

local Hoist = Set {'element', 'alt', 'cat'}

local function synthesize(node)
   for twig in ipairs(node) do
      if Hoist[twig] then
         twig:hoist()
         twig = assert(twig[1])
      end

      if SpecialSnowflake[node.tag] then
         extraSpecial(twig)
      end
      -- elements
      if twig.tag == 'element' then
         analyzeElement(twig)
      end
      if node.tag == 'rule' then
         node.token = assert(node :take 'rule_name' . token)
      end
      synthesize(node)
   end
   return node
end
```


#### analyzeElement\(elem\)

The parser change puts all the modifiers on the element, which is useful\.

Since we hoist a few redundant classes, any element which remains is modified
in some fashion, what we do here is promote that information onto the
element, and copy it to the component part, such that we no longer need to
consider those synth nodes\.

We then dispose of the surroundings, except for back references\.

```lua
local Prefix = Set {'and', 'not', 'to_match'}
local Suffix = Set {'zero_plus', 'one_plus', 'optional', 'repeat'}
local Backref = Set {'backref'}

local Surrounding = Prefix + Suffix + Backref
```

```lua
function analyzeElement(elem)
   local prefixed, backrefed  = Prefix[elem[1].tag],
                                Backref[elem[#elem].tag]
   local suffixed;
   if backrefed then
      suffixed = Suffix[elem[#elem-1].tag]
   else
      suffixed = Suffix[elem[#elem].tag]
   end
   local modifier = { prefix = false,
                      suffix = false,
                      backref = false, }

   local part

   if prefixed then
      modifier.prefix = elem[1]
      part = elem[2]
   else
      part = elem[1]
   end

   if backrefed and suffixed then
      modifier.backref = elem[#elem]
      modifier.suffix  = elem[#elem - 1]
   elseif suffixed then
      modifier.suffix = elem[#elem]
   elseif backrefed then
      modifier.backref = elem[#elem]
   end
   assert(part and (not Surrounding[part.tag]),
          "weirdness encountered analyzing element")
   for _, mod in pairs(modifier) do
      if mod then
         elem[mod.tag] = true
         local traits = Prop[mod.tag]
         if traits then
            for trait in pairs(traits) do
               elem[trait] = true
            end
         end
      end
   end
   -- strip now-extraneous information
   for i = 1, #elem do
      elem[i] = nil
   end
   elem[1] = part
   if backrefed then
      elem[2] = modifier.backref
   end
end
```


```lua
function Mem.grammar.synthesize(grammar)
   grammar.start = grammar :take 'rule'
   synthesize(grammar)

   return grammar
end
```


### Codegen Mixin

This should be a Clade vector\.

```lua
local codegen = require "espalier:peg/codegen"

for class, mixin in pairs(codegen) do
   for trait, method in pairs(mixin) do
      Mem[class][trait] = method
   end
end
```


```lua
return MemClade
```

