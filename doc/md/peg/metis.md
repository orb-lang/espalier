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


#### Q\.maybe

Any rule type which doesn't need to be fulfilled\.

Note there is one type of repeat rule `name%0..5` which is also optional but
we must detect this \(we do not as yet\)\.

```lua
Q.maybe = Set {'zero_or_more', 'optional'}
```


#### Q\.compound

```lua
Q.compound = Set {'cat', 'choice'}
```


#### Q\.terminal

Rules which produce cursor movement in and of themselves\.

```lua
Q.terminal = Set {'literal', 'set', 'range', 'number'}
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
   -- this is just for reading purposes, remove
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
   -- this field isn't used but I think it will be
   'final',
   'constrained',
   'o',
   'col',
   'up',
   'node',
}
local _lens = { hide_key = suppress,
                depth = 10 }
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

Nothing past synthesis will work correctly until adjusted to the new structure
of the AST\.

Needed fields:

`set` gets `.value`, `range` gets `.from_char` and `to_char`, `name`,
`number`, `literal`, `rule_name`, all have `.token`\.

I'm going to grab these custom, and may be back someday to rationalize this
module, who knows\.

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
local function _synth(node, parent_synth, i)
   local synth = newSynth(node, i)
   synth.parent = parent_synth or synth
   if SpecialSnowflake[synth.class] then
      extraSpecial(node, synth)
   end
   for i, twig in ipairs(node) do
      synth[i] = _synth(twig, synth, i)
   end
   return synth
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



#### rules:hoist\(\)

Three rules are just noise when they have only one child:

```lua
local Hoist = Set {'element', 'alt', 'cat'}
```

```lua
function M.rules.hoist(rules)
   if rules.hoisted then return rules end
   for i, rule in ipairs(rules) do
      rule:hoist()
   end
   rules.hoisted = true

   return rules
end

function Twig.hoist(twig)
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
function M.rules.synthesize(rules)
   rules.start = rules :take 'rule'

   local synth = _synth(rules)
   s:verb("synthesized %s", synth.class)
   synth.peg_str = rules.peg_str
   rules.synth = synth --- this is useful, ish, at least in helm
   return synth
end
```


## Data gathering

We're just going to be greedy and get our hands on any static relationships
we can, and use them later\.

Broken up into several chunks for clarity\.


### rules:collectRules\(\)

Time for a big ol' info dump\!  May as well grab All The Formats and see where
we get w\. it\.

This builds up a large collection of relational information, while decorating
rules and names with tokens representing their normalized value\.


- returns a map of the following:

  - nameSet:  The set of every name in normalized token form\.

  - nameMap:  The tokens of nameSet mapped to an array of all occurance in the
      grammar\.

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

Probably belongs in core\.

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
function Syn.rules.collectRules(rules)
   -- our containers:
   local nameSet, nameMap = Set {}, {} -- #{token*}, token => {name*}
   local dupe, surplus, missing = {}, {}, {} -- {rule*}, {rule*}, {token*}
   local ruleMap = {}   -- token => synth
   local ruleCalls = {} -- token => {name*}
   local ruleSet = Set {}   -- #{rule_name}

   for name in rules :filter 'name' do
      local token = normalize(name:span())
      name.token = token
      nameSet[token] = true
      local refs = nameMap[token] or {}
      insert(refs, name)
      nameMap[token] = refs
   end

   local start_rule = rules :take 'rule'

   for rule in rules :filter 'rule' do
      local token = normalize(rule :take 'rule_name' :span())
      rule.token = token
      ruleSet[token] = true
      if ruleMap[token] then
         -- lpeg uses the *last* rule defined so we do likewise
         ruleMap[token].duplicate = true
         insert(dupe, ruleMap[token])
      end
      ruleMap[token] = rule
      if not nameSet[token] then
         -- while it is valid to refer to the top rule, it is not noteworthy
         -- when a grammar does not.
         -- rules which are not findable from the start rule aren't part of
         -- the grammar, and are therefore surplus
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
   for name in pairs(nameSet) do
      if not ruleMap[name] then
         insert(missing, name)
      end
   end
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


### Syn\.rules\.callSet\(rules\)

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
function Syn.rules.callSet(rules)
   local collection = rules.collection or rules:collectRules()
   return _callSet(collection.ruleCalls)
end
```


#### graphCalls\(rules\)

  Now that we've obtained all the terminal rules, we can use more set
addition and a queue to obtain the full rule set seen by any other given
rule\.

This returns a map of names to a Set of every rule which can be visited from
that rule name\.  It actually return the two halves \(terminal and regular\) as
well as the union, but it most likely doesn't have to\.

```lua
local function setFor(tab)
   return Set(clone1(tab))
end

local function graphCalls(rules)
   local collection = assert(rules.collection)
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
      ruleMap[name].final = true
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


### rules:analyze\(\)

Pulls together the caller\-callee relationships\.

```lua
function Syn.rules.analyze(rules)
   rules.collection = rules:collectRules()
   local coll = assert(rules.collection)

   local regulars, recursive = partition(coll.ruleCalls, rules:callSet())
   local ruleMap = assert(coll.ruleMap)
   for name in pairs(recursive) do
      ruleMap[name].recursive = true
   end
   coll.regulars, coll.recursive = regulars, recursive
   coll.calls = graphCalls(rules)
   if coll.missing then
      rules:makeDummies()
   end

   return rules:anomalies()
   --rules:constrain()
end
```


### rules:anomalies\(\)

If everything is in order, returns `nil, message`, otherwise, the
less\-than\-perfect aspects of the grammar as\-is\.

```lua
function Syn.rules.anomalies(rules)
   local coll = rules.collection
   if not coll then return nil, "collectRules first" end
   if not (coll.missing or coll.surplus or coll.dupes) then
      return nil, "no anomalies detected"
   else
      return { missing = coll.missing,
               surplus = coll.surplus,
               dupes   = coll.dupes }
   end
end
```


## Constraints

  This algorithm is almost entirely about adding flags to rules as we discover
things about them, then using that knowledge in a surprising number of ways\.


### Ghost Rules

We have three sorts of rules here: shown, hidden, and ghost\.

Shown and hidden rules are straightfoward enough, a ghost rule is any rule we
make out of an un\-named fragment of another rule\.

Most of the time we're concerned with named rules and just call those rules\. A
fragment of grammar without a name we call a pattern, a ghost rule is
something we \(intend to\) *make* out of our patterns for use in Dji\.

At some point we'll have synthetic rules as well, and won't that be fun\.


#### rules:expandRules

This will create and where possible deduplicate literal rules\.

We'll use an obvious naming convention with leading underscores, which are
invalid rule names in the grammar *and this is one of the good reasons*\.


### rules:makeDummies\(\)

Does nothing if `.missing` is empty, otherwise makes dummies of missing rules\.

The dummy rule just matches the string of the missing rule name, which is
exactly what we want\.

```lua
local find, gsub = string.find, string.gsub

local function dumbRule(name, pad, patt)
   return  "`" .. name .. "`  <-  DUMMY-" .. name .. "\n"
           .. "DUMMY-" .. name .. "  <-  " .. pad
           .. patt .. pad .. "\n"
end

function Syn.rules.makeDummies(rules)
   if not rules.collection then
      return nil, 'no analysis has been performed'
   end
   local missing = rules.collection.missing
   if (not missing) or #missing == 0 then
      return nil, 'no rules are missing'
   end
   local dummy_str, pad = {"\n\n"}, " "
   if rules.collection.ruleMap['_'] then
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
   rules.dummy_str = concat(dummy_str)
   return rules.pegparse(rules.dummy_str)
end
```

```lua
local Peg = require "espalier:espalier/peg"

function Syn.rules.dummyParser(rules)
   if not rules.collection then
      rules:collectRules()
   end
   if not rules.collection.missing then
      return nil, "no dummy rules"
   end
   rules:makeDummies()
   local with_dummy = rules.peg_str .. rules.dummy_str
   return Peg(with_dummy):toGrammar()
end
```



### Control Flow Analysis

  We are discovering what requirements a given pattern imposes on the rest of
the Grammar, so we can use this strategically\.

The simplest part is synthesizing what is *mandatory*, each atomic pattern
either is or isn't, and this composes, that composition being our main target
of interest\.


### Locks

One pattern we're looking for is any concatenation of \(at least\) two
elements where the first and the last are both mandatory\.

We know of such a pattern, that once we've passed the first of those elements,
we must pass the final one as well, or abandon the pattern entirely\.

We call such a rule `.locked`, the first element is a lock and the last is a
gate\.

Since left\-recursion is forbidden in PEGs \(Roberto Ierusalimschy says that
it's semantically unclear what it would even mean, although there are a
plethora of papers which disagree\), our task is quite a bit easier if we
presume that the grammar is well\-formed\.

In fact we shouldn't presume this, we should detect left recursion rather than
throwing it at LPEG and seeing if it sticks, but this part of the code will
make that assumption since we can reject lefta recursion earlier in the
pipeline\.


#### lock rules

A rule is a lock if, once the containing rule has succeeded against this rule,
the container must either succeed the rest of the rule or fail: specifically
it cannot backtrack past a lock rule and succeed\.

Example being `"` for a string and so on, some of them are easy to spot but I
do expect that rules like `("k" b "y" / "K" B "Y") "Z"` will be more
interesting, this is really two rules tried one after the other and inlined,
the rule itself doesn't have a lock but rather two\.  Disjoint choice may be
locked between 0 and 2 times, a given cat sequence is or isn't\.

Writing this for later trial: `("k" b "y" / "K" B? "Y?") "Z"` because there's
some sort of distributive rule to apply here\.


#### gate rules

A rule is a gate if it must be passed for the containing rule to succeed\.


##### starting\_fails\_rule

This is an important subcondition for us to look for, the case where a rule
is made up of choices and if one of the choices is **started** but not finished
then the entire rule will fail\.

This will be the case **if**: the subrule is *locked*, and the *lock* of the
subrule is incompatible with the first mandatory match of any subsequent
subrule in the choice\.

An example where this will apply is statements in Lua, many of which begin
with a unique keyword which serves as a lock\.  Once an `"if"` has been
correctly parsed in the right location, no other statement rule can succeed,
so a failure of the `if` rule fails the statement rule\.

`statement` is itself mandatory, and this gets us to error escape analysis\.

Conceptually, negative lookahead has a similar function, but we don't need a
separate flag for it because `not` is the only condition which triggers it\.
Negative lookahead we could call "success fails rule", while `and` gives us
two causes for a failure where we otherwise have only one\.

Positive lookahead isn't as interesting, although it gives us a head start on
error recovery, which is nice\.  It does have this interesting 'pseudomatch'
quality but it will be tricky to extract that in a useful way\.


### rules:constrain\(\)

So let's see what wisdom we might derive\.


### Rethinking it

This first pass tries to handle the recursive nature of the grammar by dealing
with all regulars first\.

It makes more sense to just handle every rule and deal with cycles at the
very end\.

So let's do this in passes\.


- Step 1:  Walk the whole synth and establish basis for constraints, including
    all atomic constraints\.


- Step 2:  Go rulewise and connect references to constraints\.


- Step 3:  Hoist all non\-recursive constraints and derive accordingly\.


#### rules:constrain\(\)

We'll drop caps once this has taken over\.

```lua
function Syn.rules.constrain(rules)
   local coll;
   if rules.collection then
      coll = rules.collection
   else
      rules:analyze()
      coll = assert(rules.collection)
   end
   if rules:anomalies() then
      return nil, "can't constrain imperfect grammar (yet)", rules:anomalies()
   end

   local regulars, ruleMap = coll.regulars, coll.ruleMap
   local nameMap = coll.nameMap
   coll.nameQ = Deque()
   for _, tier in ipairs(regulars) do
      for name in pairs(tier) do
         coll.nameQ:push(name)
         ruleMap[name]:constrain(coll)
      end
      for name_str in pairs(tier) do              -- orphan references
         for _, name in ipairs(nameMap[name_str] or {}) do
            name:constrain(coll)
         end
      end
   end

   for rule in rules :filter 'rule' do
      rule:constrain(coll)
   end

   for name in rules :filter 'name' do
      name:constrain(coll)
   end

   -- lift up regulars

   -- say sensible things about recursives
end
```

```lua
function Syn.rule.constrain(rule, coll)
   local rhs = assert(rule :take 'rhs')
   local body = rhs[1]
   if body.maybe then
      rhs.maybe = true
      rule.maybe = true
   end
   if body.compound then
      body:sumConstraints(coll)
      if body.locked then
         rule.locked = true
      end
   end
   rule.constrained = true
end
```

```lua
function Syn.name.constrain(name, coll)
   local tok = assert(name.token)
   local rule = assert(coll.ruleMap[tok])
   if rule.constrained then
      name.final = rule.final
      name.terminal = rule.terminal
      name.maybe = rule.maybe
      name.locked = rule.locked
      name.constrained = true
      name.unconstrained = nil
   else
      name.unconstrained = true
   end
end
```


#### Compound constraints

```lua
function Syn.cat.sumConstraints(cat, coll)
   local locked;
   local gate;
   local idx;
   for i, sub in ipairs(cat) do
      if sub.compound then
         sub:sumConstraints(coll)
      else
         if sub.constrain then
            sub:constrain(coll)
         else
            sub.unconstrained = true
         end
      end
      if sub.locked or (not sub.maybe) then
         idx = i
         gate = sub
      end
      if (not sub.maybe) then
         if not locked then
            assert(not sub.maybe)
            if sub.token == "_" then sub.seriously = "wtf: " .. tostring(sub.maybe) end
            sub.lock = true
            locked = true
         end
      end
   end

   if gate then
      if gate.lock then
         gate.gate_lock = true
         gate.lock = nil
      else
         gate.gate = true
         for i = idx-1, 1, -1 do
            local sub = cat[i]
            if not sub.terminal then break end
            sub.gate = true
         end
      end
   end

   if locked then
      cat.locked = true
   end
   cat.constrained = true
end
```

```lua
function Syn.alt.sumConstraints(choice, coll)
   local maybe = nil
   for _, sub in ipairs(choice) do
      if sub.compound then
         sub:sumConstraints(coll)
      end
      if sub.maybe then
         maybe = true
         -- for future expansion: this has to be the last rule
         -- to be meaningful under ordered choice
      end
   end
   choice.maybe = maybe
   choice.constrained = true
end
```


##### Catching optional repeates

```lua
function Syn.repeated.constrain(repeated, coll)
   local range = repeated :take 'integer_range'
   if not range then return end
   local start = tonumber(range[1])
   if start == 0 then
      repeated.maybe = true
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



### Arithmetic

```lua
function SynM.__add(grammar, rule)

end
```


```lua
return M
```
