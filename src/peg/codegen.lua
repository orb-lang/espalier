








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

local function _suppressHiddens(peg_rules)
   local hiddens = {}
   for hidden in peg_rules : filter 'suppressed' do
      insert(hiddens, hidden.token)
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
            push(phrase("\n" .. (" "):rep(14)))
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
   local start = rules :take 'rule' . token
   local grammar_fn  = "_" .. start .."_fn"
   push(phrase, "local function ", grammar_fn, "(_ENV)\n", "   START ",
                "\"", grammar_name, "\"\n")
   -- Build the SUPPRESS function here, this requires finding the
   -- hidden rules and suppressing them
   local suppress = _suppressHiddens(peg_rules)
   if suppress then
      push(phrase, suppress)
   end
   -- add initial indentation:
   push(phrase, "\n")

   for rule in peg_rules : select "rule" do
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



function M.name.toLpeg(name, phrase)
   push(phrase, 'V"', name.token, '"', " ")
end

