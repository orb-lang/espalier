# Metis

   The system responsible for building, analyzing, and manipulating input into
the Vav combinator\.


## Design

We receive a Grammar in a dialect of PEG, the Vav combinator takes it and
combines it in various ways, this is linked to a Qopf via Dji, producing a
Peh, something which takes a string and outputs a result\.

Analysis and various rule transformations are performed by this module\.

This is a multi\-pass system with no attempt at optimization whatsoever\. The
intention is that, as grammars change infrequently once stable, the results
of these computations will be cached as various useful programs\.


### Taming The Beast

  This does maybe ten percent of what it will do, and the file is pushing a
thousand lines\.

At some point I'll take a time out and write `cluster.clade`, which we can
use to break out various capabilities into their own files, and recombine them
into synth metatables which do All The Things\.


### Synth Nodes

This is officially a pattern since we do the same thing with Scry\.

Here it is particularly important because we expect to do a lot of rewriting
of terms based on underlying strings which will not be identical\.


## Metis

The 'machinery' for this sort of pattern will end up in cluster eventually\.

Here we set it all up by hand for the second time\.


#### imports

```lua
local Node = require "espalier:espalier/node"
local Grammar = require "espalier:espalier/grammar"
local core = require "qor:core" -- #todo another qor
local cluster = require "cluster:cluster"
local table = core.table
local Set = core.set
local Deque = require "deque:deque"
local insert, remove, concat = assert(table.insert),
                               assert(table.remove),
                               assert(table.concat)
local s = require "status:status" ()
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

We'll fill this in as we go deeper\.

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
   local M = Twig :inherit(key)
   metabuild[key] = M
   return metabuild[key]
end
```

```lua
local M = setmetatable({Twig}, {__index = __index})
```


## Rules

This is where we set up the information graph for a given Vav\.


#### builder\(\_new, synth, node, i\)

```lua
local new, Syndex, SynM = cluster.order()

local function builder(_new, synth, node, i)
   synth.up = i
   synth.o = node.first
   synth.node = node
   node.synth = synth
   synth.line, synth.col = node:linePos()
   -- this is just for reading purposes in helm
   -- add a feature to the lens to allow this through
   synth.class = _new.class
   if Q.terminal[synth.class] then
      synth.token = node:span()
   end
   return synth
end

cluster.construct(new, builder)
```


##### Synth lens

Keeps printable data in the synth manageable\.

```lua
local suppress = Set {
   'parent',
   'line',
   ---[[DBG]] --[=[
   'constrained',
   'constrained_by_rule',
   'constrained_by_fixed_point',
   'references',
   'compound',
   --]=]
   'peh',
   'o',
   'col',
   'up',
   'node'
}
local _lens = { hide_key = suppress,
                depth = math.huge }
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

The win might be to cut on compounds\.\.\.

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

First we inherit from `new` if we haven't seen the class aka node `.id`,
decorating with applicable qualia:

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

The goal with clades is to allow these sorts of methods to be composable
without any visitor BS, once again we're handrolling here\.


#### Reporting


##### synth:pathName\(\)


```lua
function Syndex.pathName(synth)
   local phrase, stack = {}, {synth.class}
   local parent = synth.parent
   while parent ~= parent.parent do
      insert(stack, parent.class)
      parent = parent.parent
   end
   while #stack > 0 do
      insert(phrase, remove(stack))
      insert(phrase, "/")
   end
   phrase[#phrase] = ":"
   insert(phrase, synth.token or "none")
   return concat(phrase)
end
```


##### synth:parentRule\(\) :withinRule\(\)

Returns the parent rule of the part, or the token for it, respectively

```lua
function Syndex.parentRule(synth)
   if synth.class == 'rule' then return nil, 'this is a rule' end
   if synth.class == 'grammar' then return nil, 'this is a grammar' end
   local parent = synth.parent
   while parent ~= parent.parent do
      if parent.class == 'rule' then
         return parent
      else
         parent = parent.parent
      end
   end
   return nil, 'mistakes were made (new tree structure?)'
end
```

```lua
function Syndex.withinRule(synth)
   local rule, why = synth:parentRule()
   if not rule then
      return nil, why
   end
   return rule.token
end
```


#### Traversal

```lua
local walk = require "gadget:walk"

local depth, filter, reduce = assert(walk.depth),
                              assert(walk.filter),
                              assert(walk.reduce)

Syndex.walk = depth

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

local curry = assert(core.fn.curry)

local function setfilter(set, node)
   return set[node.class]
end

function _filter(synth, pred)
   if type(pred) == 'string' then
      return filter(synth, filterer(pred))
   elseif type(pred) == 'table' then
      -- presume a Set
      return filter(synth, curry(pred))
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

While these may be useful, they are as yet unused:

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

Is just pass, we can add a tagger if we need to track down missing cases\.

```lua
Syndex.synthesize = cluster.ur.pass
Syndex.analyze = cluster.ur.pass
```


#### \_synth\(node\)

Let's get this out of the way real quick\.


##### Custom Synthesis

Here we decorate particular synth nodes with useful representations and
contextual information\.

```lua
local SpecialSnowflake = Set {'set', 'range', 'name',
                               'number', 'literal', 'rule_name'}

local function extraSpecial(node, synth)
   local c = synth.class
   if c == 'range' then
      synth.from_char, synth.to_char = node[1]:span(), node[2]:span()
   elseif c == 'set' then
      synth.value = node:span()
   elseif c == 'name' or c == 'rule_name' then
      synth.token = normalize(node:span())
   else
      synth.token = node:span()
   end
end
```


```lua
local analyzeElement;

-- note: better lenses obviate this
local allpairs = table.allpairs

local s = use "status:status" ()
s.verbose = false

local function _synth(node, parent_synth, i)
   local synth = newSynth(node, i)
   s:verb("synthesizing %s", node.id)
   synth.parent = parent_synth or synth
   ---[[ we copy the flags so I can see them in helm :/
   for key, value in allpairs(synth) do
      if type(value) == 'boolean' then
         synth[key] = value
      end
   end --]]
   if SpecialSnowflake[synth.class] then
      extraSpecial(node, synth)
   end
   for i, twig in ipairs(node) do
      synth[i] = _synth(twig, synth, i)
   end
   -- elements
   if synth.class == 'element' then
      analyzeElement(synth)
   end
   if synth.class == 'rule' then
      synth.token = assert(synth :take 'rule_name' . token)
   end
   return synth
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
local Prefix = Set {'and', 'not'}
local Suffix = Set {'zero_plus', 'one_plus', 'optional', 'repeat'}
local Backref = Set {'backref'}

local Surrounding = Prefix + Suffix + Backref
```

```lua
function analyzeElement(elem)
   local prefixed, backrefed  = Prefix[elem[1].class],
                                Backref[elem[#elem].class]
   local suffixed;
   if backrefed then
      suffixed = Suffix[elem[#elem-1].class]
   else
      suffixed = Suffix[elem[#elem].class]
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
   assert(part and (not Surrounding[part.class]),
          "weirdness encountered analyzing element")
   for _, mod in pairs(modifier) do
      if mod then
         elem[mod.class] = true
         local traits = Prop[mod.class]
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


### Codegen Mixin

Eventually this is clade\-native behavior\.

```lua
local codegen = require "espalier:peg/codegen"

for class, mixin in pairs(codegen) do
   for trait, method in pairs(mixin) do
      Syn[class][trait] = method
   end
end
```


#### grammar:hoist\(\)

Three rules are just noise when they have only one child:

```lua
local Hoist = Set {'element', 'alt', 'cat'}
```

So we eliminate them by 'hoisting' the child to the parent's index on the
grandparent\.

This implementation has to hoist twice, for some obvious\-in\-retrospect reason
I'm having trouble caring about\. Node 2\.0 will feature hoisting as a native
operation\.

```lua
function M.grammar.hoist(grammar)
   if grammar.hoisted then return grammar end
   for i, rule in ipairs(grammar) do
      rule:hoist()
   end
   grammar.hoisted = true

   return grammar
end

function Twig.hoist(twig)
   if #twig == 0 then return twig end
   for i, ast in ipairs(twig) do
      if #ast == 1 and Hoist[ast.id] then
         twig[i] = ast[1]:hoist()
      else
         ast:hoist()
      end
   end
   -- this makes zero sense but I'm missing hoists somehow
   for i, ast in ipairs(twig) do
      if #ast == 1 and Hoist[ast.id] then
         twig[i] = ast[1]:hoist()
      else
         ast:hoist()
      end
   end
   return twig
end
```

```lua
function M.grammar.synthesize(grammar)
   grammar.start = grammar :take 'rule'
   local synth = _synth(grammar)
   ---[[DBG]] synth.Prop = Prop
   s:verb("synthesized %s", synth.class)
   synth.peh = grammar.peh
   grammar.synth = synth --- this is useful, ish, at least in helm
   return synth
end
```


## Data gathering: grammar:analyze\(\)


  This is where we digest the implicit recursive structure of the grammar into
various explicit and useful forms\.

This concludes by sorting the grammar into ordinary, meaning it has no
missing, surplus, or duplicated rules, and anomalous, the antonym\.

This is broken up into several subsidiary methods and helper functions,
largely for the purpose of clarity\.  Everything in this section is expected to
be accessed through `:analyze`\.


### grammar:collectRules\(\)

This builds up a large collection of relational information, while decorating
rules and names with tokens representing their normalized value\.


- returns a map of the following:

  - nameSet:  The set of every name in normalized token form\.

  - nameMap:  The tokens of nameSet mapped to an array of all right hand side
      references in the grammar\.

  - ruleMap:  A map from the rule name \(token\) to the synthesized rule\.

  - ruleCalls:  A map of the token for a rule to an array of the name of each
      rule it calls\. This overwrites duplicate rules, which don't
      interest me very much except as something we lint and prune\.

  - ruleSet:  A set containing the name of all defined rules\.

  - dupe:  An array of any rule synth which has been duplicated later\.  The
      tools follow the semantics of lpeg, which overwrites a `V"rule"`
      definition if it sees a second one\.

  - surplus:  An array of any rule which isn't referenced by name on the
      right hand side\.

  - missing:  Any rule referenced by name which isn't defined in the grammar\.



#### nonempty\(tab\)

Returns a table in the event it has \(array\) contents, otherwise `nil`\.

Good candidate for `core`\.

```lua
local function nonempty(tab)
   if #tab > 0 then
      return tab
   else
      return nil
   end
end
```


```lua
local sort = table.sort

function Syn.grammar.collectRules(grammar)
   -- our containers:
   local nameSet, nameMap = Set {}, {} -- #{token*}, token => {name*}
   local dupe, surplus, missing = {}, {}, {} -- {rule*}, {rule*}, {token*}
   local ruleMap = {}   -- token => synth
   local ruleCalls = {} -- token => {name*}
   local ruleSet = Set {}   -- #{rule_name}

   for name in grammar :filter 'name' do
      -- #Todo: this is probably the second time this happens?
      -- this, and the second one with rule_name, can be changed to
      -- asserts, then removed
      local token = assert(name.token)
      nameSet[token] = true
      local refs = nameMap[token] or {}
      insert(refs, name)
      nameMap[token] = refs
   end

   local start_rule = grammar :take 'rule'

   for rule in grammar :filter 'rule' do
      local token = assert(rule.token)
      rule.references = nameMap[token]
      ruleSet[token] = true
      if ruleMap[token] then
         -- lpeg uses the *last* rule defined so we do likewise
         ruleMap[token].duplicate = true
         insert(dupe, ruleMap[token])
      end
      ruleMap[token] = rule
      if not nameSet[token] then
         --  While it is valid to refer to the top rule, it isn't noteworthy
         --  when a grammar does not.
         --  Rules which are not findable from the start rule aren't part of
         --  the grammar, and are therefore surplus
         if rule ~= start_rule then
            rule.surplus = true
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

   -- account for missing rules (referenced but not defined)
   for name in pairs(nameSet) do
      if not ruleMap[name] then
         insert(missing, name)
      end
   end
   sort(missing)

   return { nameSet   =  nameSet,
            nameMap   =  nameMap,
            ruleMap   =  ruleMap,
            ruleCalls =  ruleCalls,
            ruleSet   =  ruleSet,
            dupe      =  nonempty(dupe),
            surplus   =  nonempty(surplus),
            missing   =  nonempty(missing), }
end
```


#### partition\(ruleCalls\)

This partitions the rules into regular and recursive\.

'Regular' here is not 100% identical to 'regular language' due to references
and lookahead, but it's suitably close\.

\#improve
it as an accumulator i\.e\. `set = set + newSet` is generally wasteful and
we can drop some allocation pressure by iteration and setting to true\.  This
would call for profiling, and is only worth considering because programmatic
generation of fairly complex grammar is on the horizon\.

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


### Syn\.grammar\.callSet\(grammar\)

This makes Sets non\-destructively out of arrays of rule names, which might not
have to be non\-destructive, but comes with no disadvantages at this point\.

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

```lua
function Syn.grammar.callSet(grammar)
   local collection = grammar.collection or grammar:collectRules()
   return _callSet(collection.ruleCalls)
end
```


#### graphCalls\(grammar\)

  Now that we've obtained all the terminal rules, we can use more set
addition and a queue to obtain the full rule set seen by any other given
rule\.

This returns a map of names to a Set of every rule which can be visited from
that rule name, followed by the regular and recursive halves, which we do not
currently collect\.

```lua
local function setFor(tab)
   return Set(clone1(tab))
end

local function graphCalls(grammar)
   local collection = assert(grammar.collection)
   local ruleCalls, ruleMap = assert(collection.ruleCalls),
                               assert(collection.ruleMap)
   local regulars = assert(collection.regulars)

   -- go through each layer and build the full dependency tree for regular
   -- rules
   local regSets = {}

   -- first set of rules have no named subrules
   -- which we call 'final'
   local depSet = regulars[1]
   for name in pairs(depSet) do
      ---[[DBG]] ruleMap[name].final = true
      regSets[name] = Set {}
   end
   -- second tier has only the already-summoned direct calls
   depSet = regulars[2] or {}
   for name in pairs(depSet) do
      regSets[name] = setFor(ruleCalls[name])
   end
   -- the rest is set arithmetic
   for i = 3, #regulars do
      depSet = regulars[i]
      for name in pairs(depSet) do
         local callSet = setFor(ruleCalls[name])
         for _, called in ipairs(ruleCalls[name]) do
            callSet = callSet + regSets[called]
         end
         regSets[name] = callSet
      end
   end

   --  the regulars collected, we turn to the recursives and roll 'em up
   local recursive = assert(collection.recursive)
   local recurSets = {}

   -- make a full recurrence graph for one set
   local function oneGraph(name, callSet)
      local recurSet = callSet + {}
      -- start with known subsets
      for elem in pairs(callSet) do
         local subSet = regSets[elem] or recurSets[elem]
         if subSet then
            recurSet = recurSet + subSet
         end
      end
      -- run a queue until we're out of names
      local shuttle = Deque()
      for elem in pairs(recurSet) do
         shuttle:push(elem)
      end
      for elem in shuttle:popAll() do
         for _, name in ipairs(ruleCalls[elem] or {}) do
            if not recurSet[name] then
               shuttle:push(name)
               recurSet[name] = true
            end
         end
      end

      recurSets[name] = recurSet
   end

   for name, callSet in pairs(recursive) do
      oneGraph(name, callSet)
   end
   local allCalls = clone1(regSets)
   for name, set in pairs(recurSets) do
      allCalls[name] = set
   end
   return allCalls, regSets, recurSets
end
```


#### trimRecursive\(recursive\)

```lua
local function trimRecursive(recursive, ruleMap)
   for rule, callset in pairs(recursive) do
      for elem in pairs(callset) do
         if not ruleMap[elem].recursive then
            callset[elem] = nil
         end
      end
   end

   return recursive
end
```


### grammar:analyze\(\)

Pulls together the caller\-callee relationships\.

```lua
function Syn.grammar.analyze(grammar)
   grammar.collection = grammar:collectRules()
   local coll = assert(grammar.collection)

   local regulars, recursive = partition(coll.ruleCalls, grammar:callSet())
   local ruleMap = assert(coll.ruleMap)
   for name in pairs(recursive) do
      ruleMap[name].recursive = true
   end
   coll.regulars, coll.recursive = regulars, trimRecursive(recursive, ruleMap)
   coll.calls = graphCalls(grammar)
   if coll.missing then
      grammar:makeDummies()
   end

   -- we'll switch to using these directly
   for k, v in pairs(coll) do
      grammar[k] = v
   end


   return grammar:anomalies()
end
```


## Anomalous Grammars

A grammar is anomalous if it has missing, duplicate, or surplus rules\.

Duplicate rules are a simple error, since the only semantic of a duplicate
rule is to overwrite the earlier with the latter, so we have no further
action to take in the moments before the mistake is corrected by the user\.

Missing rules we can account for by building placeholders, which we do\.

Surplus rules are an interesting case, because there is a coherent kind of
surplus rule or rules: an alternate grammar built partially or wholly from
rules referenced from the start rule of the grammar\.

The intention of the Vav framework is that it will be tractable to assemble
this sort of rule from parts, and this is more clear than embedding several
grammars into one\.

But it's a coherent action to take on surplus rules, the semantic is clear
enough, and we'll consider doing it\.


### grammar:anomalies\(\)

If everything is in order, returns `nil, message`, otherwise, the
less\-than\-perfect aspects of the grammar as\-is\.

```lua
function Syn.grammar.anomalies(grammar)
   local coll = grammar.collection
   if not coll then return nil, "collectRules first" end
   if not (grammar.missing or grammar.surplus or grammar.dupes) then
      return nil, "no anomalies detected"
   else
      return { missing = grammar.missing,
               surplus = grammar.surplus,
               dupes   = grammar.dupes }
   end
end
```


## Peh Methods


  Various functions to produce a Peh: a string in PEG format specifying a
grammar\.


### grammar:makeDummies\(\)

Does nothing if `.missing` is empty, otherwise makes dummies of missing rules\.

The dummy rule just matches the string of the missing rule name, giving us a
reasonable placeholder to allow testing of portions of a grammar before
filling in the remaining clauses\.

```lua
local find, gsub = string.find, string.gsub

local function dumbRule(name, pad, patt)
   return   name .. "  <-  " .. pad .. patt .. pad .. "\n"
end

function Syn.grammar.makeDummies(grammar)
   if not grammar.collection then
      return nil, 'no analysis has been performed'
   end
   local missing = grammar.missing
   if (not missing) or #missing == 0 then
      return nil, 'no rules are missing'
   end
   local dummy_str, pad = {"\n\n"}, " "
   if grammar.ruleMap['_'] then
      pad = " _ "
   end
   for _, name in ipairs(missing) do
      local patt;
      if find(name, "_") then
         patt = '"' .. (gsub(name, "_", '" {-_} "') .. '"')
      else
         patt = '"' .. name .. '"'
      end
      insert(dummy_str, dumbRule(name, pad, patt))
   end
   grammar.dummy_rules = concat(dummy_str)
end
```


### grammar:pehFor 'rule'

  Returns the concatenated peg string to recognize a single rule, which will
include rules referenced recursively\.

\#Todo
      use of a shuttle and `added` check here shouldn't be necessary\.

```lua
function Syn.grammar.pehFor(grammar, rule)
   if not grammar.collection then
      grammar:collectRules()
   end

   local calls, ruleMap, missing = grammar.calls,
                                   grammar.ruleMap,
                                   grammar.missing
   local phrase =  {}
   insert(phrase, ruleMap[rule]:span())

   local shuttle = Deque()
   shuttle :push(calls[rule])
   local added = {rule = true}
   for call_set in shuttle :popAll() do
      for rule_name in pairs(call_set) do
         if not added[rule_name] then
            added[rule_name] = true
            if ruleMap[rule_name] then
               insert(phrase, ruleMap[rule_name]:span())
               shuttle :push(calls[rule_name])
            end
         end
      end
   end

   return concat(phrase, "\n\n")
end
```


## Constrain

  The constraint phase of the algorithm uses the mappings established in
analysis to provide insight into the compound and recursive structure of the
grammar\.

`:constrain` requires that the grammar be ordinary, not anomalous: we don't
bother doing fancy things with under or over\-specified grammars\.


#### Fixed Point

Grammars are recursive, and allow an arbitrary amount of indirection, so our
only hope of completing this constraint process is to reach a fixed point,
where calling `:constrain` on any of the Nodes will have no further effect\.

The most straightforward way to do this is to run a queue and push anything
which isn't complete onto it\.

When the initial passes are complete, we pop\-and\-push on the queue until
everything is relaxed\.

The trick will be knowing when a node has no further possibility of traits
changing\.


### Base :constrain

Tags the class as having been constrained by the base rule and visits the
kids\.

```lua
function Syndex.constrain(synth, coll)
   for i, elem in ipairs(synth) do
      elem:constrain(coll)
   end
   synth.base_constraint_rule = true
   synth.constrained = true
end
```


#### queue 'tater

This is just to strip the work queue down to something readable when it
overflows, which should never happen when this code is stable\.

```lua
local function queuetate(node)
   if node == false then return false end
   return node:pathName()
end
```


#### queueUp\(shuttle, node\)

This keeps us from pushing a node which is already on queue, in particular,
a rule will not be pushed each time it's seen, meaning that all names waiting
on that rule will be behind it\.

```lua
local function queueUp(shuttle, node)
   if node.on then return end
   node.on = true
   shuttle:push(node)
end
```


### grammar:constrain\(\)

Performs the post\-analysis constraint satisfaction\.


#### BAIL\_AT

The queue can potentially run for a long time in a grammar with many rules, so
we set this reasonably high\.

In principle we should be able to get a good guess based on the complexity
we've already collected but\.  But\.

```lua
local BAIL_AT = 16384
```

```lua
local mutate = assert(table.mutate)

function Syn.grammar.constrain(grammar)
   local coll;
   if grammar.collection then
      coll = grammar.collection
   else
      grammar:analyze()
      coll = assert(grammar.collection)
   end
   if grammar:anomalies() then
      return nil, "can't constrain imperfect grammar (yet)", grammar:anomalies()
   end

   local regulars, ruleMap = coll.regulars, coll.ruleMap
   local nameMap = coll.nameMap
   coll.nameQ = Deque()
   local shuttle = Deque()
   coll.shuttle = shuttle
   local seen = {}
   for i, tier in ipairs(regulars) do
      for name in pairs(tier) do
         coll.nameQ:push(name)
         ruleMap[name]:constrain(coll)
         seen[name] = true
      end
      for name_str in pairs(tier) do
         for _, name in ipairs(nameMap[name_str]) do
            ---[[DBG]] name.seen_at = i
            name:constrain(coll)
         end
      end
   end
   for rule in grammar :filter 'rule' do
      -- should be redundant to include the rules already in
      -- seen above
      if not seen[rule.token] then
         queueUp(shuttle, rule)
      end
   end
   local bail = 0
   for node in shuttle:popAll() do
      if type(node) == 'table' then
         ---[[DBG]] node.popped = node.popped and node.popped + 1 or 1
         node.on = nil
         bail = bail + 1
         node:constrain(coll)
         if bail > BAIL_AT then
            grammar.had_to_bail = true
            grammar.no_constraint = {}
            for rule in grammar :filter 'rule' do
               if not rule.constrained then
                  grammar.no_constraint[rule.token] = rule
               end
            end

            mutate(shuttle, queuetate)
            break
         end
      else
         -- bad shape?
         local ts = require "repr:repr".ts_color
         local bare = require "valiant:replkit".bare
         error((
            "weird result %s from queue %s")
                :format(tostring(node), ts(bare(shuttle))))
      end
   end
   grammar.nodes_seen = bail
   grammar.had_to_bail = not not grammar.had_to_bail
end
```


### rule:constrain\(coll\)

Constrains an individual rule\.

```lua
function Syn.rule.constrain(rule, coll)
   local rhs = assert(rule :take 'rhs')
   assert(#rhs == 1, "bad arity on RHS")
   local body = rhs[1]
   body:constrain(coll)
   if body.constrained then
      rule.constrained = true
      rhs.constrained = true
   else
      queueUp(coll.shuttle, rule)
   end
   rule:propagateConstraints(coll)
end
```


### rule:propagateConstraints\(coll\)

Sends all changes to the rule to each name\.

```lua
function Syn.rule.propagateConstraints(rule, coll)
   if rule.references then -- could be the start rule
      for _, ref in ipairs(rule.references) do
         ref:constrain(coll)
         -- this should only be necessary on change
         -- we make sure the rule is looked at again
         if ref.changed then
            local rule = ref:parentRule()
            queueUp(coll.shuttle, rule)
         end
      end
   end
end
```


### terminals

```lua
local function termConstrain(terminal)
   terminal.constrained = true
end

for class in pairs(Q.terminal) do
   Syn[class].constrain = termConstrain
end
```


### Compound constraints: cat, alt

Cat and alt are where all the fancy happens, we need to look for 'locked' cat
rules: those which, once started, will fail if they don't reach a specific
end rule and succeed\.


#### cat

This is where the most intricate stuff happens, which I will document when it
settles all the way down\.

```lua
function Syn.cat.constrain(cat, coll)
   local locked;
   local gate;
   local idx;
   local again;
   local terminal = true
   local nofail = true
   local nullable = true
   for i, sub in ipairs(cat) do
      -- reset our conditions because we routinely do this several times
      sub.lock, sub.dam, sub.gate, sub.gate_lock = nil, nil, nil, nil

      sub:constrain(coll)

      if not sub.constrained then
         again = true
      end

      if (not sub.nullable) or sub.predicate then
         idx = i
         gate = sub
         if (not locked) then
            sub.lock = true
            locked = true
         else
            sub.dam = true
         end
      end

      if sub.terminal or sub.predicate then
         terminal = terminal and true
      else
         terminal = false
      end

      if sub.unbounded then
         cat.unbounded = true
      end
      nofail = nofail and sub.nofail
      nullable = nullable and sub.nullable
   end

   cat.terminal = terminal or nil
   cat.nofail   = nofail or nil
   cat.nullable = nullable or nil
   cat.constrained = not again

   if gate then
      gate.dam = nil
      if gate.lock then
         gate.gate_lock = true
         gate.lock = nil
      else
         gate.gate = true
         -- look for other unfailable /terminal/ rules
         -- at-most-one unbounded gate at the end
         if not gate.unbounded then
            for i = idx-1, 1, -1 do
               local sub = cat[i]
               if not sub.terminal then break end
               sub.gate = true
               sub.dam = nil
            end
         end
      end
   else
      locked = false -- right? lock but no gate = not locked
   end

   if locked then
      cat.locked = true
   end
end
```

```lua
function Syn.alt.constrain(alt, coll)
   local nofail, nullable = nil, nil
   local again;
   local locked = true
   local terminal = true
   for _, sub in ipairs(alt) do
      sub:constrain(coll)
      if not sub.constrained then
         again = true
      end
      if sub.unbounded then
         alt.unbounded = true
      end
      terminal = terminal and sub.terminal

      nofail = nofail or sub.nofail
      nullable = nullable or sub.nullable
      locked = locked and sub.locked
   end
   alt.nofail      = nofail
   alt.nullable    = nullable
   alt.terminal    = terminal or nil
   alt.locked      = locked   or nil
   alt.constrained = not again
end
```



### element:constrain\(coll\)

```lua
function Syn.element.constrain(element, coll)
   -- ??
   local again;
   for _, sub in ipairs(element) do
      sub:constrain(coll)
      if not sub.constrained then
         again = true
      end
   end
   element.constrained = not again
end
```



### name:constrain\(coll\)

This is all about copying traits from the rule body to the reference\.

We have to handle a self\-reference carefully: the first time we see it, we're
still collecting the other properties, so we push the rule again and tag the
name\.

Welp\. Obvious once I see it but, self\-recursion only breaks the tie sometimes,
and we have to handle arbitrary cycles\.

What we do is count "copy with no change" and if we see it four times, we're
done\.

Four? It's not correct, I'm reasonably confident\.  One 'no change' can/does
happen if a rule body hasn't been constrained at all, two in a row is waiting
on one level of indirection, this is satisfied in three, so four takes care of
two\.

I need some sessions demonstrating the accomplishments and limits here,
because all of this needs to be *correct* and that will involve more
sophistication than this "lol doesn't seem like it's moving" approach shown
here\.


#### copyTraits\(rule, name\): changed: b

Copies over traits, returning `true` if any of the copied traits has changed
the state of `name`\.

```lua
local Trait = Set {'locked', 'predicate', 'nullable', 'terminal',
                   'unbounded', 'compound', 'failsucceeds', 'nofail',
                   'recursive', 'self_recursive'}

local function copyTraits(rule, name)
   local changed = false
   for trait, state in pairs(rule) do
      if Trait[trait] then
         local differs = name[trait] ~= state
         changed = changed or differs
         name[trait] = state
      end
   end
   local body = rule :take 'rhs' [1]
   for trait, state in pairs(body) do
      if Trait[trait] then
         local differs = name[trait] ~= state
         changed = changed or differs
         name[trait] = state
      end
   end
   if body.constrained then
      name.constrained = true
      name.constrained_by_rule = true
   else
      name.constrained_by_rule = false
   end

   return changed
end
```


### FIX\_POINT

If we see a name twice with no changes that *should* be it\.

```lua
local FIX_POINT = 2
```


```lua
function Syn.name.constrain(name, coll)
   if name.constrained then return end
   local token = assert(name.token)
   local rule = assert(coll.ruleMap[token])
   local self_ref = token == name:withinRule()
   if self_ref then
      rule.self_recursive = true
      rule.unbounded = true
      if name.seen_self then
         name.seen_self = nil
      else
         name.seen_self = true
         queueUp(coll.shuttle, rule)
         return
      end
   end
   local changed = copyTraits(rule, name)
   ---[[DBG]] name.changed = changed
   if not changed then
      name.no_change = name.no_change and name.no_change + 1 or 1
      if name.no_change > FIX_POINT then
         ---[[DBG]] --[[
         name.no_change = nil --]]
         name.constrained_by_rule = nil
         name.constrained_by_fixed_point = true
         name.constrained = true
      end
   end
   if not name.constrained then
      queueUp(coll.shuttle, rule)
   else ---[[DBG]] --[[
      name.no_change = nil -- no longer relevant --]]
   end
end
```


##### Catching optional repeats

```lua
function Syn.repeated.constrain(repeated, coll)
   local range = repeated :take 'integer_range'
   if not range then return end
   local start = tonumber(range[1])
   if start == 0 then
      repeated.nofail = true
      repeated.nullable = true
   end
   repeated.constrained = true
end
```


### Rule Ordering and Grouping

We want this for formatting and a bunch of other good reasons\.

The algorithm:

Start rule is its own group\.

First block is everything mentioned in the start rule, in order\.

Second block is everything mentioned in the first block, and so on\.

This is for a **normal form**, not necessarily how we pretty\-print, which can be
more intelligent about putting things like whitespace at the end where they
belong\.


```lua
return M
```
