




local core, cluster = use("qor:core", "cluster:cluster")

local Set = core.set







local function idx(tab, key)
   rawset(tab, key, {})
   return tab[key]
end

local M = setmetatable({}, {__index = idx})





local _PREFACE = [[
-- Automatically Generated by Espalier

local L = assert(require "lpeg")
local P, V, S, R = L.P, L.V, L.S, L.R
local C, Cg, Cb, Cmt = L.C, L.Cg, L.Cb, L.Cmt

]]



local backref_rules = {
   back_refer = [[
local function __EQ_EXACT(s, i, a, b)
   return a == b
end

]],
   eq_refer = [[
local function __EQ_LEN(s, i, a, b)
   return #a == #b
end

]],
   gte_refer = [[
local function __GTE_LEN(s, i, a, b)
   return #a >= #b
end

]],
   gt_refer = [[
local function __GT_LEN(s, i, a, b)
   return #a > #b
end

]],
   lte_refer = [[
local function __LTE_LEN(s, i, a, b)
   return #a <= #b
end

]],
   lt_refer = [[
local function __LT_LEN(s, i, a, b)
   return #a < #b
end

]],
}






local insert, concat = assert(table.insert), assert(table.concat)

local function push(tab, ...)
   local one = ...
   if not one then return end
   insert(tab, one)
   return push(tab, select(2, ...))
end

local function _suppressHiddens(rules)
   local hiddens = {}
   for hidden in rules :filter 'suppressed' do
      insert(hiddens, hidden :take 'rule_name' . token)
   end
   if #hiddens == 0 then
      -- no hidden patterns
      return nil
   end
   local len = 14
   local phrase = {"   SUPPRESS ("}
   for i, patt in ipairs(hiddens) do
      push(phrase, "\"", patt, "\"")
      len = len + #patt + 2
      if i < #hiddens then
         push(phrase, ", ")
         if len > 78 then
            push(phrase, "\n",(" "):rep(14))
            len = 14
         end
      end
   end
   insert(phrase, ")\n\n")
   return concat(phrase)
end



function M.rules.toLpeg(rules, extraLpeg)
                           -- reserve extra space at [2] for backref rules
   local phrase, preface = {_PREFACE, ""}, {}
   phrase.preface = preface
   local start = rules :take 'rule_name' . token
   local grammar_fn  = "_" .. start .."_fn"
   push(phrase, "local function ", grammar_fn, "(_ENV)\n", "   START ",
                "\"", start, "\"\n")
   -- Build the SUPPRESS function here, this requires finding the
   -- hidden rules and suppressing them
   local suppress = _suppressHiddens(rules)
   if suppress then
      push(phrase, suppress)
   end
   -- add initial indentation:
   push(phrase, "\n")

   for rule in rules :filter 'rule' do
      rule:toLpeg(phrase)
   end
   local pre = {""}
   for _, backref in ipairs(preface) do
      push(pre, backref_rules[backref])
   end
   phrase[2] = concat(pre)


   push(phrase, "\nend\n\nreturn ", grammar_fn, "\n")
   return concat(phrase)
end






function M.rule.toLpeg(rule, phrase)
   push(phrase, "_ENV[", rule.token, "] = ")
   rule :take 'rhs' :toLpeg(phrase)
end



function M.rhs.toLpeg(rhs, phrase)
   assert(#rhs == 1, "more than one child on rhs?")
   rhs[1]:toLpeg(phrase)
end






function M.cat.toLpeg(rule, phrase)
   for i, element in ipairs(rule) do
      push(phrase, " ")
      element:toLpeg(phrase)
      if i < #rule then
         push(phrase, " ", "*", " ")
      end
   end
   push(phrase, " ")
end



function M.alt.toLpeg(rule, phrase)
   for i, element in ipairs(rule) do
      push(phrase, " ")
      element:toLpeg(phrase)
      if i < #rule then
         push(phrase, " ", "+", " ")
      end
   end
   push(phrase, " ")
end






function M.group.toLpeg(group, phrase)
   push(phrase, "(")
   assert(#group == 1, "group has other than one child")
   group[1]:toLpeg(phrase)
   push(phrase, ")")
end






function M.name.toLpeg(name, phrase)
   push(phrase, 'V"', name.token, '"', " ")
end


















local Prefix = Set {'and', 'not'}
local Suffix = Set {'zero-plus', 'one-plus', 'optional', 'repeat'}
local Backref = Set {'backref'}

local Surrounding = Prefix + Suffix + Backref

local backrefBegin, backrefEnd

function M.element.toLpeg(elem, phrase)
   local prefixed, backrefed  = Prefix[elem[1].class],
                                Backref[elem[#elem].class]
   local suffixed;
   if backrefed then
      suffixed = Suffix[elem[#elem-1].class]
   else
      suffixed = Suffix[elem[#elem].class]
   end
   local prefix, part, suffix, backref = nil, nil, nil, nil -- none of you are f

   if prefixed then
      prefix = elem[1]
      part = elem[2]
   else
      part = elem[1]
   end

   if backrefed and suffixed then
      backref = elem[#elem]
      suffix  = elem[#elem - 1]
   elseif suffixed then
      suffix = elem[#elem]
   elseif backrefed then
      backref = elem[#elem]
   end

   assert(not Surrounding[part.class], "missed the element part somehow")

   -- backrefs enclose everything including lookahead prefixes
   if backref then
      backrefBegin(backref, phrase)
   end

   if prefix then
      local which = prefix.class
      if which == 'and' then
         push(phrase, "#")
      elseif which == 'not' then
         push(phrase, "-", "(")
      else
         error(("bad prefix of class %s"):format(which))
      end
   end

   part:toLpeg(phrase)

   if suffix then
      local which = suffix.class
      if which == 'zero-plus' then
         push(phrase, "^0")
      elseif which == 'one-plus' then
         push(phrase, "^1")
      elseif which == 'optional' then
         push(phrase, "^-1")
      elseif which == 'repeat' then
         -- handle this case
      else
         error(("bad suffix of class %s"):format(which))
      end
   end

   if prefix and prefix.class == 'not' then
      push(phrase, ")")
   end

   if backref then
      backrefEnd(backref, phrase)
   end
   push(phrase, " ")
end




function backrefBegin()

end

function backrefEnd()

end






function M.literal.toLpeg(literal, phrase)
   push(phrase, "P", literal.token)
end






function M.number.toLpeg(number, phrase)
   push(phrase, "", number.token, " ")
end














function M.set.toLpeg(set, phrase)
   push(phrase, 'S"', set.value, '"',  " ")
end



function M.range.toLpeg(range, phrase)
   push(phrase, 'R"', range.from_char, range.to_char, '"', " ")
end




return M

