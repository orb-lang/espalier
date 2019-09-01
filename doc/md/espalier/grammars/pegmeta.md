# PEG metatables


A collection of Node-descended metatables to provide sundry methodologies.


```lua
local Node = require "espalier/node"
local core = require "singletons/core"
local Phrase = require "singletons/phrase"

local inherit = assert(core.inherit)
local insert, remove, concat = assert(table.insert),
                               assert(table.remove),
                               assert(table.concat)
local s = require "singletons/status" ()
```
### Peg base class

```lua
local Peg, peg = Node : inherit()
Peg.id = "peg"
```
### Peg:toSexpr()

```lua
local nl_map = { rule = true }
local function _toSexpr(peg, depth)
   depth = depth or 0
   local sexpr_line = { (" "):rep(depth), "(" } -- Phrase?
   local name = peg.name or peg.id
   insert(sexpr_line, name)
   insert(sexpr_line, " ")
   for _, sub_peg in ipairs(peg) do
      local _toS = sub_peg.toSexpr or _toSexpr
      insert(sexpr_line, _toS(sub_peg, depth + 1))
      insert(sexpr_line, " ")
   end
   remove(sexpr_line)
   insert(sexpr_line, ")")
   if nl_map[name] then
      insert(sexpr_line, "\n")
   end

   return concat(sexpr_line)
end

Peg.toSexpr = _toSexpr
```
### Peg:toSexprRepr()

A bit ugly perhaps, but this will let us view the sexprs as more than a
mere string.


I will most likely elaborate this past the useful point, in the pursuit of
happiness.

```lua
local function __repr(repr, phrase, c)
   return _toSexpr(repr[1])
end

local ReprMeta = { __repr = __repr,
                   __tostring = __repr }
ReprMeta.__index = ReprMeta

local function newRepr(peg)
   local repr = setmetatable({}, ReprMeta)
   repr[1] = peg
   return repr
end
```
```lua
function Peg.toSexprRepr(peg)
   return newRepr(peg)
end
```
## Peg.toLpeg(peg)

This needs to be implemented by each subclass, individually, so we produce a
base method that halts if we fall back to it.

```lua
function Peg.toLpeg(peg)
   s:halt "each grammar class must implement toLpeg"
end
```
## PegMetas

```lua
local PegMetas = Peg : inherit()
PegMetas.id = "pegMetas"
```
### PegPhrase class

We'll want to decorate our phrases with various REPRy enhancements, so let's
pull a fresh metatable:

```lua
local PegPhrase = Phrase() : inherit ()
```
### Rules

```lua
local Rules = PegMetas : inherit()
Rules.id = "rules"

function Rules.toLpeg(peg_rules, depth)
   depth = depth or 0 -- for consistency
   -- _preProcessAST(peg_rules)
   local phrase = PegPhrase()
   -- the first rule should have an atom:
   -- peg_rules[1]   -- this is the first rule
   -- peg_rules[1]:select "rhs" : select "atom" . val
   -- maybe?
   local grammar_name = peg_rules : select "rule" ()
                         : select "pattern" ()
                         : span()
   phrase = phrase .. "local functionn _" .. grammar_name .. "_fn(_ENV)\n"
   phrase = phrase .. "   " .. "START " .. "\"" .. grammar_name .. "\"\n"
   -- Build the SUPPRESS function here, this requires finding the
   -- hidden rules and suppressing them
   --
   -- stick everything else in here...
   ---[[
   for rule in peg_rules : select "rule" do
      phrase = phrase .. rule:toLpeg(depth + 1)
   end
   --]]
   phrase = phrase .. "\nend\n"
   return phrase
end
```
```lua
local Rule = PegMetas : inherit()
Rule.id = "rule"

function Rule.toLpeg(rule, depth)
   depth = depth or 0
   local phrase = PegPhrase(("   "):rep(depth))
   local lhs = rule:select "pattern" () : span()
   phrase = phrase .. lhs .. " = "
   local rhs = rule:select "rhs" () : span () -- toLpeg()
   return phrase .. rhs .. "\n"
end
```
```lua
local Rhs = PegMetas : inherit()
Rhs.id = "rhs"
```
```lua
local Choice = PegMetas : inherit()
Choice.id = "choice"

function Choice.toLpeg(choice, depth)
   local phrase = PegPhrase "+"
   for _, sub_choice in ipairs(choice) do
      phrase = phrase .. " " .. sub_choice:toLpeg(depth + 1)
   end
   return phrase
end
```
```lua
local Comment = PegMetas : inherit()
Comment.id = "comment"

function Comment.toSexpr(comment, depth)
   return ""
end
```
```lua
return { rules = Rules,
         rule  = Rule,
         rhs   = Rhs,
         comment = Comment,
         choice = Choice }
```
