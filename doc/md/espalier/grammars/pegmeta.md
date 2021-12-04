# PEG metatables


A collection of Node\-descended metatables to provide sundry methodologies\.


## Status

This module currently covers enough ground to start co\-developing PEG grammars
in a declarative style\.


- [ ] \#Todo

  - [ ]  Assemble `toLpeg` methods for the remaining classes\.

  - [ ]  Add a PEG syntax highlighter to the [=orb/etc= directory](codex://orb:orb/etc/)\.

  - [ ]  Add a `toHmtl` method set that's roughly pygments\-compatible\.

      This should actually emit a Node of `id` `html`, capable of emitting
      a Phrase as well as a string\.

```lua
local Node = require "espalier/node"
local Grammar = require "espalier/grammar"
local Phrase = require "singletons/phrase"

local insert, remove, concat = assert(table.insert),
                               assert(table.remove),
                               assert(table.concat)
local s = require "status:status" ()
```


#### Optional Lex Lua\_thor

```lua
local ok, lex = pcall(require, "helm:helm/lex")
if not ok then
   lex = function(repr, window, c) return tostring(repr) end
else
   local lua_thor = lex.lua_thor
   lex = function(repr, window, c)
            local toks = lua_thor(tostring(repr))
            for i, tok in ipairs(toks) do
              toks[i] = tok:toString(c)
            end
            return concat(toks)
         end
end
```


### Peg base class

```lua
local Peg, peg = Node : inherit()
Peg.id = "peg"
```


### PegPhrase class

  We might want to decorate our phrases with various REPRy enhancements, so
let's pull a fresh metatable:

```lua
local PegPhrase = Phrase : inherit ({__repr = lex})
```


### Peg:toSexpr\(\)

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


### Peg:toSexprRepr\(\)

A bit ugly perhaps, but this will let us view the sexprs as more than a
mere string\.

I will most likely elaborate this past the useful point, in the pursuit of
happiness\.

\#Todo
interpolate colors into the repr string representation\.\.

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


## Peg\.toLpeg\(peg\)

This needs to be implemented by each subclass, individually, so we produce a
base method that highlights the span in red\.  This makes it stick out, and
will produce an error if we attempt to compile it\.

```lua
local a = require "anterm:anterm"
function Peg.toLpeg(peg)
   local phrase = PegPhrase ""
   for _, sub in ipairs(peg) do
      phrase = phrase .. sub:toLpeg()
   end
   return phrase
end
```

## PegMetas

```lua
local PegMetas = Peg : inherit()
PegMetas.id = "pegMetas"
```


### Rules

`rules` is our base class, and we manually iterate through the AST to
generate passable Lua code\.

It's not pretty, but it's valid\.  At least, so far; PRs welcome\.

```lua
local Rules = PegMetas : inherit "rules"
```


##### \_normalize

  Causes any `-` in a pattern or atom to become `_`, allowing us to treat them
as interchangeable\.  This is my crank compromise between ordinary string
matching and creations such as Nim's symbol equivalence and unified call
syntax\.

```lua
local function _normalize(str)
   return str:gsub("%-", "%_")
end
```

#### Rules\.\_\_call\(rules, str\)

We allow the Peg root node to be callable as a Grammar\.

```lua
function Rules.__call(rules, str, start, finish)
   if not rules.parse then
      rules.parse, rules.grammar = Grammar(rules:toLpeg())
   end
   return rules.parse(str, start, finish)
end
```


### Rules:toLpeg\(extraLpeg\)

Converts declarative Peg rules into a string of Lua code implementing a
Grammar function\.

`extraLpeg` is an optional string appended to the generated string before the
final `end`, to inject rules which aren't expressible using the subset of
`lpeg` which the Peg module supports\.


#### \_PREFACE

```lua
local _PREFACE = PegPhrase ([[
local L = assert(require "lpeg")
local P, V, S, R = L.P, L.V, L.S, L.R
local C, Cg, Cb, Cmt = L.C, L.Cg, L.Cb, L.Cmt
]])
```

```lua
local backref_rules = {
   back_reference = [[
local function __EQ_EXACT(s, i, a, b)
   return a == b
end
]],
   equal_reference = [[
local function __EQ_LEN(s, i, a, b)
   return #a == #b
end
]],
   gte_reference = [[
local function __GTE_LEN(s, i, a, b)
   return #a >= #b
end
]],
   gt_reference = [[
local function __GT_LEN(s, i, a, b)
   return #a > #b
end
]],
   lte_reference = [[
local function __LTE_LEN(s, i, a, b)
   return #a <= #b
end
]],
   lt_reference = [[
local function __LT_LEN(s, i, a, b)
   return #a < #b
end
]]
}
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
   local len = 14
   local phrase = PegPhrase "   " .. "SUPPRESS" .. " " .. "("
   for i, patt in ipairs(hiddens) do
      phrase = phrase .. "\"" .. patt .. "\""
      len = len + #patt + 2
      if i < #hiddens then
         phrase = phrase .. "," .. " "
         if len > 80 then
            phrase = phrase .. "\n" .. (" "):rep(14)
            len = 14
         end
      end
   end
   return phrase .. ")" .. "\n\n"
end

function Rules.toLpeg(peg_rules, extraLpeg)
   local phrase = PegPhrase()
   -- Add matching functions if those rules are used
   for rule, fn_str in pairs(backref_rules) do
       if peg_rules:select(rule)() then
          phrase = phrase .. fn_str
       end
   end
   phrase = phrase .. "\n"
   -- the first rule should have an atom:
   -- peg_rules[1]   -- this is the first rule
   local grammar_patt = peg_rules : select "rule" ()
                         : select "pattern" ()
   local grammar_name = grammar_patt:span()
   -- the root pattern can conceivably be hidden:
   if grammar_name:sub(1,1) == "`" then
      grammar_name = grammar_name:sub(2,-2)
   end
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
   -- add initial indentation:
   phrase = phrase .. "\n"
   --
   -- stick everything else in here...
   ---[[
   for rule in peg_rules : select "rule" do
      phrase = phrase .. rule:toLpeg()
   end
   --]]
   phrase = phrase .. (extraLpeg or "")
   phrase = phrase .. "\nend\n\n"
   local appendix = PegPhrase "return " .. grammar_fn .. "\n"
   return _PREFACE .. phrase .. appendix
end
```


#### Rules:toGrammar\(metas, pre, post, extraLpeg, header\)

  Builds a Grammar out of a parsed Peg set\. All non\-self parameters are
optional\.


- Params:

  - metas:  Metatables for function behavior \(this module is an example of
      this parameter\)\.

  - pre:  A function operating on the string to be parsed before the grammar
      is Matched\.  Expected to return a string\.

  - post:  A function operating on the Nodes returned by the match, before the
      AST is returned\. Expected to return an AST, but whatever it returns
      will be passed on by the Grammar\.

  - extraLpeg:  String inserted after generated rules and before the final
      `end` of the function\.

  - header:  String inserted before the beginning of the generated
      function\.

      This and `extraLpeg` must be valid Lua chunks\.

The resulting Grammar is stored as `rules.grammar` and can be invoked with the
corresponding `__call` metamethod\.  `toGrammar` will overwrite these if they
have been created already, since the other parameters can be changed\.

```lua
function Rules.toGrammar(rules, metas, pre, post, extraLpeg, header)
   metas = metas or {}
   header = header or ""
   local rule_str = rules:toLpeg(extraLpeg)
   rule_str = header .. rule_str
   rules.parse, rules.grammar = Grammar(rule_str, metas, pre, post)
   return rules.parse
end
```


### Rules:allParsers\(\)

This returns a map of every rule name to a parser which recognizes that rule\.

```lua
function Rules.allParsers(rules)
   local allGrammars = {}
   for rule in rules :select "rule" do
      allGrammars[rule:ruleName()] = rule:toPeg():toGrammar()
   end
   return allGrammars
end
```


### Rules:getRule\(name\)

Returns a rule of name `name`, if one exists\.

```lua

function Rules.getRule(rules, name)
   for rule in rules :select "rule" do
      if rule:ruleName() == _normalize(name) then
         return rule
      end
   end
   return nil
end
```


### Rules:getGrammar\(name\)

```lua
function Rules.getGrammar(rules, name)
   local _rule = rules:getRule(name)
   if not _rule then return nil end
   return _rule:toPeg()
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

function Rule.ruleName(rule)
   return _normalize(_pattToString(rule:select "pattern" ()))
end

function Rule.toLpeg(rule)
   local phrase = PegPhrase ""
   local patt = rule:ruleName()
   phrase = phrase .. patt .. " = "
   return phrase .. rule:select "rhs" () : toLpeg ()
end
```


### Rule:toPegStr\(\)

This returns a string which can be processed by Peg back into a parsing
expression grammar, such that that grammar will parse the rule\.

It actually returns a \_\_repr\-able table with a \_\_tostring method, and is
mostly for development, `:toPeg` being the more useful method\.

Also returns a handy metatable as a second value

```lua
local _peg_str_memo = setmetatable({}, { __mode = 'kv' })

function Rule.toPegStr(rule)
   local rules = rule:root()
   local rule_name = rule:ruleName()
   local metas = rules.metas or {}
   local new_metas = {metas[1], [rule_name] = metas[rule_name]}

   local name_rule, name_atoms = unpack(_peg_str_memo[rules] or {})
   if not name_rule then
      -- make the rules map
      name_rule, name_atoms = {}, {}
      for _rule in rules :select "rule" do
         local _rule_name = _rule:ruleName()
         local atoms = {}
         name_rule[_rule_name] = _rule
         name_atoms[_rule_name] = atoms
         for atom in _rule :select "rhs" () :select "atom" do
             insert(atoms, (_normalize(atom:span())))
         end
      end
      -- and memoize it
      _peg_str_memo[rules] = pack(name_rule, name_atoms)
   end

   local peg_str = {}
   local dupes = { rule = true }
   -- add the start rule
   insert(peg_str, rule:span())

   local function _rulesFrom(atoms)
      for _, atom in ipairs(atoms) do
         local _rule = name_rule[atom]
         new_metas[atom] = metas[atom]
         if _rule and not dupes[_rule] then
            insert(peg_str, _rule:span())
            dupes[_rule] = true
            _rulesFrom(name_atoms[atom])
         end
      end
   end

   _rulesFrom(name_atoms[rule_name])

   local function rfn() return concat(peg_str, "\n") end

   return setmetatable({}, { __repr = rfn, __tostring = rfn }),
          new_metas
end
```


### Rule:toPeg\(\)

Through the magic of late binding `require`, we can in fact generate a Peg
even though this module is a dependency of it\.

`:toPeg()` returns a Peg of the given rule\.

```lua
local _Peg;

function Rule.toPeg(rule)
   _Peg = _Peg or require "espalier:espalier/peg"
   local str, _M = rule:toPegStr()
   return _Peg(tostring(str), _M)
end
```

#### lhs, pattern, hidden\_pattern

These are all handled internally by Rule, so they don't require
their own lpeg transducers\.

These should be inherited with proper PascalCaps in the event we write, for
example, a toHtml method\.


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
   local phrase = PegPhrase "*"
   for _, sub_cat in ipairs(cat) do
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
correctly\. Now, you'd **think** I could manage this, but it isn't a priority
right now\.


### Not\_predicate

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


### And\_predicate

Equivalent of `#rule` in Lpeg\.

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


### Literal

This offers an exact match of a substring\.

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


### Zero\_or\_more

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


### One\_or\_more

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
implementation\.

The simpler case is a numeric repeat: this simply matches the suffixed pattern
an exact number of times\.

```lua
local Repeated = PegMetas : inherit "repeated"

function Repeated.toLpeg(repeated)
   local phrase = PegPhrase ""
   local condition = repeated[1]:toLpeg():intern()
   local times = repeated[2]:span()
      -- match at least times - 1 and no more than times
   phrase = phrase .. "#" .. condition .. "^" .. times
               .. " * " .. condition .. "^-" .. PegPhrase(times)
   return phrase
end
```


### Named

The most complex rule in the book, this handles capture groups and back
references\.

```lua
local Named = PegMetas : inherit "named"

function Named.toLpeg(named)
   local phrase = PegPhrase ""
   local condition = named[1]:toLpeg():intern()
   if named[2].id == "named_match" then
     -- make a capture group
     phrase = phrase .. "Cg(" .. condition .. ",'" .. named[2]:span()
               .. PegPhrase "')"
   elseif named[2].id == "back_reference" then
     -- make a back reference with equality comparison
     phrase = phrase .. "Cmt(C(" .. condition
               .. ") * Cb('" .. named[2]:span()
               .. PegPhrase"'), __EQ_EXACT)"
   elseif named[2].id == "equal_reference" then
     -- make a back reference, compare by length
     phrase = phrase .. "Cmt(C(" .. condition
               .. ") * Cb('" .. named[2]:span()
               .. PegPhrase"'), __EQ_LEN)"
   elseif named[2].id == "gte_reference" then
      phrase = phrase .. "Cmt(C(" .. condition
               .. ") * Cb('" .. named[2]:span()
               .. PegPhrase"'), __GTE_LEN)"
   elseif named[2].id == "gt_reference" then
      phrase = phrase .. "Cmt(C(" .. condition
               .. ") * Cb('" .. named[2]:span()
               .. PegPhrase"'), __GT_LEN)"
   elseif named[2].id == "lte_reference" then
      phrase = phrase .. "Cmt(C(" .. condition
               .. ") * Cb('" .. named[2]:span()
               .. PegPhrase"'), __LTE_LEN)"
   elseif named[2].id == "gte_reference" then
      phrase = phrase .. "Cmt(C(" .. condition
               .. ") * Cb('" .. named[2]:span()
               .. PegPhrase"'), __LT_LEN)"
   else
      error("unexpected back reference, id " .. tostring(named[2].id))
   end
   return phrase
end
```


### Comment

```lua
local Comment = PegMetas : inherit "comment"

function Comment.toSexpr(comment)
   return ""
end

function Comment.toLpeg(comment)
   local phrase = PegPhrase "--"
   return phrase .. comment:span():sub(2)
end
```


### Atom

This is grammatically different from pattern only by virtue of being on the
right hand side\.

This is convenient, since it translates differently into lpeg\.

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


### Dent

An in `dent` tation; we want the Lpeg to reflect the spacing of the source
document\.

```lua
local Dent = PegMetas : inherit "dent"

function Dent.toLpeg(dent)
   return dent:span()
end

function Dent.strLine(dent)
   return ""
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
return { Peg,
         rules   = Rules,
         rule    = Rule,
         rhs     = Rhs,
         comment = Comment,
         choice  = Choice,
         cat     = Cat,
         group   = Group,
         atom    = Atom,
         number  = Number,
         set     = Set,
         range   = Range,
         literal = Literal,
         zero_or_more  = Zero_or_more,
         one_or_more   = One_or_more,
         not_predicate = Not_predicate,
         and_predicate = And_predicate,
         optional  = Optional,
         repeated  = Repeated,
         named     = Named,
         WS        = Whitespace,
         dent      = Dent }
```
