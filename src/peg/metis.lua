















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










local gsub = assert(string.gsub)

local function normalize(str)
   return gsub(str, "%-", "%_")
end








local Q = {}




















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




function Syndex.span(synth)
   return synth.node:span()
end




function Syndex.nameOf(synth)
   return synth.name or synth.class
end






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
   return { nameSet = nameSet,
            ruleMap = ruleMap,
            ruleCalls = ruleCalls,
            dupe = dupe,
            surplus = surplus,
            missing = missing, }
end



function M.rules.analyze(rules)

end




































return M

