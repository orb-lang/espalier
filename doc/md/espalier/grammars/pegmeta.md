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
local function _toSexpr(peg)
   depth = depth or 0
   local sexpr_line = { (" "):rep(depth), "(" } -- Phrase?
   local name = peg.name or peg.id
   insert(sexpr_line, name)
   insert(sexpr_line, " ")
   for _, sub_peg in ipairs(peg) do
      local _toS = sub_peg.toSexpr or _toSexpr
      insert(sexpr_line, _toS(sub_peg))
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
base method that highlights the span in red.  This makes it stick out, and
will produce an error if we attempt to compile it.

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

  We might want to decorate our phrases with various REPRy enhancements, so
let's pull a fresh metatable:

```lua
local PegPhrase = Phrase() : inherit ()
```
### PegPhrase.__repr(peg_phrase)

```lua
function PegPhrase.__repr(peg_phrase)
   return tostring(peg_phrase)
end
```
### Rules

``rules`` is our base class, and we manually iterate through the AST to
generate passable Lua code.


It's not pretty, but it's valid.  At least, so far; PRs welcome.

```lua
local Rules = PegMetas : inherit "rules"
```
#### Rules.__call(rules, str)

We allow the Peg root node to be callable as a Grammar.

```lua
function Rules.__call(rules, str, start, finish)
   if not rules.parse then
      rules.parse, rules.grammar = Grammar(rules:toLpeg())
   end
   return rules.parse(str, start, finish)
end
```
### Rules:toLpeg(extraLpeg)

Converts declarative Peg rules into a string of Lua code implementing a
Grammar function.


``extraLpeg`` is an optional string appended to the generated string before the
final ``end``, to inject rules which aren't expressible using the subset of
``lpeg`` which the Peg module supports.


#### _PREFACE

```lua
local _PREFACE = PegPhrase ([[
local L = assert(require "lpeg")
local P, V, S, R = L.P, L.V, L.S, L.R
local C, Cg, Cb, Cmt = L.C, L.Cg, L.Cb, L.Cmt
]])
```
#### _normalize

Causes any ``-`` in a pattern or atom to become ``_``.

```lua
local function _normalize(str)
   return str:gsub("%-", "%_")
end
```
```lua
local insert = assert(table.insert)

local function _suppressHiddens(peg_rules)
   local hiddens = {}
   for hidden_patt in peg_rules : select "hidden_pattern" do
      local normal = _normalize(hidden_patt:span():sub(2,-2))
      insert(hiddens, normal)
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

function Rules.toLpeg(peg_rules, extraLpeg)
   local phrase = PegPhrase()
   extraLpeg = extraLpeg or ""
   -- the first rule should have an atom:
   -- peg_rules[1]   -- this is the first rule
   local grammar_name = peg_rules : select "rule" ()
                         : select "pattern" ()
                         : span()
   grammar_name = _normalize(grammar_name)
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
      phrase = phrase .. rule:toLpeg()
   end
   --]]
   phrase = phrase .. extraLpeg
   phrase = phrase .. "\nend\n"
   local appendix = PegPhrase "return " .. grammar_fn .. "\n"
   return _PREFACE .. phrase .. appendix
end
```
#### Rules:toGrammar(metas, extraLpeg, header, pre, post)

  Builds a Grammar out of a parsed Peg set. All non-self parameters are
optional.


- Params:


  - metas:  Metatables for function behavior (this module is an example of
            this parameter).


  - extraLpeg:  String inserted after generated rules and before the final
                ``end`` of the function.


  - header:  String inserted before the beginning of the generated
             function.


             This and ``extraLpeg`` must be valid Lua chunks.


  - pre:  A function operating on the string to be parsed before the grammar
          is Matched.  Expected to return a string.


  - post:  A function operating on the Nodes returned by the match, before the
           AST is returned. Expected to return an AST, but whatever it returns
           will be passed on by the Grammar.


The resulting Grammar is stored as ``rules.grammar`` and can be invoked with the
corresponding ``__call`` metamethod.  ``toGrammar`` will overwrite these if they
have been created already, since the other parameters can be changed.

```lua
function Rules.toGrammar(rules, metas, extraLpeg, header, pre, post)
   metas = metas or {}
   header = header or ""
   local rule_str = rules:toLpeg(extraLpeg)
   rule_str = header .. rule_str
   rules.parse, rules.grammar = Grammar(rule_str, metas, pre, post)
   return rules.parse
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

function Rule.toLpeg(rule)
   local phrase = PegPhrase ""
   for commentary in rule : select "lead_comment" do
      phrase = phrase .. "--" .. " "
             .. commentary : select "comment" ()
             : span()
             : sub(2)
             .. "\n"
             .. "   "
   end

   local patt = _normalize(_pattToString(rule:select "pattern" ()))
   phrase = phrase .. patt .. " = "
   local rhs = rule:select "rhs" () : toLpeg ()
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

function Rhs.toLpeg(rhs)
   local phrase = PegPhrase()
   for _, twig in ipairs(rhs) do
      phrase = phrase .. " " .. twig:toLpeg()
   end
   return phrase
end
```
### Choice

```lua
local Choice = PegMetas : inherit "choice"

function Choice.toLpeg(choice)
   local phrase = PegPhrase "+"
   for _, sub_choice in ipairs(choice) do
      phrase = phrase .. " " .. sub_choice:toLpeg()
   end
   return phrase
end
```
### Cat

```lua
local Cat = PegMetas : inherit "cat"

function Cat.toLpeg(cat)
   local phrase = PegPhrase " * "
   for _, sub_cat in ipairs(cat) do
      -- hmm this is a hack
      if sub_cat.id == "not_this" then
         phrase = PegPhrase " "
      end
      phrase = phrase .. " " .. sub_cat:toLpeg()
   end
   return phrase
end
```
### Group

```lua
local Group = PegMetas : inherit "group"

function Group.toLpeg(group)
   local phrase = PegPhrase "("
   for _, sub_group in ipairs(group) do
      phrase = phrase .. " " .. sub_group:toLpeg()
   end
   return phrase .. ")"
end
```
#### HiddenMatch

This should be implemented if and only if I can get the Drop rule working
correctly. Now, you'd **think** I could manage this, but it isn't a priority
right now.


### NotThis

```lua
local NotThis = PegMetas : inherit "not_this"

function NotThis.toLpeg(not_this)
  local phrase = PegPhrase "-"
  for _, sub_not in ipairs(not_this) do
    phrase = phrase .. " " .. sub_not:toLpeg()
  end
  return phrase
end
```
### Not_predicate

```lua
local Not_predicate = PegMetas : inherit "not_predicate"

function Not_predicate.toLpeg(not_pred)
   local phrase = PegPhrase "-("
   for _, sub_not_pred in ipairs(not_pred) do
      phrase = phrase .. sub_not_pred:toLpeg()
   end
   return phrase .. ")"
end
```
### And_predicate

Equivalent of ``#rule`` in Lpeg.

```lua
local And_predicate = PegMetas : inherit "and_predicate"

function And_predicate.toLpeg(and_predicate)
   local phrase = PegPhrase "#"
   for _, sub_and_predicate in ipairs(and_predicate) do
      phrase = phrase .. " " .. sub_and_predicate:toLpeg()
   end
   return phrase
end
```
```lua
-- #todo am I going to use this? what is its semantics? -Sam.
local Capture = PegMetas : inherit "capture"
```
### Literal

This offers an exact match of a substring.

```lua
local Literal = PegMetas : inherit "literal"

function Literal.toLpeg(literal)
   return PegPhrase "P" .. literal:span()
end
```
### Set

```lua
local Set = PegMetas : inherit "set"

function Set.toLpeg(set)
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
function Range.toLpeg(range)
   local phrase = PegPhrase "R\""
   phrase = phrase .. range : select "range_start" () : span()
   return phrase .. range : select "range_end" () : span() .. "\" "
end
```
### Zero_or_more

```lua
local Zero_or_more = PegMetas : inherit "zero_or_more"

function Zero_or_more.toLpeg(zero_or_more)
   local phrase = PegPhrase()
   for _, sub_zero in ipairs(zero_or_more) do
      phrase = phrase .. " " .. sub_zero:toLpeg()
   end
   return phrase .. "^0"
end
```
### One_or_more

```lua
local One_or_more = PegMetas : inherit "one_or_more"

function One_or_more.toLpeg(one_or_more)
   local phrase = PegPhrase()
   for _, sub_more in ipairs(one_or_more) do
      phrase = phrase .. " " .. sub_more:toLpeg()
   end
   return phrase .. "^1"
end
```
### Optional

```lua
local Optional = PegMetas : inherit "optional"

function Optional.toLpeg(optional)
   local phrase = PegPhrase()
   for _, sub_optional in ipairs(optional) do
      phrase = phrase .. " " .. sub_optional:toLpeg()
   end
   return phrase .. "^-1"
end
```
### Repeated

This class covers two superficially similar casess with rather different
implementation.


The simpler case is a numeric repeat: this simply matches the suffixed pattern
an exact number of times.

```lua
local Repeated = PegMetas : inherit "repeated"

function Repeated.toLpeg(repeated)
   local phrase = PegPhrase ""
   local condition = repeated[1]:toLpeg():intern()
   if repeated[2].id == "number_repeat" then
      local times = repeated[2]:span()
      -- match at least times - 1 and no more than times
      phrase = phrase .. "#" .. condition .. "^" .. times
               .. " * " .. condition .. "^-" .. times
   else
      -- handle named repeats and (back) references here
      if repeated[2].id == "named_repeat" then
        -- make a capture group
        phrase = phrase .. "Cg(" .. condition .. ",'" .. repeated[2]:span()
                 .. PegPhrase "')"
      elseif repeated[2].id == "reference" then
        -- make a back reference with equality comparison
        phrase = phrase .. "Cmt(C(" .. condition
                 .. ") * Cb('" .. repeated[2]:span()
                 .. PegPhrase"'),function (s, i, a, b) return a == b end)"
      end
   end
   return phrase
end
```
```lua
local Comment = PegMetas : inherit "comment"

function Comment.toSexpr(comment)
   return ""
end

function Comment.toLpeg(comment)
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

function Atom.toLpeg(atom)
   local phrase = PegPhrase "V"
   phrase = phrase .. "\"" .. _normalize(atom:span()) .. "\""
   return phrase
end
```
### Number

```lua
local Number = PegMetas : inherit "number"

function Number.toLpeg(number)
   local phrase = PegPhrase "P("
   return phrase .. number:span() .. ")"
end
```
### Whitespace

```lua
local Whitespace = PegMetas : inherit "WS"

function Whitespace.toLpeg(whitespace)
   return PegPhrase(whitespace:span())
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
         number  = Number,
         set     = Set,
         range   = Range,
         literal = Literal,
         zero_or_more = Zero_or_more,
         one_or_more = One_or_more,
         not_this  = NotThis,
         not_predicate = Not_predicate,
         and_predicate = And_predicate,
         not_this     = NotThis,
         capture     = Capture,
         optional   = Optional,
         repeated   = Repeated,
         WS      = Whitespace }
```
