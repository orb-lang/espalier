























local Node = require "espalier/node"
local Grammar = require "espalier/grammar"
local core = require "singletons/core"
local Phrase = require "singletons/phrase"

local inherit = assert(core.inherit)
local insert, remove, concat = assert(table.insert),
                               assert(table.remove),
                               assert(table.concat)
local s = require "singletons/status" ()






local Peg, peg = Node : inherit()
Peg.id = "peg"






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



function Peg.toSexprRepr(peg)
   return newRepr(peg)
end









local a = require "singletons/anterm"
function Peg.toLpeg(peg)
   return a.red(peg:span())
end





local PegMetas = Peg : inherit()
PegMetas.id = "pegMetas"









local PegPhrase = Phrase() : inherit ()






function PegPhrase.__repr(peg_phrase)
   return tostring(peg_phrase)
end











local Rules = PegMetas : inherit "rules"








function Rules.__call(rules, str)
   if not rules.parse then
      rules.parse, rules.grammar = Grammar(rules:toLpeg())
   end
   return rules.parse(str)
end
















local _PREFACE = PegPhrase ([[
local L = assert(require "lpeg")
local P, V, S, R = L.P, L.V, L.S, L.R
]])








local function _normalize(str)
   return str:gsub("%-", "%_")
end



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

































function Rules.toGrammar(rules, metas, extraLpeg, header, pre, post)
   metas = metas or {}
   header = header or ""
   local rule_str = rules:toLpeg(extraLpeg)
   rule_str = header .. rule_str
   rules.parse, rules.grammar = Grammar(rule_str, metas, pre, post)
   return rules.parse
end








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















local Rhs = PegMetas : inherit "rhs"

function Rhs.toLpeg(rhs)
   local phrase = PegPhrase()
   for _, twig in ipairs(rhs) do
      phrase = phrase .. " " .. twig:toLpeg()
   end
   return phrase
end






local Choice = PegMetas : inherit "choice"

function Choice.toLpeg(choice)
   local phrase = PegPhrase "+"
   for _, sub_choice in ipairs(choice) do
      phrase = phrase .. " " .. sub_choice:toLpeg()
   end
   return phrase
end






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






local Group = PegMetas : inherit "group"

function Group.toLpeg(group)
   local phrase = PegPhrase "("
   for _, sub_group in ipairs(group) do
      phrase = phrase .. " " .. sub_group:toLpeg()
   end
   return phrase .. ")"
end













local NotThis = PegMetas : inherit "not_this"

function NotThis.toLpeg(not_this)
  local phrase = PegPhrase "-"
  for _, sub_not in ipairs(not_this) do
    phrase = phrase .. " " .. sub_not:toLpeg()
  end
  return phrase
end






local IfNotThis = PegMetas : inherit "if_not_this"

function IfNotThis.toLpeg(if_not)
   local phrase = PegPhrase "-("
   for _, sub_if_not in ipairs(if_not) do
      phrase = phrase .. sub_if_not:toLpeg()
   end
   return phrase .. ")"
end








local IfAndThis = PegMetas : inherit "if_and_this"

function IfAndThis.toLpeg(if_and_this)
   local phrase = PegPhrase "#"
   for _, sub_if_and_this in ipairs(if_and_this) do
      phrase = phrase .. " " .. sub_if_and_this:toLpeg()
   end
   return phrase
end



-- #todo am I going to use this? what is its semantics? -Sam.
local Capture = PegMetas : inherit "capture"








local Literal = PegMetas : inherit "literal"

function Literal.toLpeg(literal)
   return PegPhrase "P" .. literal:span()
end






local Set = PegMetas : inherit "set"

function Set.toLpeg(set)
   return PegPhrase "S\"" .. set:span():sub(2,-2) .. "\""
end









local Range = PegMetas : inherit "range"



function Range.toLpeg(range)
   local phrase = PegPhrase "R\""
   phrase = phrase .. range : select "range_start" () : span()
   return phrase .. range : select "range_end" () : span() .. "\" "
end






local Optional = PegMetas : inherit "optional"

function Optional.toLpeg(optional)
   local phrase = PegPhrase()
   for _, sub_option in ipairs(optional) do
      phrase = phrase .. " " .. sub_option:toLpeg()
   end
   return phrase .. "^0"
end






local MoreThanOne = PegMetas : inherit "more_than_one"

function MoreThanOne.toLpeg(more_than_one)
   local phrase = PegPhrase()
   for _, sub_more in ipairs(more_than_one) do
      phrase = phrase .. " " .. sub_more:toLpeg()
   end
   return phrase .. "^1"
end






local Maybe = PegMetas : inherit "maybe"

function Maybe.toLpeg(maybe)
   local phrase = PegPhrase()
   for _, sub_maybe in ipairs(maybe) do
      phrase = phrase .. " " .. sub_maybe:toLpeg()
   end
   return phrase .. "^-1"
end














local SomeNumber = PegMetas : inherit "some_number"

function SomeNumber.toLpeg(some_num)
   local phrase = PegPhrase "("
   local reps =  some_num : select "repeats" ()
   if not reps then
      s : halt "no repeats in SomeNumber"
   else
      -- make reps a number, our grammar should guarantee this
      -- succeeds.
      reps = tonumber(reps:span())
   end

   local patt = some_num[1]:toLpeg()
   if not patt then s : halt "no pattern in some_number" end

   for i = 1, reps do
      phrase = phrase .. patt
      if i < reps then
         phrase = phrase .. " * "
      end
   end

   return phrase .. ")"
end



local Comment = PegMetas : inherit "comment"

function Comment.toSexpr(comment)
   return ""
end

function Comment.toLpeg(comment)
   local phrase = PegPhrase "--"
   return phrase .. comment:span():sub(2) .. "\n"
end











local Atom = PegMetas : inherit "atom"

function Atom.toLpeg(atom)
   local phrase = PegPhrase "V"
   phrase = phrase .. "\"" .. _normalize(atom:span()) .. "\""
   return phrase
end






local Number = PegMetas : inherit "number"

function Number.toLpeg(number)
   local phrase = PegPhrase "P("
   return phrase .. number:span() .. ")"
end






local Whitespace = PegMetas : inherit "WS"

function Whitespace.toLpeg(whitespace)
   return PegPhrase(whitespace:span())
end



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
         optional = Optional,
         more_than_one = MoreThanOne,
         not_this  = NotThis,
         if_not_this = IfNotThis,
         if_and_this = IfAndThis,
         not_this     = NotThis,
         capture     = Capture,
         maybe   = Maybe,
         some_number = SomeNumber,
         WS      = Whitespace }
