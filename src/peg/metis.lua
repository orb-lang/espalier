










































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











local gsub = assert(string.gsub)

local function normalize(str)
   return gsub(str, "%-", "%_")
end








local Q = {}











Q.maybe = Set {'zero_or_more', 'optional'}






Q.compound = Set {'cat', 'choice'}








Q.terminal = Set {'literal', 'set', 'range', 'number'}




















local Twig = Node :inherit()




local function __index(metabuild, key)
   metabuild[key] = Twig :inherit(key)
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
   -- this is just for reading purposes, remove
   synth.class = _new.class
   return synth
end

cluster.construct(new, builder)







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








local function _synth(node, parent_synth, i)
   local synth = newSynth(node, i)
   synth.parent = parent_synth or synth
   for i, twig in ipairs(node) do
      synth[i] = _synth(twig, synth, i)
   end
   return synth
end



function M.rules.synthesize(rules)
   rules.start = rules :take 'rule'
   rules.synth = _synth(rules)
   return rules.synth
end











































function Syn.rules.collectRules(rules)
   local nameSet = Set {}
   for name in rules :filter 'name' do
      local token = normalize(name:span())
      name.token = token
      nameSet[token] = true
   end
   local dupe, surplus = {}, {}
   local ruleMap = {}   -- token => synth
   local ruleCalls = {} -- token => {name*}
   local ruleSet = Set {}   -- #{rule_name}
   for rule in rules :filter 'rule' do
      local token = normalize(rule :take 'rule_name' :span())
      rule.token = token
      ruleSet[token] = true
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
   return { nameSet   =  nameSet,
            ruleMap   =  ruleMap,
            ruleCalls =  ruleCalls,
            ruleSet   =  ruleSet,
            dupe      =  dupe,
            surplus   =  surplus,
            missing   =  missing, }
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



function Syn.rules.callSet(rules)
   local collection = rules.collection or rules:collectRules()
   return _callSet(collection.ruleCalls)
end














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
   local depSet = regulars[1]
   for name in pairs(depSet) do
      ruleMap[name].final = true
      regSets[name] = Set {}
   end
   -- second tier has only the already-summoned direct calls
   depSet = regulars[2]
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
         for _, name in ipairs(ruleCalls[elem]) do
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
   return regSets, recurSets, allCalls
end



function Syn.rules.analyze(rules)
   local collection = rules:collectRules()
   rules.collection = collection
   local regulars, recursive = partition(collection.ruleCalls, rules:callSet())
   local ruleMap = assert(collection.ruleMap)
   collection.regulars, collection.recursive = regulars, recursive
   for name in pairs(recursive) do
      ruleMap[name].recursive = true
   end
   local regSets, recurSets, calls = graphCalls(rules)
   collection.calls = calls
   -- sometimes we want to know what a given rule /can't/ see
   local ruleSet = collection.ruleSet
   local blind = {}
   for name, callSet in pairs(calls) do
      blind[name] = ruleSet - callSet
   end
   collection.blind = blind
   rules:constrain()
   return blind, calls
end



















































































































local function copyFlags(synA, synB)
   for k, v in pairs(synA) do
      if type(v) == 'boolean' then
         synB[k] = v
      end
   end
end



function Syn.rules.constrain(rules)
   -- now what lol
   -- well, we have the 'tiers' for the regulars, so we can start with zero
   -- dep and accumulate wisdom.
   local collection
   if rules.collection then
      collection = rules.collection
   else
      rules:analyze()
      collection = assert(rules.collection)
   end

   local ruleMap, regulars = collection.ruleMap, collection.regulars
   -- this is merely for tracking purposes
   local constraints = {} -- name => synth
   for _, workSet in ipairs(regulars) do
      for elem in pairs(workSet) do
         -- get the guts out
         local rule = assert(ruleMap[elem])
         local rhs = assert(rule :take 'rhs')
         local body = rhs[1]
         -- mayb we move this to the end
         if body.maybe then
            rhs.maybe = true
         end
         if body.compound then
            body:sumConstraints(constraints)
            if body.locked then
               rule.locked = true
            end
         end
         if body.class == 'name' then
            copyFlags(ruleMap[body.token], body)
         end

      constraints[elem] = rule
      end
   end
end






function Syn.cat.sumConstraints(cat, constraints)
   local locked = false
   for i, sub in ipairs(cat) do
      if sub.compound then
         sub:sumConstraints(constraints)
      else
         if sub.constrain then
            sub:constrain(constraints)
         else
            sub.unconstrained = true
         end
      end
      if not sub.maybe then
         if not locked then
            sub.lock = true
            locked = true
         end
         if i == #cat then
            sub.gate = true
            locked = true
         end
      end
   end
   -- we may have missed a gate
   if locked and (not cat[#cat].gate) then
      for i = #cat-1, 1, -1 do
         if not cat[i].maybe then
            cat[i].gate = true
            break
         end
      end
   end
   if locked then
      cat.locked = true
   end
end



function Syn.choice.sumConstraints(choice, constraints)
   local maybe, locked = false, true
   for _, sub in ipairs(choice) do
      if sub.compound then
         sub:sumConstraints(constraints)
      end
      if sub.maybe then
         maybe = true
      end
      if not sub.locked then
         locked = false
      end
   end
   choice.maybe, choice.locked = maybe, locked
end
























function SynM.__add(grammar, rule)

end




return M

