















local Node = require "espalier:espalier/node"
local Grammar = require "espalier:espalier/grammar"
local Seer   = require "espalier:espalier/recognize"
local Phrase = require "singletons/phrase"
local core = require "qor:core" -- #todo another qor
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








function M.rules.synthesize(rules)
   rules.start = rules :take 'rule'
end






local getset = assert(table.getset)

function M.rules.collectRules(rules)
   local references, nameSet = {}, Set {}
   for name in rules :select 'name' do
      local token = normalize(name:span())
      insert(references, name)
      nameSet[token] = true
   end
   local dupe, surplus = {}, {}
   local ruleMap = {} -- token => node
   local ruleSet = Set {}
   for rule in rules :select 'rule' do
      local token = normalize(rule :take 'rule_name' :span())
      ruleSet[token] = true
      if ruleMap[token] then
         -- lpeg uses the *last* rule defined so we do likewise
         insert(dupe, ruleMap[token])
      end
      ruleMap[token] = rule
      if not nameSet[token] then
         insert(surplus, rule)
      end
   end
   local missing = {}
   for name in pairs(nameSet) do
      if not ruleSet[name] then
         insert(missing, name)
      end
   end
   return { --references = references,
            nameSet = nameSet,
            dupe = dupe,
            ruleSet = ruleSet,
            surplus = surplus,
            missing = missing, }
end



function M.rules.analyze(rules)

end




































return M

