






local Node = require "espalier/node"
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









function Peg.toLpeg(peg)
   s:halt ("must implement toLepeg for class " .. peg.id)
end





local PegMetas = Peg : inherit()
PegMetas.id = "pegMetas"









local PegPhrase = Phrase() : inherit ()





local Rules = PegMetas : inherit "rules"

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



local Rule = PegMetas : inherit "rule"

function Rule.toLpeg(rule, depth)
   depth = depth or 0
   local phrase = PegPhrase(("   "):rep(depth))
   local lhs = rule:select "pattern" () : span()
   phrase = phrase .. lhs .. " = "
   local rhs = rule:select "rhs" () : toLpeg (depth)
   return phrase .. rhs .. "\n"
end



local Rhs = PegMetas : inherit "rhs"

function Rhs.toLpeg(rhs, depth)
   local phrase = PegPhrase()
   for _, twig in ipairs(rhs) do
      phrase = phrase .. " " .. twig:toLpeg(depth + 1)
   end
   return phrase
end



local Choice = PegMetas : inherit "choice"

function Choice.toLpeg(choice, depth)
   local phrase = PegPhrase "+"
   for _, sub_choice in ipairs(choice) do
      phrase = phrase .. " " .. sub_choice:toLpeg(depth + 1)
   end
   return phrase
end



local Maybe = PegMetas : inherit "maybe"

function Maybe.toLpeg(maybe, depth)
   local phrase = PegPhrase()
   for _, sub_maybe in ipairs(maybe) do
      phrase = phrase .. " " .. sub_maybe:toLpeg(depth + 1)
   end
   return phrase .. "^-1"
end



local Cat = PegMetas : inherit "cat"

function Cat.toLpeg(cat, depth)
   local phrase = PegPhrase " * "
   for _, sub_cat in ipairs(cat) do
      phrase = phrase .. " " .. sub_cat:toLpeg(depth)
   end
   return phrase
end



local Group = PegMetas : inherit "group"

function Group.toLpeg(group, depth)
   local phrase = PegPhrase "("
   for _, sub_group in ipairs(group) do
      phrase = phrase .. " " .. sub_group:toLpeg(depth)
   end
   return phrase .. ")"
end



local Atom = PegMetas : inherit "atom"

function Atom.toLpeg(atom, depth)
   local phrase = PegPhrase "V"
   phrase = phrase .. "\"" .. atom:span() .. "\""
   return phrase
end




local Comment = PegMetas : inherit()
Comment.id = "comment"

function Comment.toSexpr(comment, depth)
   return ""
end

function Comment.toLpeg(comment, depth)
   local phrase = PegPhrase "--"
   return phrase .. comment:span():sub(2) .. "\n"
end



return { rules = Rules,
         rule  = Rule,
         rhs   = Rhs,
         comment = Comment,
         choice = Choice,
         cat     = Cat,
         group   = Group,
         atom    = Atom,
         maybe   = Maybe }
