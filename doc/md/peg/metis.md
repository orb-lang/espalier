# Metis

The metatables responsible for building the Vav combinator\.


### Synth Nodes

This is officially a pattern since we do the same thing with Scry\.

Here it is particularly important because we expect to do a lot of rewriting
of terms based on underlying strings which will not be identical\.

#### imports

```lua
local Node = require "espalier:espalier/node"
local Grammar = require "espalier:espalier/grammar"
local core = require "qor:core" -- #todo another qor
local cluster = require "cluster:cluster"
local table = core.table
local Set = core.set
local insert, remove, concat = assert(table.insert),
                               assert(table.remove),
                               assert(table.concat)
local s = require "status:status" ()
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

We'll fill this in as we go deeper\.

```lua
local Q = {}
```


### Metabuilder

  This pattern goes into its own module eventually/soon/as part of what I'm
doing right now\.

Lets us automatically build a metatable for class `something` by indexing
`Metas.something`\.

I'm tempted to do something automagic with `Metas.Something` but like, not,
right now\.


#### Twig

This is clearly part of what a generator does automatically *but*

```lua
local Twig = Node :inherit()
```


```lua
local function __index(metabuild, key)
   metabuild[key] = Twig :inherit(key)
   return metabuild[key]
end
```

```lua
local M = setmetatable({Twig}, {__index = __index})
```


### Rules

This is where we set up the information graph for a given Vav\.


### Scry Synth Copypasta

This really is one distinct thing but yeah\.


#### builder\(\_new, synth, node, i\)

```lua
local new, Syndex, SynM = cluster.order()

local function builder(_new, synth, node, i)
   synth.up = i
   synth.o = node.first
   synth.node = node
   synth.line, synth.col = node:linePos()
   -- this is just for reading purposes, remove
   synth.class = _new.class
   return synth
end
cluster.construct(new, builder)

```


##### Synth lens

```lua
local suppress = Set {
   'parent',
   --'line',
   'o',
   'col',
   'up',
   'node',
}
local _lens = { hide_key = suppress,
                depth = 6 }
local Syn_repr = require "repr:lens" (_lens)

SynM.__repr = Syn_repr
```


### Synth Equality

We say a synth is equal to another if:


- A leaf node has the same class and string value


- A branch node the same class and has all children equal by this rule

Note that we have an opportunity to provide memoized equality here by pointing
between branch nodes already proven equal, either manually as 'cut' points or
just as part of the equality operation\.

```lua
function SynM.__eq(syn1, syn2)
   -- different classes or unequal lengths always neq
   if (syn1.class ~= syn2.class)
      or (#syn1 ~= #syn2) then
         return false
   end
   -- two tokens?
   if (#syn1 == 0) and (#syn2 == 0) then
      -- same length?
      if syn1:stride() ~= syn2:stride() then
         return false
      end
      local str1, str2 = syn1.node.str, syn2.node.str
      local o1, o2 = syn1.o, syn2.o
      local same = true
      for i = 0, syn1:stride() - 1 do
         local b1, b2 = byte(str1, i + o1), byte(str2, i + o2)
         if b1 ~= b2 then
            same = false
            break
         end
      end
      return same
   end
   -- two leaves with the same number of children
   local same = true
   for i = 1, #syn1 do
      if not syn1[i] == syn2[i] then
         same = false
         break
      end
   end
   return same
end
```



### Synth Metamaker

We do this a couple of ways\.\.\.

First we inherit from `new` if we haven't seen the class aka node `.id`:

```lua
local newSes, metaSes =  {}, {}

local function makeGenus(class)
   local _new, Class, Class_M = cluster.genus(new)
   cluster.extendbuilder(_new, true)
   newSes[class] = _new
   metaSes[class] = Class
   Class.class = class
   for quality, set in pairs(Q) do
      if set[class] then
         Class[quality] = true
      end
   end
   return _new, Class, Class_M -- we ignore the metatable. until we dont'.
end

local function newSynth(node, i)
   local class = node.id
   local _new, Class = newSes[class]
   if not _new then
      _new, Class = makeGenus(class)
   end
   return _new(node, i)
end
```


Second we have a metamaker, letting us say `Syn.class.whatever` and get the
correct index table \(Cassette\)\.

```lua
local function Syn_index(Syn, class)
   local meta, _ = metaSes[class]
   if not meta then
      _, meta = makeGenus(class)
      Syn[class] = meta
   end
   return meta
end

local Syn = setmetatable({Syndex}, {__index = Syn_index })
```


### Base Synth methods

```lua
local walk = require "gadget:walk"
local filter, reduce = assert(walk.filter), assert(walk.reduce)
local classfilter = {}

local function filterer(class)
   local F = classfilter[class]
   if not F then
      classfilter[class] = function(node)
                        return node.class == class
                     end
      F = classfilter[class]
   end
   return F
end

function _filter(synth, pred)
   if type(pred) == 'string' then
      return filter(synth, filterer(pred))
   else
      return filter(synth, pred)
   end
end
Syndex.filter = _filter

function Syndex.take(synth, pred)
   for syn in _filter(synth, pred) do
      return syn
   end
end

function Syndex.reduce(synth, pred)
   if type(pred) == 'string' then
      return reduce(synth, filterer(pred))
   else
      return reduce(synth, pred)
   end
end
```


```lua
function Syndex.span(synth)
   return synth.node:span()
end
```


```lua
function Syndex.stride(synth)
   return node.last - node.first + 1
end
```


```lua
function Syndex.nameOf(synth)
   return synth.name or synth.class
end
```


Not using these:

```lua
function Syndex.shed(syn)
   if #syn > 1 then
      error "can't shed a node with several children"
   elseif #syn == 0 then
      error "can't shed a leaf node"
   end
   assert(syn.parent[syn.up] == syn, "parent missing child")
   syn.parent[syn.up] = syn[1]
   syn[1].parent = syn.parent
   syn[1].up = syn.up
end
```

```lua
function Syndex.left(syn)
   return syn.parent[syn.up + 1]
end

function Syndex.right(syn)
   return syn.parent[syn.up - 1]
end
```

Might actually want 'left' and 'right' for something a little more useful?


#### 'Syndex' base for analysis and synthesis

Is just pass, probably these should be promoted to errors because synthesis
and analysis should be exhaustive\.\.\. maybe? This is my best guess\.

```lua
Syndex.synthesize = cluster.ur.pass
Syndex.analyze = cluster.ur.pass
```


#### \_synth\(node\)

Let's get this out of the way real quick\.

```lua
local function _synth(node, parent_synth, i)
   local synth = newSynth(node, i)
   synth.parent = parent_synth or synth
   for i, twig in ipairs(node) do
      synth[i] = _synth(twig, synth, i)
   end
   return synth
end
```

```lua
function M.rules.synthesize(rules)
   rules.start = rules :take 'rule'
   rules.synth = _synth(rules)
   return rules.synth
end
```


### rules:collectRules\(\)

Time for a big ol' info dump\!  May as well grab All The Formats and see where
we get w\. it\.


- returns a map of the following:

  - nameSet:  The set of every name in normalized token form\.

  - ruleMap:  A map from the rule name \(token\) to the rule itself\.

  - dupe:  An array of any rule synth which has been duplicated later, this
      reflects the semantics of lpeg which overwrites a `V"rule"`
      definition if it sees a second one\.

  - surplus:  An array of any rule which isn't referenced by name on the
      right hand side\.

  - missing:  Any rule referenced by name which isn't defined in the grammar\.

  - ruleCalls:  A map of the token for a rule to an array of the name of each
      rule it calls\. This overwrites duplicate rules, which don't
      interest me very much except as something we lint and prune\.

```lua
function Syn.rules.collectRules(rules)
   local nameSet = Set {}
   for name in rules :filter 'name' do
      local token = normalize(name:span())
      nameSet[token] = true
   end
   local dupe, surplus = {}, {}
   local ruleMap = {} -- token => node
   local ruleCalls = {} -- token => {name*}
   for rule in rules :filter 'rule' do
      local token = normalize(rule :take 'rule_name' :span())
      if ruleMap[token] then
         -- lpeg uses the *last* rule defined so we do likewise
         insert(dupe, ruleMap[token])
      end
      ruleMap[token] = rule
      if not nameSet[token] then
         -- while it is valid to refer to the top rule, it is not noteworthy
         -- when a grammar does not.
         -- rules[1] is kind of sloppy but we're just going in the order of
         -- inspiration...
         if not (rule == rules[1]) then
            insert(surplus, rule)
         end
      end
      -- build call graph
      local calls = {}
      ruleCalls[token] = calls
      for name in rule :filter 'name' do
         local tok = normalize(name:span())
         insert(calls, tok)
      end
   end
   local missing = {}
   for name in pairs(nameSet) do
      if not ruleMap[name] then
         insert(missing, name)
      end
   end
   -- #improve should dupe, surplus, missing be sets?
   return { nameSet = nameSet,
            ruleMap = ruleMap,
            ruleCalls = ruleCalls,
            dupe = dupe,
            surplus = surplus,
            missing = missing, }
end
```

#### partition\(ruleCalls\)

This partitions the rules into regular and recursive\.


```lua
local function partition(ruleCalls, callSet)
   local base_rules = Set()
   for name, calls in pairs(ruleCalls) do
      if #calls == 0 then
         base_rules[name] = true
         callSet[name] = nil
      end
   end

   local rule_order = {base_rules}
   local all_rules, next_rules = base_rules, Set()
   local TRIP_AT = 512
   local relaxing, trip = true, 1
   while relaxing do
      trip = trip + 1
      for name, calls in pairs(callSet) do
         local based = true
         for call in pairs(calls) do
            if not all_rules[call] then
               based = false
            end
         end
         if based then
            next_rules[name] = true
            callSet[name] = nil
         end
      end
      if #next_rules == 0 then
         relaxing = false
      else
         insert(rule_order, next_rules)
         all_rules = all_rules + next_rules
         next_rules = Set()
      end

      if trip > TRIP_AT then
         relaxing = false
         error "512 attempts to relax rule order, something is off"
      end
   end

   return rule_order, callSet
end
```

```lua
local clone1 = assert(table.clone1)

local function _callSet(ruleCalls)
   local callSet = {}
   for name, calls in pairs(ruleCalls) do
      callSet[name] = Set(clone1(calls))
   end
   return callSet
end
```

We know these rules aren't recursive so we can obtain their dependencies
without cycle checking\.

```lua
local function graphCalls(rules)
   local collection = assert(rules.collection)
   local ruleCalls, ruleMap = assert(collection.ruleCalls),
                               assert(collection.ruleMap)
   local regulars = assert(collection.regulars)

   -- go through each layer and build the full dependency tree for regular
   -- rules
   local regSets = {}
   -- first set of rules have no named subrules
   local depSet = regulars[1]
   for name in pairs(depSet) do
      ruleMap[name].final = true
      regSets[name] = Set {}
   end
   -- second tier has only the already-summoned direct calls
   depSet = regulars[2]
   for name in pairs(depSet) do
      regSets[name] = Set(clone1(ruleCalls[name]))
   end
   -- the rest is set arithmetic
   for i = 3, #regulars do
      depSet = regulars[i]
      for name in pairs(depSet) do
         local callSet = Set(clone1(ruleCalls[name]))
         for _, called in ipairs(ruleCalls[name]) do
            callSet = callSet + regSets[called]
         end
         regSets[name] = callSet
      end
   end
   return regSets
end
```

```lua
function Syn.rules.analyze(rules)
   local collection = rules:collectRules()
   rules.collection = collection
   local regulars, recursive = partition(collection.ruleCalls, rules:callSet())
   local ruleMap = assert(collection.ruleMap)
   collection.regulars, collection.recursive = regulars, recursive
   for name in pairs(recursive) do
      ruleMap[name].recursive = true
   end
   local callSets = graphCalls(rules)
   collection.callSets = callSets
   return callSets
end
```

```lua
function Syn.rules.callSet(rules)
   local collection = rules.collection or rules:collectRules()
   return _callSet(collection.ruleCalls)
end
```


## Analysis




### What is a 'rule'

One of the first things we do is 'reify' the rule structure by assigning
names to any rule which doesn't have one\.  So a rule is any pattern which
recognizes some area of a string in some context\.

The product of Dji may or may not be in a position to work with phantom or
suppressed rules, it may in fact ignore rule structure completely if it is,
say, a validator\.


#### lock rules

A rule is a lock if, once the containing rule has succeeded against this rule,
the container must either succeed the rest of the rule or fail: specifically
it cannot backtrack past a lock rule and succeed\.

Example being `"` for a string and so on, some of them are easy to spot but I
do expect that rules like `("k" b "y") / ("K" B "Y")` will be more
interesting, this is really two rules tried one after the other and inlined,
the rule itself doesn't have a lock but rather two\.  Noting that it has two
locks is easier than reducing the **lock** partof the rule to `{Kk}`\.


#### gate rules

A rule is a gate if it must be passed for the containing rule to succeed\.


```lua
return M
```
