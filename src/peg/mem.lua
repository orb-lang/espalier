





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

function Basis.withinRule(mem)
   s:chat "use .nameOfRule"
   return mem:nameOfRule()
end








function Basis.nameOf(mem)
   return mem.name or mem.tag
end









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




function Mem.grammar.synthesize(grammar)
   grammar.start = grammar :take 'rule'
   synthesize(grammar)
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
   insert(getset(g, 'unconstrainted'), basis.tag)
end










local function queueUp(shuttle, node)
   if node.on then return end
   node.on = true
   shuttle:push(node)
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
   local seen = {}
   for _, tier in ipairs(regulars) do
      for name in pairs(tier) do
         queueUp(shuttle, ruleMap[name])
      end
   end
   for name in pairs(g.recursive) do
      queueUp(shuttle, ruleMap[name])
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








function Mem.rule.constrain(rule)
   local rhs = assert(rule :take 'rhs')
   assert(#rhs == 1, "bad arity on RHS")
   local body = rhs[1]
   body:constrain()
   if body.constrained then
      rule.constrained = true
      rhs.constrained = true
   else
      queueUp(rule:G().shuttle, rule)
   end
   for trait in pairs(CopyTrait) do
      if body[trait] then
        rule[trait] = body[trait]
      end
   end
   rule:propagateConstraints()
end








function Mem.rule.propagateConstraints(rule)
   if rule.references then -- could be the start rule
      for _, ref in ipairs(rule.references) do
         ref:constrain()
         -- this should only be necessary on change
         -- we make sure the rule is looked at again
         if ref.changed then
            local rule = ref:parentRule()
            queueUp(rule:G().shuttle, rule)
         end
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

      sub:constrain()

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
   if again then
      queueUp(cat:G().shuttle, cat)
   end
end



function Mem.alt.constrain(alt)
   local nofail, nullable = nil, nil
   local again;
   local locked = true
   local terminal = true
   for _, sub in ipairs(alt) do
      sub:constrain()
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
   if again then
      queueUp(assert(alt:G().shuttle), alt)
   end
end







function Mem.element.constrain(element)
   -- ??
   local again;
   for _, sub in ipairs(element) do
      sub:constrain()
      if sub.constrained then
         for trait in pairs(CopyTrait) do
            element[trait] = element[trait] or sub[trait]
         end
      else
         again = true
      end
   end
   if again then
      queueUp(element:G().shuttle, element)
   end
   element.constrained = not again
end



































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








local FIX_POINT = 2




function Mem.name.constrain(name)
   if name.constrained then return end
   local token = assert(name.token)
   local rule = name:G().ruleMap[token]
   local self_ref = token == name:withinRule()
   if self_ref then
      rule.self_recursive = true
      rule.unbounded = true
      if name.seen_self then
         name.seen_self = nil
      else
         name.seen_self = true
         queueUp(name:G().shuttle, rule)
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
      queueUp(name:G().shuttle, rule)
   else ---[[DBG]] --[[
      name.no_change = nil -- no longer relevant --]]
   end
end






























function Mem.repeated.constrain(repeated)
   local range = repeated :take 'integer_range'
   if not range then return end
   local start = tonumber(range[1])
   if start == 0 then
      repeated.nofail = true
      repeated.nullable = true
   end
   repeated.constrained = true
end






function Mem.group.constrain(group)
   local again = false
   for _, sub in ipairs(group) do
      sub:constrain()
      if not sub.constrained then
         again = true
      end
   end
   if not again then
      group.constrained = true
   end
end



























local codegen = require "espalier:peg/codegen"

for class, mixin in pairs(codegen) do
   for trait, method in pairs(mixin) do
      Mem[class][trait] = method
   end
end




return MemClade

