# Peg Middleware

Extensions of the Peg metatables\.

```lua
local core = require "qor:core"
```

```lua
local Peg_M = require "espalier:espalier/pegmeta"
```


### Specializing the Metatables

This needs to be informed by cluster\.  ¯\\\\\_\(ツ\)\_/¯\.

For now, to get the effect I want, I'm going to make a global\.

```lua
local P_ENV = setmetatable({}, { __index = getfenv(1) })

setfenv(1, P_ENV)
assert(getmetatable) -- sanity check
```

```lua
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
```


## Peg Middleware extension

We need to inject a base implementation of `powerLevel`, which will probably
not be the only base, so rather than refactor when I add a second, we'll put
it in a `_Peg` base table\.


```lua
local _Peg = {}
```


###  \_Peg:powerLevel\(\)

This needs specific implementation, but there is a sensible default behavior\.


#### Power level constants

We return a number as the main value for a power level, followed by the name
as a string\.

`BOUNDED` could use explanation, this is anything in a regular family which
has a **defined maximum extent**, a useful subset of regulars where reasoning
about the state of the parse is concerned\.

```lua
local LITERAL, BOUNDED, REGULAR, RECURSIVE = 0, 1, 2, 3

local NO_LEVEL = -1 -- comment and indentation type rules
```

The corresponding strings we will provide directly when we have them\.  When
deducing them from other rules, this array will be useful:

```lua
local POWER = { 'bounded', 'regular', 'recursive',
                [0] ='literal',
                [-1] = 'no_level',
                [-2] = 'ERROR_NO_LEVEL_ASSIGNED' }
```



#### Power level basic methods

All primitive combinators return based on category alone, we define those
here:

```lua
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
```

Recursive rules \(and those with cat, group, and ordered choice\) require
knowledge about the subrules, which ultimately they derive from these three\.


#### "Peg" base

This rule applies correctly to e\.g\. `cat` and is a suitable base for this
reason\.

I argue that the use of `-2` is defensible here, as simplifying the logic
relative to beginning with `nil`\.

```lua
function _Peg.powerLevel(peg)
   local pow = -2
   for _, twig in ipairs(peg) do
      local level = twig:powerLevel()
      pow = (tonumber(level) > tonumber(pow)) and level or pow
   end
   return pow, POWER[pow]
end
```


#### Base Method Injection

Again, the need for a proper MOP is acute\.

```lua
for var, val in pairs(P_ENV) do
   for k, v in pairs(_Peg) do
      val[k] = v
   end
end
```


## Rules

So we come to the actual extension\.


### Rules:powerMap\(\)

A blunt instrument for exporting the power level analyses\.

```lua
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
```

### Rules:analyse\(\)

  Perform recursive rule analysis, attaching the result as a `.analysis`
field on the Rules Node, returning the result as well\.

```lua
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
```


### Rule:powerLevel\(\)

  The power level of a rule is the power level of the right hand side of the
rule\.

```lua
function Rule.powerLevel(rule)
   return rule :select 'rhs' () :powerLevel()
end
```


```lua
Range.powerLevel = _bounded
```


```lua
Zero_or_more.powerLevel = _regular
```

```lua
One_or_more.powerLevel = _regular
```

```lua
Comment.powerLevel = _no_level
```

```lua
Number.powerLevel = _literal
```

```lua
Dent.powerLevel = _no_level
```

```lua
Whitespace.powerLevel = _no_level
```


```lua
function Named.powerLevel(named)
   return named[1]:powerLevel()
end
```


#### Set:powerLevel\(\)

```lua
Set.powerLevel = _bounded
```

### Literal:powerLevel\(\)

The most basic, almost tautological, building block for power level analysis\.

```lua
Literal.powerLevel = _literal
```



### Return as metas collection

To complete the other slice of bread in this sandwich, we need something which
looks like PegM:

```lua
local PegMiddle = {}

for k, v in pairs(P_ENV) do
   PegMiddle[v.id] = v
end
```

```lua
return PegMiddle
```


