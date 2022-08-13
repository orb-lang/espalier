














































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











local gsub = assert(string.gsub)

local function normalize(str)
   return gsub(str, "%-", "%_")
end








local Q = {}











Q.nofail = Set {'zero_plus', 'optional'}








Q.predicate = Set {'and', 'not'}








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




















local Twig = Node :inherit()




local function __index(metabuild, key)
   local M = Twig :inherit(key)
   metabuild[key] = M
   return metabuild[key]
end



local M = setmetatable({Twig}, {__index = __index})











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








local suppress = Set {
   'parent',
   'line',
   -- this field isn't used but I think it will be
   'final',
   'constrained',
   'peh',
   'o',
   'col',
   'up',
   'node',
}
local _lens = { hide_key = suppress,
                depth = 10 }
local Syn_repr = require "repr:lens" (_lens)

SynM.__repr = Syn_repr


















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






local function Syn_index(Syn, class)
   local meta, _ = metaSes[class]
   if not meta then
      _, meta = makeGenus(class)
      Syn[class] = meta
   end
   return meta
end

local Syn = setmetatable({Syndex}, {__index = Syn_index })









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




function Syndex.span(synth)
   return synth.node:span()
end




function Syndex.stride(synth)
   return node.last - node.first + 1
end




function Syndex.nameOf(synth)
   return synth.name or synth.class
end





function Syndex.left(syn)
   return syn.parent[syn.up + 1]
end

function Syndex.right(syn)
   return syn.parent[syn.up - 1]
end










Syndex.synthesize = cluster.ur.pass
Syndex.analyze = cluster.ur.pass














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
   return synth
end















local Prefix = Set {'and', 'not'}
local Suffix = Set {'zero_plus', 'one_plus', 'optional', 'repeat'}
local Backref = Set {'backref'}

local Surrounding = Prefix + Suffix + Backref



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
         part[mod.class] = true
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








local codegen = require "espalier:peg/codegen"

for class, mixin in pairs(codegen) do
   for trait, method in pairs(mixin) do
      Syn[class][trait] = method
   end
end









local Hoist = Set {'element', 'alt', 'cat'}



function M.grammar.hoist(grammar)
   if grammar.hoisted then return grammar end
   for i, rule in ipairs(grammar) do
      rule:hoist()
   end
   grammar.hoisted = true

   return grammar
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



function M.grammar.synthesize(grammar)
   grammar.start = grammar :take 'rule'
   local synth = _synth(grammar)
   ---[[DBG]] synth.Prop = Prop
   s:verb("synthesized %s", synth.class)
   synth.peh = grammar.peh
   grammar.synth = synth --- this is useful, ish, at least in helm
   return synth
end


















































local function nonempty(tab)
   if #tab > 0 then
      return tab
   else
      return nil
   end
end




function Syn.grammar.collectRules(grammar)
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



function Syn.grammar.callSet(grammar)
   local collection = grammar.collection or grammar:collectRules()
   return _callSet(collection.ruleCalls)
end














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








function Syn.grammar.analyze(grammar)
   grammar.collection = grammar:collectRules()
   local coll = assert(grammar.collection)

   local regulars, recursive = partition(coll.ruleCalls, grammar:callSet())
   local ruleMap = assert(coll.ruleMap)
   for name in pairs(recursive) do
      ruleMap[name].recursive = true
   end
   coll.regulars, coll.recursive = regulars, recursive
   coll.calls = graphCalls(grammar)
   if coll.missing then
      grammar:makeDummies()
   end

   -- we'll switch to using these directly
   for k, v in pairs(coll) do
      grammar[k] = v
   end


   return grammar:anomalies()
   --grammar:constrain()
end









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

















local find, gsub = string.find, string.gsub

local function dumbRule(name, pad, patt)
   return  "`" .. name .. "`  <-  DUMMY-" .. name .. "\n"
           .. "DUMMY-" .. name .. "  <-  " .. pad
           .. patt .. pad .. "\n"
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






local Peg = require "espalier:espalier/peg"

function Syn.grammar.dummyParser(grammar)
   if not grammar.collection then
      grammar:collectRules()
   end
   if not grammar.collection.missing then
      return nil, "no dummy rules"
   end
   grammar:makeDummies()
   local with_dummy = grammar.peh .. grammar.dummy_str
   -- do this with Vav
   -- return Peg(with_dummy):toGrammar()
end



















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

   for rule in grammar :filter 'rule' do
      rule:constrain(coll)
   end

   for name in grammar :filter 'name' do
      name:constrain(coll)
   end

   -- lift up regulars

   -- say sensible things about recursives
end



function Syn.rule.constrain(rule, coll)
   local rhs = assert(rule :take 'rhs')
   local body = rhs[1]
   if body.nofail then
      rhs.nofail = true
      rule.nofail = true
   end
   if body.compound then
      body:sumConstraints(coll)
      if body.locked then
         rule.locked = true
      end
   end
   rule.constrained = true
end



function Syn.name.constrain(name, coll)
   local tok = assert(name.token)
   local rule = assert(coll.ruleMap[tok])
   if rule.constrained then
      name.final = rule.final
      name.terminal = rule.terminal
      name.nofail = rule.nofail
      name.locked = rule.locked
      name.constrained = true
      name.unconstrained = nil
   else
      name.unconstrained = true
   end
end






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
      if sub.locked or (not sub.nofail) then
         idx = i
         gate = sub
      end
      if (not sub.nofail) then
         if not locked then
            assert(not sub.nofail)
            if sub.token == "_" then sub.seriously = "wtf: " .. tostring(sub.nofail) end
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



function Syn.alt.sumConstraints(choice, coll)
   local maybe = nil
   for _, sub in ipairs(choice) do
      if sub.compound then
         sub:sumConstraints(coll)
      end
      if sub.nofail then
         maybe = true
         -- for future expansion: this has to be the last rule
         -- to be meaningful under ordered choice
      end
   end
   choice.nofail = maybe
   choice.constrained = true
end






function Syn.repeated.constrain(repeated, coll)
   local range = repeated :take 'integer_range'
   if not range then return end
   local start = tonumber(range[1])
   if start == 0 then
      repeated.nofail = true
   end
   repeated.constrained = true
end
























function SynM.__add(grammar, rule)

end




return M

