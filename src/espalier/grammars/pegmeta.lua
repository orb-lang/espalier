























local Node = require "espalier:espalier/node"
local Grammar = require "espalier:espalier/grammar"
local Seer   = require "espalier:espalier/recognize"
local Phrase = require "singletons/phrase"
local core = require "qor:core"
local insert, remove, concat = assert(table.insert),
                               assert(table.remove),
                               assert(table.concat)
local s = require "status:status" ()






local lines = assert(core.string.lines)
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
            return lines(concat(toks))
         end
end






local Peg, peg = Node : inherit()
Peg.id = "peg"


















local LITERAL, BOUNDED, REGULAR, RECURSIVE = 0, 1 , 2, 3

local NO_LEVEL = -1 -- comment and indentation type rules






local POWER = {'literal', 'bounded', 'regular', 'recursive',
                NaN = "NaN",
                [-1] = 'no_level' }






function Peg.powerLevel(peg)
   local pow = -1
   for _, twig in ipairs(peg) do
      local level = twig:powerLevel()
      -- level up!
      pow = (tonumber(level) > tonumber(pow)) and pow or level
   end
   pow = pow == -1 and "NaN" or pow
   return pow, POWER[pow]
end








function Peg.powerMap(peg, map)
   map = map or {}
   local nyi_map = {}
   local this_map = {}
   this_map[1], this_map[2], this_map[3] = peg.id, peg:powerLevel()
   insert(map, this_map)
   for _, twig in ipairs(peg) do
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












local PegPhrase = Phrase : inherit ({__repr = lex})






local nl_map = { rule = true }
local function _toSexpr(peg, depth)
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










local a = require "anterm:anterm"
function Peg.toLpeg(peg)
   local phrase = PegPhrase ""
   for _, sub in ipairs(peg) do
      phrase = phrase .. sub:toLpeg()
   end
   return phrase
end





local PegMetas = Peg : inherit()
PegMetas.id = "pegMetas"











local Rules = PegMetas : inherit "rules"











local function _normalize(str)
   return str:gsub("%-", "%_")
end







function Rules.__call(rules, str, start, finish)
   if not rules.parse then
      rules.parse, rules.grammar = Grammar(rules:toLpeg())
   end
   return rules.parse(str, start, finish)
end
















local _PREFACE = PegPhrase ([[
local L = assert(require "lpeg")
local P, V, S, R = L.P, L.V, L.S, L.R
local C, Cg, Cb, Cmt = L.C, L.Cg, L.Cb, L.Cmt
]])



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

































function Rules.toGrammar(rules, metas, pre, post, extraLpeg, header)
   metas = metas or {}
   header = header or ""
   local rule_str = rules:toLpeg(extraLpeg)
   rule_str = header .. rule_str
   rules.parse, rules.grammar = Grammar(rule_str, metas, pre, post)
   return rules.parse
end








function Rules.toSeer(rules, metas)
   metas = metas or {}
   local rule_str = rules:toLpeg()
   rules.see = Seer(rule_str, metas)
   return rules.see
end








function Rules.allParsers(rules)
   local allGrammars = {}
   for rule in rules :select "rule" do
      allGrammars[rule:ruleName()] = rule:toPeg():toGrammar()
   end
   return allGrammars
end









function Rules.getRule(rules, name)
   for rule in rules :select "rule" do
      if rule:ruleName() == _normalize(name) then
         return rule
      end
   end
   return nil
end









function Rules.subPeg(rules, name)
   local _rule = rules:getRule(name)
   if not _rule then return nil end
   return _rule:toPeg()
end









local function _atomsIn(rule)
   local atoms = {}
   for _, part in ipairs(rule:select 'rhs'()) do
      if part.id == 'atom' then
         insert(atoms, part)
      end
   end
   return atoms
end

function Rules.analyse(rules)
   local analysis = {}
   rules:root().analysis = analysis
   local calls = {{}}
   analysis.calls = calls
   local start_rule = rules :select 'rule' ()
   local start_name = start_rule:ruleName()
   calls[1][start_name] = _atomsIn(start_rule)
   calls[start_name]= calls[1][start_name]

   return analysis
end

Rules.analyze = Rules.analyse -- i18nftw






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



local format = assert(string.format)

function Rule.ruleString(rule)
   return format("%q", rule:ruleName())
end



function Rule.toLpeg(rule)
   local patt = rule:ruleString()
   local phrase = "_ENV[" .. patt .. "] = "
   return phrase .. rule:select "rhs" () : toLpeg ()
end














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











local _Peg;

function Rule.toPeg(rule)
   _Peg = _Peg or require "espalier:espalier/peg"
   local str, _M = rule:toPegStr()
   return _Peg(tostring(str), _M)
end




function Rule.toSexpr(rule)
   local phrase = "(rule " .. rule:ruleName()
   for _, twig in ipairs(rule :select "rhs"()) do
      phrase = phrase .. " " .. twig:toSexpr()
   end
   return phrase .. ")"
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
   local phrase = PegPhrase "*"
   for _, sub_cat in ipairs(cat) do
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













local Not_predicate = PegMetas : inherit "not_predicate"

function Not_predicate.toLpeg(not_pred)
   local phrase = PegPhrase "-("
   for _, sub_not_pred in ipairs(not_pred) do
      phrase = phrase .. sub_not_pred:toLpeg()
   end
   return phrase .. ")"
end








local And_predicate = PegMetas : inherit "and_predicate"

function And_predicate.toLpeg(and_predicate)
   local phrase = PegPhrase "#"
   for _, sub_and_predicate in ipairs(and_predicate) do
      phrase = phrase .. " " .. sub_and_predicate:toLpeg()
   end
   return phrase
end








local Literal = PegMetas : inherit "literal"

function Literal.toLpeg(literal)
   return PegPhrase "P" .. literal:span()
end








Literal.powerLevel = _literal








local Set = PegMetas : inherit "set"

function Set.toLpeg(set)
   return PegPhrase "S\"" .. set:span():sub(2,-2) .. "\""
end






Set.powerLevel = _bounded






local Range = PegMetas : inherit "range"



function Range.toLpeg(range)
   local phrase = PegPhrase "R\""
   phrase = phrase .. range : select "range_start" () : span()
   return phrase .. range : select "range_end" () : span() .. "\" "
end



Range.powerLevel = _bounded






local Zero_or_more = PegMetas : inherit "zero_or_more"

function Zero_or_more.toLpeg(zero_or_more)
   local phrase = PegPhrase()
   for _, sub_zero in ipairs(zero_or_more) do
      phrase = phrase .. " " .. sub_zero:toLpeg()
   end
   return phrase .. "^0"
end



Zero_or_more.powerLevel = _regular






local One_or_more = PegMetas : inherit "one_or_more"

function One_or_more.toLpeg(one_or_more)
   local phrase = PegPhrase()
   for _, sub_more in ipairs(one_or_more) do
      phrase = phrase .. " " .. sub_more:toLpeg()
   end
   return phrase .. "^1"
end



One_or_more.powerLevel = _regular






local Optional = PegMetas : inherit "optional"

function Optional.toLpeg(optional)
   local phrase = PegPhrase()
   for _, sub_optional in ipairs(optional) do
      phrase = phrase .. " " .. sub_optional:toLpeg()
   end
   return phrase .. "^-1"
end
















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






local Comment = PegMetas : inherit "comment"

function Comment.toSexpr(comment)
   return ""
end

function Comment.toLpeg(comment)
   local phrase = PegPhrase "--"
   return phrase .. comment:span():sub(2)
end

Comment.powerLevel = _no_level











local Atom = PegMetas : inherit "atom"

function Atom.toLpeg(atom)
   local phrase = PegPhrase "V"
   phrase = phrase .. "\"" .. _normalize(atom:span()) .. "\""
   return phrase
end





function Atom.toSexpr(atom)
   return "(symbol " .. _normalize(atom:span()) .. ")"
end















local Number = PegMetas : inherit "number"

function Number.toLpeg(number)
   local phrase = PegPhrase "P("
   return phrase .. number:span() .. ")"
end



Number.powerLevel = _literal









local Dent = PegMetas : inherit "dent"

function Dent.toLpeg(dent)
   return dent:span()
end

function Dent.strLine(dent)
   return ""
end

Dent.powerLevel = _no_level






local Whitespace = PegMetas : inherit "WS"

function Whitespace.toLpeg(whitespace)
   return PegPhrase(whitespace:span())
end

Whitespace.powerLevel = _no_level



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

