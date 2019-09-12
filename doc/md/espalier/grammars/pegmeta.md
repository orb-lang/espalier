# PEG metatables


A collection of Node-descended metatables to provide sundry methodologies.


## Status

This module currently covers enough ground to start co-developing PEG grammars
in a declarative style.


- [ ] #Todo


  - [ ]  Assemble ``toLpeg`` methods for the remaining classes.


  - [ ]  Add a PEG syntax highlighter to the [[=orb/etc= directory]
         [codex://orb:orb/etc/]].


  - [ ]  Add a ``toHmtl`` method set that's roughly pygments-compatible.


         This should actually emit a Node of ``id`` ``html``, capable of emitting
         a Phrase as well as a string.

```lua
local Node = require "espalier/node"
local Grammar = require "espalier/grammar"
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
local a = require "singletons/anterm"
function Peg.toLpeg(peg)
   return a.red(peg:span())
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

``rules`` is our base class, and we manually iterate through the AST to
generate passable Lua code.


It won't be pretty, but it will be valid.  Eventually.

```lua
local Rules = PegMetas : inherit "rules"
```
#### _PREFACE

```lua
local _PREFACE = PegPhrase ([[
local L = assert(require "lpeg")
local P, V, S, R = L.P, L.V, L.S, L.R
]])
```
```lua
local insert = assert(table.insert)

local function _suppressHiddens(peg_rules)
   local hiddens = {}
   for hidden_patt in peg_rules : select "hidden_pattern" do
      insert(hiddens, hidden_patt:span():sub(2,-2))
   end
   if #hiddens == 0 then
      -- no hidden patterns
      return nil
   end
   local phrase = PegPhrase "   " .. "SUPPRESS" .. " " .. "("
   for i, patt in ipairs(hiddens) do
      phrase = phrase .. "\"" .. patt .. "\""
       if i < #hiddens then
          phrase = phrase .. "," .. " "
       end
   end
   return phrase .. ")" .. "\n"
end

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
   local grammar_fn  = "_" .. grammar_name .."_fn"
   phrase = phrase .. "local function " .. grammar_fn .. "(_ENV)\n"
   phrase = phrase .. "   " .. "START " .. "\"" .. grammar_name .. "\"\n"
   -- Build the SUPPRESS function here, this requires finding the
   -- hidden rules and suppressing them
   local suppress = _suppressHiddens(peg_rules)
   if suppress then
      phrase = phrase .. suppress
   end
   --
   -- stick everything else in here...
   ---[[
   for rule in peg_rules : select "rule" do
      phrase = phrase .. rule:toLpeg(depth + 1)
   end
   --]]
   phrase = phrase .. "\nend\n"
   local appendix = PegPhrase "return " .. grammar_fn .. "\n"
   return _PREFACE .. phrase .. appendix
end
```
#### Rules:toGrammar()

```lua
function Rules.toGrammar(rules, metas, pre, post)
   return Grammar(rules:toLpeg(), metas, pre, post)
end
```
### Rule

```lua
local Rule = PegMetas : inherit "rule"

local function _pattToString(patt)
   local is_hidden = patt : select "hidden_pattern" ()
   if is_hidden then
      return is_hidden:span():sub(2, -2)
   else
      return patt:span()
   end
end

function Rule.toLpeg(rule, depth)
   depth = depth or 0
   local phrase = PegPhrase(("   "):rep(depth))
   for commentary in rule : select "lead_comment" do
      phrase = phrase .. "--" .. " "
             .. commentary : select "comment" ()
             : span()
             : sub(2)
             .. "\n"
             .. ("   "):rep(depth)
   end

   local patt = rule:select "pattern" ()
   phrase = phrase .. _pattToString(patt) .. " = "
   local rhs = rule:select "rhs" () : toLpeg (depth)
   return phrase .. rhs .. "\n"
end
```
#### lhs, pattern, hidden_pattern

These are all handled internally by Rule, so they don't require
their own lpeg transducers.


These should be inherited with proper PascalCaps in the event we write, for
example, a toHtml method.


### Rhs

```lua
local Rhs = PegMetas : inherit "rhs"

function Rhs.toLpeg(rhs, depth)
   local phrase = PegPhrase()
   for _, twig in ipairs(rhs) do
      phrase = phrase .. " " .. twig:toLpeg(depth + 1)
   end
   return phrase
end
```
### Choice

```lua
local Choice = PegMetas : inherit "choice"

function Choice.toLpeg(choice, depth)
   local phrase = PegPhrase "+"
   for _, sub_choice in ipairs(choice) do
      phrase = phrase .. " " .. sub_choice:toLpeg(depth + 1)
   end
   return phrase
end
```
### Cat

```lua
local Cat = PegMetas : inherit "cat"

function Cat.toLpeg(cat, depth)
   local phrase = PegPhrase " * "
   for _, sub_cat in ipairs(cat) do
      phrase = phrase .. " " .. sub_cat:toLpeg(depth)
   end
   return phrase
end
```
### Group

```lua
local Group = PegMetas : inherit "group"

function Group.toLpeg(group, depth)
   local phrase = PegPhrase "("
   for _, sub_group in ipairs(group) do
      phrase = phrase .. " " .. sub_group:toLpeg(depth)
   end
   return phrase .. ")"
end
```
#### HiddenMatch

This should be implemented if and only if I can get the Drop rule working
correctly. Now, you'd **think** I could manage this, but it isn't a priority
right now.


```lua
local IfNotThis = PegMetas : inherit "if_not_this"

function IfNotThis.toLpeg(if_not, depth)
   local phrase = PegPhrase "-("
   for _, sub_if_not in ipairs(if_not) do
      phrase = phrase .. sub_if_not:toLpeg()
   end
   return phrase .. ")"
end
```
```lua
local NotThis = PegMetas : inherit "not_this"
```
```lua
local IfAndThis = PegMetas : inherit "if_and_this"
```
```lua
-- #todo am I going to use this? what is its semantics? -Sam.
local Capture = PegMetas : inherit "capture"
```
### Literal

This offers an exact match of a substring.

```lua
local Literal = PegMetas : inherit "literal"

function Literal.toLpeg(literal, depth)
   return PegPhrase "P" .. literal:span()
end
```
### Set

```lua
local Set = PegMetas : inherit "set"

function Set.toLpeg(set, depth)
   return PegPhrase "S\"" .. set:span():sub(2,-2) .. "\""
end
```
#### Range

The ``range`` class needs a semantic change since there's no percentage in
having ``-`` as a separator, it's noisy.

```lua
local Range = PegMetas : inherit "range"
```
```lua
function Range.toLpeg(range, depth)
   local phrase = PegPhrase "R\""
   phrase = phrase .. range : select "range_start" () : span()
   return phrase .. range : select "range_end" () : span() .. "\" "
end
```
### Optional

```lua
local Optional = PegMetas : inherit "optional"

function Optional.toLpeg(optional, depth)
   local phrase = PegPhrase()
   for _, sub_option in ipairs(optional) do
      phrase = phrase .. " " .. sub_option:toLpeg(depth)
   end
   return phrase .. "^0"
end
```
### MoreThanOne

```lua
local MoreThanOne = PegMetas : inherit "more_than_one"

function MoreThanOne.toLpeg(more_than_one, depth)
   local phrase = PegPhrase()
   for _, sub_more in ipairs(more_than_one) do
      phrase = phrase .. " " .. sub_more:toLpeg(depth + 1)
   end
   return phrase .. "^1"
end
```
### Maybe

```lua
local Maybe = PegMetas : inherit "maybe"

function Maybe.toLpeg(maybe, depth)
   local phrase = PegPhrase()
   for _, sub_maybe in ipairs(maybe) do
      phrase = phrase .. " " .. sub_maybe:toLpeg(depth + 1)
   end
   return phrase .. "^-1"
end
```
### SomeNumber

An exact number of matches.


The simple way to express this is: ``(patt * patt * patt)``.


SomeNumber has a set of allowable patterns, and a number parameter; the
pattern is always at the ``[1]`` index, and the number is always called
``"repeats"``, so we use a select for the latter and index to get the former.

```lua
local SomeNumber = PegMetas : inherit "some_number"

function SomeNumber.toLpeg(some_num, depth)
   local phrase = PegPhrase "("
   local reps =  some_num : select "repeats" ()
   if not reps then
      s : halt "no repeats in SomeNumber"
   else
      -- make reps a number, our grammar should guarantee this
      -- succeeds.
      reps = tonumber(reps:span())
   end

   local patt = some_num[1]:toLpeg(depth)
   if not patt then s : halt "no pattern in some_number" end

   for i = 1, reps do
      phrase = phrase .. patt
      if i < reps then
         phrase = phrase .. " * "
      end
   end

   return phrase .. ")"
end
```
```lua
local Comment = PegMetas : inherit "comment"

function Comment.toSexpr(comment, depth)
   return ""
end

function Comment.toLpeg(comment, depth)
   local phrase = PegPhrase "--"
   return phrase .. comment:span():sub(2) .. "\n"
end
```
### Atom

This is grammatically different from pattern only by virtue of being on the
right hand side.


This is convenient, since it translates differently into lpeg.

```lua
local Atom = PegMetas : inherit "atom"

function Atom.toLpeg(atom, depth)
   local phrase = PegPhrase "V"
   phrase = phrase .. "\"" .. atom:span() .. "\""
   return phrase
end
```
```lua
return { rules = Rules,
         rule  = Rule,
         rhs   = Rhs,
         comment = Comment,
         choice = Choice,
         cat     = Cat,
         group   = Group,
         atom    = Atom,
         set     = Set,
         range   = Range,
         literal = Literal,
         optional = Optional,
         more_than_one = MoreThanOne,
         if_not_this = IfNotThis,
         if_and_this = IfAndThis,
         not_this     = NotThis,
         capture     = Capture,
         maybe   = Maybe,
         some_number = SomeNumber }
```
