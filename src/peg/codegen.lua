




local core, cluster = use("qor:core", "cluster:cluster")
local Feed = use "text:formfeed"
local Set = core.set







local function idx(tab, key)
   rawset(tab, key, {})
   return tab[key]
end

local M = setmetatable({}, {__index = idx})





local _PREFACE = [[
-- Automatically Generated by Espalier
local P, V, S = L.P, L.V, L.S
local R = L.R
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






local  concat =  assert(table.concat)

local function suppressHiddens(grammar, feed)
   local hiddens = {}
   for hidden in grammar :filter 'suppressed' do
      insert(hiddens, hidden :take 'rule_name' . token)
   end
   if #hiddens == 0 then
      -- no hidden patterns
      return nil
   end
   feed:newLine()
   feed:push("SUPPRESS", " ", "(")
   feed:indent()
   for i, patt in ipairs(hiddens) do
      feed:push('"' .. patt .. '"')
      if i < #hiddens then
         feed:push(",", " ")
      end
   end
   feed:push(")")
   feed:dedent()
   feed:newLine()
   feed:newLine()
end



function M.grammar.toLpeg(grammar, extraLpeg)
   local feed = Feed ()
   insert(feed, _PREFACE)
   -- reserve extra space at [2] for backref rules
   local preface = {}
   insert(feed, "")
   feed.preface = preface
   local start = grammar :take 'rule_name' . token
   local grammar_fn  = "_" .. start .."_fn"
   feed :push("local function ", grammar_fn, "(_ENV)")
        :indent(3)
        :newLine()
        :push("START", "", "'" .. start .. "'")
        :newLine()
   -- Build the SUPPRESS function here, this requires finding the
   -- hidden rules and suppressing them
   suppressHiddens(grammar, feed)

   -- aggregate rules into the feed
   for rule in grammar :filter 'rule' do
      rule:toLpeg(feed)
   end

   -- splice in backref functions if needed
   local pre = {""}
   for _, backref in ipairs(preface) do
      push(pre, backref_rules[backref])
   end
   feed[2] = concat(pre)

   feed :dedent() :push "end" :newLine(2)
        :push("return", " ", grammar_fn) :newLine()

   return feed
end






function M.rule.toLpeg(rule, feed)
   local token = '"' .. assert(rule :take 'rule_name' . token) .. '"'
   feed :push("_ENV", "[", token, "]", " ", "=", " ")
        :indent() :nudge(1)
   rule :take 'rhs' :toLpeg(feed)

   feed :dedent() :newLine(2)
end



function M.rhs.toLpeg(rhs, feed)
   assert(#rhs == 1, "more than one child on rhs?")
   rhs[1]:toLpeg(feed)
end






function M.cat.toLpeg(rule, feed)
   for i, element in ipairs(rule) do
      feed:push("")
      element:toLpeg(feed)
      if i < #rule then
         feed:push("", "*", "")
      end
   end
   feed:push("")
end



function M.alt.toLpeg(rule, feed)
   for i, element in ipairs(rule) do
      feed:push("")
      element:toLpeg(feed)
      if i < #rule then
         feed:push("", "+", "")
      end
   end
   feed:push("")
end






function M.group.toLpeg(group, feed)
   feed :push("", "(") :indent()
   assert(#group == 1, "group has other than one child")
   group[1]:toLpeg(feed)
   feed:push(")", "") :dedent()
end






function M.name.toLpeg(name, feed)
   feed:push("", 'V"' .. name.token .. '"', "")
end





















local Prefix = Set {'and', 'not'}
local Suffix = Set {'zero_plus', 'one_plus', 'optional', 'repeat'}
local Backref = Set {'backref'}

local Surrounding = Prefix + Suffix + Backref

local backrefBegin, backrefEnd

function M.element.toLpeg(elem, feed)
   local part, backref = elem[1], elem[2]

   -- backrefs enclose everything including lookahead prefixes
   if false then
      backrefBegin(backref, feed)
   end

   if elem['and'] then
         feed:push("", "#")
   elseif elem['not'] then
         feed:push("", "-", "(") :indent()
   end

   part:toLpeg(feed)

   if elem.zero_plus then
      feed:cling("^0")
   elseif elem.one_plus then
      feed:cling("^1")
   elseif elem.optional then
      feed:cling("^-1")
   elseif elem['repeat'] then
      -- handle this case
   end


   if elem['not'] then
      feed :push(")") :dedent()
   end

   if false then
      backrefEnd(backref, feed)
   end
   feed:push("")
end




function backrefBegin()

end

function backrefEnd()

end






function M.literal.toLpeg(literal, feed)
   feed:push("", "P" .. literal.token, "")
end






function M.number.toLpeg(number, feed)
   feed:push("", number.token, "")
end














function M.set.toLpeg(set, feed)
   feed:push("", 'S"' .. set.value ..'"',  "")
end



function M.range.toLpeg(range, feed)
   feed:push("", 'R"' .. range.from_char, range.to_char .. '"', "")
end











local upper = string.upper
function M.rule.toPikchr(rule)
   local feed = Feed()
   feed:push [[
     debug_label_color = 1
     linerad = 10px
     linewid *= 0.5
     $h = 0.21
     circle radius 10%
]]
   feed:push(upper(rule.token) .. ":", "")
   feed:push("[", "", "oval", "", '"' .. rule.token .. '"', "", "fit")
   feed:push("", "]")
   feed:newLine()
   return feed:view()
end




return M

