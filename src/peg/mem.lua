





local Clade, Node = use ("cluster:clade", "espalier:peg/node")






























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








local core = use "qor:core"
local table = core.table
local Set = core.set
local Deque = use "deque:deque"
local insert, remove, concat = assert(table.insert),
                               assert(table.remove),
                               assert(table.concat)
local s = use "status:status" ()
s.verbose = false











local gsub = assert(string.gsub)

local function normalize(str)
   return gsub(str, "%-", "%_")
end








local Q = MemClade.quality











Q.nofail = Set {'zero_plus', 'optional'}








Q.predicate = Set {'and', 'not'}











Q.failsucceeds = Set {'not'}








Q.nullable = Q.predicate + Q.nofail






Q.compound = Set {'cat', 'alt'}








Q.terminal = Set {'literal', 'set', 'range', 'number'}











Q.unbounded = Set { 'zero_plus', 'one_plus' }





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













local SpecialSnowflake = Set {'set', 'range', 'name',
                               'number', 'literal', 'rule_name'}
local Hoist = Set {'element', 'alt', 'cat'}



local Prefix = Set {'and', 'not', 'to_match'}
local Suffix = Set {'zero_plus', 'one_plus', 'optional', 'repeat'}
local Backref = Set {'backref'}

local Surrounding = Prefix + Suffix + Backref









local CopyTrait = Set {'locked', 'predicate', 'nullable', 'null', 'terminal',
                   'unbounded', 'compound', 'failsucceeds', 'nofail',
                   'recursive', 'self_recursive'}








local Locks = Set {'cat', 'alt', 'group', 'element', 'name'}








local tablib = require "repr:tablib"
local yieldName = assert(tablib.yieldName)
local yieldReprs = assert(tablib.yieldReprs)
local yieldToken = assert(tablib.yieldToken)
local concat = assert(table.concat)
local floor = math.floor
local sort = table.sort
local sub = string.sub

local function blurb(node, w, c)
   if not (node.o and node.O and node.str) then return end
   local span = node:span()
   local width = w.width
   if #span > width - 12 then
      local half = floor(width / 4)
      local head, tail = sub(span, 1, half), sub(span, -half -1, -1)
      span = c.string(head) .. c.stresc(" ⋯ ") .. c.string(tail)
      span = span
                :gsub("\n+", c.greyscale("◼︎") .. c.string())
                :gsub("[ ]+", c.greyscale("␣") .. c.string())
   else
      span = c.string(span)
   end

   local V = c.number("v" .. node.v)
   local skew = c.bold(tostring(node.O - node.o))
   local first = V..skew.." "..c.metatable(node.tag)..": ".." "..span.."\n"
   local second = {}
   for trait in pairs(CopyTrait) do
      if node[trait] then
         insert(second, c["true"](trait))
      end
   end
   sort(second)
   if #second == 0 then
      return first
   else
      return first .. concat(second, "::")
   end
end



local Lens = use "repr:lens"
local Set = core.set

local suppress = Set {
   'parent',
   'up',
   'str',
   'o', 'O', 'v',
   'stride',
   'references',
   'modified',
   ---[[DBG]] --[=[
   'constrained_by_rule',
   'constrained_by_fixed_point',
   'compound',
   --]=]
} + CopyTrait

local lens = { hide_key = suppress,
               blurb = blurb,
               depth = math.huge }
Mem_M.__repr = Lens(lens)















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








function Basis.nameOfRule(mem)
   local rule, why = mem:parentRule()
   if not rule then
      return nil, why
   end
   return rule.token
end








function Basis.nameOf(mem)
   return mem.token or mem.tag
end


















local function extraSpecial(node)
   local c = node.tag
   if c == 'range' then
      node.from_char, node.to_char = node[1]:span(), node[2]:span()
      -- we'll use this in codegen #todo
      node.ASCII = #node.from_char == 1 and #node.to_char == 1
   elseif c == 'set' then
      node.value = node:span()
   elseif c == 'name' or c == 'rule_name' then
      node.token = normalize(node:span())
   else
      node.token = node:span()
   end
end



local analyzeElement;

local function synthesize(node)
   for _, twig in ipairs(node) do
      synthesize(twig)
   end
   if SpecialSnowflake[node.tag] then
      extraSpecial(node)
   end
   -- elements
   if node.tag == 'element' then
      analyzeElement(node)
   elseif node.tag == 'rule' then
      node.token = normalize(node :take 'rule_name' :span())
   end
   return node
end















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
         elem.modified = true
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



local function toHoist(node)
   return Hoist[node.tag]
          and #node == 1
          and (not node.modified)
end







function Mem.grammar.synthesize(grammar)
   grammar.start = grammar :take 'rule'
   synthesize(grammar)
   local shuttle = Deque()
   for twig in grammar :walk() do
      if toHoist(twig) then
         shuttle:push(twig)
      end
   end
   for twig in shuttle:popAll() do
      twig:hoist()
   end
   grammar:G().is_synthesized = true
   return grammar
end















































local sort, nonempty, getset = table.sort,
                               assert(table.nonempty),
                               assert(table.getset)

function Mem.grammar.collectRules(grammar)
   if not grammar:G().is_synthesized then
      grammar:synthesize()
   end
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
      local refs = getset(nameMap, token)
      insert(refs, name)
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

   -- add our collections to the general table
   local g = grammar:G()
   g.start = start_rule
   g.nameSet   = nameSet
   g.nameMap   = nameMap
   g.ruleMap   = ruleMap
   g.ruleCalls = ruleCalls
   g.ruleSet   = ruleSet
   g.dupe      = nonempty(dupe)
   g.surplus   = nonempty(surplus)
   g.missing   = nonempty(missing)
end

















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









local clone1 = assert(table.clone1)

local function _callSet(ruleCalls)
   local callSet = {}
   for name, calls in pairs(ruleCalls) do
      callSet[name] = Set(clone1(calls))
   end
   return callSet
end



function Mem.grammar.callSet(grammar)
   return _callSet(grammar:G().ruleCalls)
end














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








-- local partition, trimRecursive, graphCalls;

function Mem.grammar.analyze(grammar)
   local g = grammar:G()
   if not g.is_synthesized then
      grammar:synthesize()
   end
   if not g.ruleMap then
      grammar:collectRules()
   end

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

   local any, why = grammar:anomalies()
   if not any then
      g.is_analyzed = true
   end
   return any, why
end































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



















































function Basis.constrain(basis, coll)
   for i, elem in ipairs(basis) do
      elem:constrain(coll)
   end
   basis.base_constraint_rule = true
   basis.constrained = true
   local g = basis:G()
   insert(getset(g, 'unconstrained'), basis.tag)
end










local function queueUp(shuttle, node)
   if node.on then return end
   node.on = true
   shuttle:push(node)
end






function Basis.enqueue(basis)
   if basis.on then return end
   local g = basis:G()
   basis.seen = basis.seen and basis.seen + 1 or 1
   g.count = g.count + 1
   if g.count > 2^16 then
      for term in g.shuttle:popAll() do
         term.on = nil
         term.stuck_in_limbo = true
      end
      error "shuttle is wandering, infinite loop likely"
   end
   g.shuttle:push(basis)
end

















local BAIL_AT = 16384



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

   local regulars, ruleMap = g.regulars, g.ruleMap
   local shuttle = Deque()
   g.shuttle = shuttle
   g.count = 0
   for _, tier in ipairs(regulars) do
      for name in pairs(tier) do
         ruleMap[name]:enqueue()
      end
   end
   for name in pairs(g.recursive) do
      ruleMap[name]:enqueue()
   end
   local bail = 0
   for node in shuttle:popAll() do
      if type(node) == 'table' then
         node.on = nil
         bail = bail + 1
         node:constrain()
         if bail > BAIL_AT then
            grammar.had_to_bail = true
            grammar.no_constraint = {}
            for rule in grammar :filter 'rule' do
               if not rule.constrained then
                  grammar.no_constraint[rule.token] = rule
               end
            end
            break
         end
      else
         -- something got on the queue?
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








function Mem.rule.constrain(rule)
   local rhs = assert(rule :take 'rhs')
   assert(#rhs == 1, "bad arity on RHS")
   local body = rhs[1]
   body:constrain()
   if body.constrained then
      rule.constrained = true
      rhs.constrained = true
   else
      rule:enqueue()
   end
   for trait in pairs(CopyTrait) do
      if body[trait] then
        rule[trait] = body[trait]
      end
   end
   rule:propagateConstraints()
end

















local function copyTraits(rule, ref)
   local changed = false
   for trait in pairs(CopyTrait) do
      if rule[trait] then
         local differs = ref[trait] ~= rule[trait]
         changed = changed or differs
         ref[trait] = rule[trait]
      end
   end

   return changed
end



function Mem.rule.propagateConstraints(rule)
   if rule.references then -- could be the start rule
      for _, ref in ipairs(rule.references) do
         local changed = copyTraits(rule, ref)
         if changed then
            ref:parentRule():enqueue()
         else
            ref.constrained = true
         end
      end
   end
end










function Mem.rule.propagate(rule, prop, value)
   if rule.references then
      if value == nil then
         value = rule[prop]
      end
      for _, ref in ipairs(rule.references) do
         ref[prop] =  value
      end
   end
end






local function termConstrain(terminal)
   terminal.constrained = true
end

for class in pairs(Q.terminal) do
   Mem[class].constrain = termConstrain
end






















function Mem.cat.constrain(cat)
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

      --[[DBG]] sub.back_gate = nil
      sub:constrain()

      if not sub.constrained then
         again = true
      end

      if sub.predicate or sub.terminal then
         idx = i
         if gate then
            gate.gate = nil
         end
         if locked and gate.lock and sub.failsucceeds then
            sub.lock = true
         end
         gate = sub
         if (not locked) then
            sub.lock = true
            locked = true
         elseif not (sub.lock or sub.nullable) then
            sub.dam = true
         elseif sub.failsucceeds then
            sub.dam = true
         end
      end

      if sub.terminal then
         terminal = true
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
   if (not again) and gate then
      gate.dam = nil
      if gate.lock then
         gate.gate_lock = true
      else
         gate.gate = true
         -- look for other unfailable /terminal/ rules
         -- at-most-one unbounded gate at the end
         if not gate.unbounded then
            for i = idx-1, 1, -1 do
               local sub = cat[i]
               if (not sub.terminal) or sub.lock or sub.unbounded then
                  break
               end
               --[[DBG]] sub.back_gate = true
               sub.gate = true
               sub.dam = nil
            end
         end
      end
   elseif not again then
      locked = false -- right? lock but no gate = not locked
   end

   if locked then
      cat.locked = true
   end
end






function Mem.alt.constrain(alt)
   local constrained = true
   -- can be true for any choice
   local nofail, nullable = nil, nil
   -- must be true for all choices
   local locked, predicate, terminal = true, true, true

   for _, sub in ipairs(alt) do
      sub:constrain()
      if not sub.constrained then
         constrained = false
      end
      if sub.unbounded then
         alt.unbounded = true
      end
      terminal = terminal and sub.terminal
      locked = locked and sub.locked
      predicate = predicate and sub.predicate

      nofail = nofail or sub.nofail
      nullable = nullable or sub.nullable
   end
   alt.nofail      = nofail
   alt.nullable    = nullable
   alt.terminal    = terminal or nil
   alt.locked      = locked or nil
   alt.predicate   = predicate or nil
   alt.constrained = constrained
end













function Mem.element.constrain(element)
   -- ??
   local again
   for _, sub in ipairs(element) do
      sub:constrain()
      if sub.constrained then
         -- copy then reconcile
         for trait in pairs(CopyTrait) do
            element[trait] = element[trait] or sub[trait]
         end
         if element.nullable or element.predicate then
            element.terminal = nil
         end
      else
         again = true
      end
   end
   element.constrained = not again
end












function Mem.group.constrain(group)
   assert(#group == 1, "group has too many kids (or no kid?)")
   group[1]:constrain()
   if group[1].constrained then
      for trait in pairs(CopyTrait) do
         group[trait] = group[trait] or group[1][trait]
      end
      group.constrained = true
   end
end









function Mem.name.constrain(name)
   if not name.constrained then
      name:ruleOf():enqueue()
   end
end



function Mem.name.ruleOf(name)
   return name:G().ruleMap[name.token]
end













function Mem.repeated.constrain(repeated)
   local range = repeated :take 'integer_range'
   if not range then return end
   local start = tonumber(range[1])
   if start == 0 then
      repeated.nofail = true
      repeated.nullable = true
   end
   repeated.needs_work = true -- just a little reminder
   repeated.constrained = true
end













































function Mem.grammar.deduce(grammar)
   local g = grammar:G()
   g.constrain_count = g.count
   g.count = 0
   if not (g.start and g.start.constrained) then
      grammar:constrain()
   end
   if not g.start.constrained then
      return nil, "grammar can't be constrained"
   end
   for rule in grammar :filter 'rule' do
      rule:enqueue()
   end
   for rule in g.shuttle :popAll() do
      rule:acquireLock()
      rule:propagate 'the_lock'
   end
end






function Mem.rule.acquireLock(rule)
   local body = rule :take 'rhs' [1]
   if rule.locked then
      rule.the_lock = "rule lock!"
      if Locks[body.tag] then
         local the_lock = body:acquireLock()
         if the_lock then
            rule.the_lock = the_lock
            rule :propagate 'the_lock'
         else
            rule:enqueue()
         end
      elseif body.terminal then
         rule.the_lock = body
         rule :propagate 'the_lock'
      else
         rule.body_does_not_lock = true
      end
   end
end






function Mem.rule.bodyTag(rule)
   return rule :take 'rhs' [1] .tag
end






function Mem.name.acquireLock(name)
   if name.the_lock then
      return name.the_lock
   end
   name:ruleOf():enqueue()
end






function Mem.cat.acquireLock(cat)
   if not cat.locked then
      -- surely this is an error, since we checked: the rule is locked.
      -- but there are no guarantees in life, including a guarantee that we
      -- check the rule before calling the method, so:
      return false
   end
   local again = false
   local the_lock = { the_lock = true }
   local seen_lock = false
   for _, sub in ipairs(cat) do
      if seen_lock and (not sub.lock) then
         break
      elseif sub.the_lock then
         insert(the_lock, sub.the_lock)
         seen_lock = true
      elseif Locks[sub.tag] and (sub.lock or sub.locked) then
         local a_lock = sub:acquireLock()
         if a_lock then
            insert(the_lock, a_lock)
            seen_lock = true
         else
            again = true
         end
      elseif Q.terminal[sub.tag] then
         insert(the_lock, sub)
         seen_lock = true
      end
   end
   if again or #the_lock == 0 then
      cat:parentRule():enqueue()
      return false
   else
      cat.the_lock = the_lock
      return the_lock
   end
end









function Mem.alt.acquireLock(alt)
   return "alt lock!"
end






function Mem.element.acquireLock(element)
   local body = element[1]
   if Locks[body.tag] then
      return body:acquireLock()
   elseif body.tag == 'name' then
      if body.the_lock then
         return body.the_lock
      else
         body:ruleOf():enqueue()
         return false
      end
   elseif body.terminal then
      return element
   end
   return "element lock?"
end






function Mem.group.acquireLock(group)
   if group.lock then
      return group
   end

   local elem = group[1]
   if Locks[elem.tag] then
      return elem:acquireLock()
   elseif elem.tag == 'name' then
      if elem.the_lock then
         return elem.the_lock
      else
         elem:ruleOf():enqueue()
         return false
      end
   elseif elem.terminal then
      return elem
   end
   return "group lock?"
end





























local codegen = require "espalier:peg/codegen"

for class, mixin in pairs(codegen) do
   for trait, method in pairs(mixin) do
      Mem[class][trait] = method
   end
end




return MemClade

