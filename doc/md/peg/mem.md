# Mem


The tools of higher combination\.

```lua
local Clade, Node = use ("cluster:clade", "espalier:peg/node")
```


### \[\#Todo\] Refactor

This is in pretty good shape, I can add some sessions which will stabilize the
key operations, I think\.


#### \[\#Todo\] Use :G\(\)

We have this awkward "collection" we pass around, I've added a method which
causes Nodes to have a table `.g`, which is the tree\-global state\.

I was originally going to keep `.v` on it, but that's kind of dodgy\.  It adds
complexity, and the algorithm based on finding root and adjusting everything
only has bad behavior for very deep trees\.

It's a good fit for a lot of existing Node patterns, honestly\.


#### \[\#Todo\] Vector the Mixin

This isn't inherently useful for Mem, but it's critical for composability that
the codegen mixin be stored in the vector by the name of the method\.


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

Our categories which cut across rule identities\.

```lua
local Q = MemClade.quality
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


##### Other Trait Sets

  These are used in various places in the module, and it's useful to have them
all in one spot\.

Clades should have a way to check the validity of this sort of construct\.

We use these to massage rules into shape:

```lua
local SpecialSnowflake = Set {'set', 'range', 'name',
                               'number', 'literal', 'rule_name'}
local Hoist = Set {'element', 'alt', 'cat'}
```

```lua
local Prefix = Set {'and', 'not', 'to_match'}
local Suffix = Set {'zero_plus', 'one_plus', 'optional', 'repeat'}
local Backref = Set {'backref'}

local Surrounding = Prefix + Suffix + Backref
```


###### Copy Traits

These propagate from rules to their references\.

```lua
local CopyTrait = Set {'locked', 'predicate', 'nullable', 'null', 'terminal',
                   'unbounded', 'compound', 'failsucceeds', 'nofail',
                   'recursive', 'self_recursive'}
```


## Mem Basis

Methods in common to the entire Phyle\.


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

local function synthesize(node)
   if Hoist[node.tag] and #node == 1 then
      local kid = node[1]
      node:hoist()
      node = kid
   end
   for _, twig in ipairs(node) do
      synthesize(twig)
   end
   if SpecialSnowflake[node.tag] then
      extraSpecial(node)
   end
   -- elements
   if node.tag == 'element' then
      analyzeElement(node)
      -- this may make the element have a single child,
      -- so we need to hoist:
      node.parent:hoist()
   elseif node.tag == 'rule' then
      node.token = normalize(node :take 'rule_name' :span())
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
         for trait in pairs(CopyTrait) do
            elem[trait] = mod[trait]
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
   grammar:G().is_synthesized = true
   return grammar
end
```


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


```lua
local sort, nonempty = table.sort, assert(table.nonempty)

function Mem.grammar.collectRules(grammar)
   -- our containers:
   local nameSet, nameMap = Set {}, {} -- #{token*}, token => {name*}
   local dupe, surplus, missing = {}, {}, {} -- {rule*}, {rule*}, {token*}
   local ruleMap = {}   -- token => synth
   local ruleCalls = {} -- token => {name*}
   local ruleSet = Set {}   -- #{rule_name}

   for name in grammar :filter 'name' do
      local token = normalize(name:span())
      name.token = token
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

   local g = grammar:G()
   g.nameSet   = nameSet
   g.nameMap   = nameMap
   g.ruleMap   = ruleMap
   g.ruleCalls = ruleCalls
   g.ruleSet   = ruleSet
   g.dupe      = nonempty(dupe)
   g.surplus   = nonempty(surplus)
   g.missing   = nonempty(missing)


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


### Mem\.grammar\.callSet\(grammar\)

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
function Mem.grammar.callSet(grammar)
   return _callSet(grammar:G().ruleCalls)
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
   local collection = assert(grammar:G())
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
         if (not ruleMap[elem])
            or (not ruleMap[elem].recursive) then
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
function Mem.grammar.analyze(grammar)
   local g = grammar:G()
   if not g.is_synthesized then
      grammar:synthesize()
   end

   grammar:collectRules()

   local regulars, recursive = partition(g.ruleCalls, grammar:callSet())
   local ruleMap = assert(g.ruleMap)
   for name in pairs(recursive) do
      ruleMap[name].recursive = true
   end
   g.regulars, g.recursive = regulars, trimRecursive(recursive, ruleMap)
   g.calls = graphCalls(grammar)
   if g.missing then
      grammar:makeDummies()
   end

   -- we'll switch to using these directly
   for k, v in pairs(g) do
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
function Mem.grammar.anomalies(grammar)
   local coll = grammar:G()
   if not coll then return nil, "collectRules first" end
   if not (coll.missing or coll.surplus or coll.dupe) then
      return nil, "no anomalies detected"
   else
      return { missing = coll.missing,
               surplus = coll.surplus,
               dupe   = coll.dupe }
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

function Mem.grammar.makeDummies(grammar)
   local g = grammar:G()
   if not g.ruleMap then
      g:analyze()
   end
   local missing = g.missing
   if (not missing) or #missing == 0 then
      return nil, 'no rules are missing'
   end
   local dummy_str, pad = {"\n\n"}, " "
   if g.ruleMap['_'] then
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
   g.dummy_rules = concat(dummy_str)
end
```


### grammar:pehFor 'rule'

  Returns the concatenated peg string to recognize a single rule, which will
include rules referenced recursively\.

\#Todo
      use of a shuttle and `added` check here shouldn't be necessary\.

```lua
function Mem.grammar.pehFor(grammar, rule)
   if not grammar:G().ruleMap then
      grammar:collectRules()
   end
   local g = grammar.g
   local calls, ruleMap, missing = g.calls,
                                   g.ruleMap,
                                   g.missing
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

\#Todo
       integrated with the constraint system\.  Nor have backrefs\.

       `to-match` is syntax sugar, and we probably want to unsugar it\.
       Backrefs have meaningful semantics we need to be careful with, but in
       principle it's a lock and gate with unusual semantics\.


#### Propagation

Grammars are recursive, and allow an arbitrary amount of indirection, so our
only hope of completing this constraint process is to reach a fixed point,
where calling `:constrain` on any of the Nodes will have no further effect\.

We've already determined the call 'tiers' for non\-recursive rules, and we
can begin by constraining the rules we call final: those with no references
at all\.

Each regular tier from that point is constrained by constraining the rule,
and propagating the traits to each reference\.

This leaves recursion, direct or otherwise\. We repeatedly constrain rules, and
propagate any changes we've recovered, until every name we see doesn't change
when we copy the traits over\.  At which point the constraints are complete,
and we can do things with them\.


### Base :constrain

Tags the class as having been constrained by the base rule and visits the
kids\.

In the fully mature system we won't have this, it's only here to provide
plausible behavior for classes we hadn't specified\.

```lua
function Basis.constrain(synth, coll)
   for i, elem in ipairs(synth) do
      elem:constrain(coll)
   end
   synth.base_constraint_rule = true
   synth.constrained = true
end
```


#### queueUp\(shuttle, node\)

This keeps us from pushing a node which is already on queue, in particular we
can see a rule many times before we check it again, and this keeps it on the
queue at\-most\-once\.

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

function Mem.grammar.constrain(grammar)
   local g = grammar:G()
   local coll = g
   if not g.ruleMap then
      grammar:analyze()
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
         if not nameMap[name_str] then
            error("missing from nameMap: " .. name_str)
         end
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
function Mem.rule.constrain(rule, coll)
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
   for trait in pairs(CopyTrait) do
      if body[trait] then
        rule[trait] = body[trait]
      end
   end
   rule:propagateConstraints(coll)
end
```


### rule:propagateConstraints\(coll\)

Sends all changes to the rule to each name\.

```lua
function Mem.rule.propagateConstraints(rule, coll)
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
   Mem[class].constrain = termConstrain
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
function Mem.cat.constrain(cat, coll)
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
function Mem.alt.constrain(alt, coll)
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
function Mem.element.constrain(element, coll)
   -- ??
   local again;
   for _, sub in ipairs(element) do
      sub:constrain(coll)
      if sub.constrained then
         for trait in pairs(CopyTrait) do
            element[trait] = element[trait] or sub[trait]
         end
      else
         again = true
      end
   end
   if again then
      queueup(coll.shuttle, element)
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
local function copyTraits(rule, name)
   local changed = false
   for trait in pairs(CopyTrait) do
      if rule[trait] then
         local differs = name[trait] ~= rule[trait]
         changed = changed or differs
         name[trait] = rule[trait]
      end
   end
   if rule.constrained then
      name.constrained = true
      name.constrained_by_rule = true
   else
      name.constrained_by_rule = false
   end

   return changed
end
```


### FIX\_POINT

If we see a name twice with no changes that *should* be it\. So far, so good\.

```lua
local FIX_POINT = 1
```


```lua
function Mem.name.constrain(name, coll)
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


### Next

We need to analyze `alt` groupings for "lock fails rule"\.

This gets intricate\!  We have to compare literals, sets, ranges, with
repetition and lookahead\.

I think the trick is simple: we reduce sets and ranges to the literals, and
test anything else against them\.

Yeah\. Just\.\.\. make the pattern on the spot, try it out\.

If we even have to, because repetitions nest in each other, or don't\.

While we're in there, we're looking for choice shadowing: if a rule will
always consume a rule after it in the choice order, that's a bug\.

With lock fails rule, we can the unhappy paths out of the grammar\.

Then we can start putting together the fragment parser, the error\-recovering
parser with `lpeglable.T`, and all that other fun stuff\.  I expect it will
help with the madcap combinator scheme I have in mind for re\-parsing trees\.\.\.


##### Catching optional repeats

```lua
function Mem.repeated.constrain(repeated, coll)
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




### Codegen Mixin

\#Todo

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

