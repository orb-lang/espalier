




local core = require "qor:core"



local Peg_M = require "espalier:espalier/pegmeta"










local P_ENV = setmetatable({}, { __index = getfenv(1) })

setfenv(1, P_ENV)
assert(getmetatable) -- sanity check



local upper = assert(string.upper)

for name, category in pairs(Peg_M) do
  if name == 'WS' then
     -- special case... meh
     P_ENV.Whitespace = category:inherit(category.id)
  elseif type(name) == 'string' then
     local up_name = upper(name:sub(1,1)) .. name:sub(2)
     P_ENV[up_name] = category:inherit(category.id)
  end
  -- no action for [1] which we are about to inherit and call Peg
end
-- another sanity check
assert(Rules)











local _Peg = {}


















local LITERAL, BOUNDED, REGULAR, RECURSIVE = 0, 1, 2, 3

local NO_LEVEL = -1 -- comment and indentation type rules






local POWER = { 'bounded', 'regular', 'recursive',
                [0] ='literal',
                [-1] = 'no_level',
                [-2] = 'ERROR_NO_LEVEL_ASSIGNED' }










local function _literal(combi)
   return LITERAL, 'literal'
end

local function _bounded(combi)
   return BOUNDED, 'bounded'
end

local function _regular(combi)
   return REGULAR, 'regular'
end

local function _no_level(combi)
   return NO_LEVEL, 'no_level'
end















function _Peg.powerLevel(peg)
   local pow = -2
   for _, twig in ipairs(peg) do
      local level = twig:powerLevel()
      pow = (tonumber(level) > tonumber(pow)) and level or pow
   end
   return pow, POWER[pow]
end








for var, val in pairs(P_ENV) do
   for k, v in pairs(_Peg) do
      val[k] = v
   end
end













function Rules.powerMap(rules, map)
   map = map or {}
   local nyi_map = {}
   local this_map = {}
   this_map[1], this_map[2], this_map[3] = rules.id, rules:powerLevel()
   insert(map, this_map)
   for _, twig in ipairs(rules) do
      local kids, bad_kids =  twig:powerMap()
      for __, v in ipairs(kids) do
         if v[2] == 'NaN' then
            insert(nyi_map, v)
         else
            insert(map, v)
         end
      end
      for __, v in ipairs(bad_kids) do
         insert(nyi_map, v)
      end
   end
   return map, nyi_map
end








local compact = assert(core.table.compact)

local function _atomsIn(rule)
   local names = {}
   for atom in rule :select 'rhs'() :select 'atom' do
      insert(names, _normalize(atom:span()))
   end
   -- deduplicate
   local seen, top = {}, #names
   for i, sym in ipairs(names) do
      if seen[sym] then
         names[i] = nil
      end
      seen[sym] = true
   end
   compact(names, top)
   return names
end

function Rules.analyse(rules)
   local analysis = {}
   rules.analysis = analysis
   local name_to_symbols = {}
   local name_to_rule = {}
   analysis.symbols = name_to_symbols
   analysis.rules = name_to_rule

   -- map rules to the rules needed to match them
   local start_rule = rules :select 'rule' ()
   local start_name = start_rule:ruleName()
   local names_called = _atomsIn(start_rule)
   name_to_symbols[start_name] = names_called
   name_to_rule[start_name] = start_rule
   name_to_rule[1] = start_rule
   for rule in rules :select 'rule' do
      if rule ~= start_rule then
         local name = rule:ruleName()
         local names_called = _atomsIn(rule)
         name_to_symbols[name] = names_called
         name_to_rule[name] = rule
      end
   end
   local name_to_power = {}
   analysis.powers = name_to_power

   -- get power levels for base rules
   for name, symbols in pairs(name_to_symbols) do
      if #symbols == 0 then
         name_to_power[name] = name_to_rule[name]:powerLevel()
      end
   end

   return analysis.powers
end

Rules.analyze = Rules.analyse -- i18nftw









function Rule.powerLevel(rule)
   return rule :select 'rhs' () :powerLevel()
end




Range.powerLevel = _bounded




Zero_or_more.powerLevel = _regular



One_or_more.powerLevel = _regular



Comment.powerLevel = _no_level



Number.powerLevel = _literal



Dent.powerLevel = _no_level



Whitespace.powerLevel = _no_level




function Named.powerLevel(named)
   return named[1]:powerLevel()
end






Set.powerLevel = _bounded







Literal.powerLevel = _literal










local PegMiddle = {}

for k, v in pairs(P_ENV) do
   PegMiddle[v.id] = v
end



return PegMiddle

