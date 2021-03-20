




























































































































































local s = require "status:status" ()
s.verbose = false
s.angry   = false






local L = require "lpeg"
local compact = assert(require "core/table" . compact)
local Node = require "espalier/node"













local assert = assert
local string = assert(string)
local sub = assert(string.sub)
local remove = assert(table.remove)
local VER = sub(assert(_VERSION), -4)
local _G = assert(_G)
local error = assert(error)
local pairs = assert(pairs)
local next = assert(next)
local type = assert(type)
local tostring = assert(tostring)
local setmeta = assert(setmetatable)
if VER == " 5.1" then
   local setfenv = assert(setfenv)
   local getfenv = assert(getfenv)
end








local function make_ast_node(id, first, t, last, str, metas, offset)





























   t.first = first + offset
   t.last  = last + offset - 1
   t.str   = str
   if metas[id] then
      local meta = metas[id]
      if type(meta) == "function" then
        t.id = id
        t = meta(t, offset)
      else
        t = setmeta(t, meta)
      end
      assert(t.id, "no id on Node")
   else
      t.id = id
      setmeta(t, metas[1])
   end

   if not t.parent then
      t.parent = t
   end















   local top, touched = #t, false
   for i = 1, top do
      local cap = t[i]
      if type(cap) ~= "table" or not cap.isNode then
         touched = true
         t[i] = nil
      else
         cap.parent = t
      end
   end
   if touched then
      compact(t, top)
   end









   -- post conditions
   assert(t.isNode, "failed isNode: " .. id)
   assert(t.str)
   assert(t.parent, "no parent on " .. t.id)
   return t
end























local Cp = L.Cp
local Cc = L.Cc
local Ct = L.Ct
local arg1_str = L.Carg(1)
local arg2_metas = L.Carg(2)
local arg3_offset = L.Carg(3)






local function define(func, g, e)
   g = g or {}
   if e == nil then
      e = VER == " 5.1" and getfenv(func) or _G
   end
   local suppressed = {}
   local env = {}
   local env_index = {
      START = function(name) g[1] = name end,
      SUPPRESS = function(...)
         suppressed = {}
         for i = 1, select('#', ...) do
            suppressed[select(i, ... )] = true
         end
      end,
      V = L.V,
      P = L.P }

    setmeta(env_index, { __index = e })
    setmeta(env, {
       __index = env_index,
       __newindex = function( _, name, val )
          if suppressed[ name ] then
             g[ name ] = val
          else
             g[ name ] = Cc(name)
                       * Cp()
                       * Ct(val)
                       * Cp()
                       * arg1_str
                       * arg2_metas
                       * arg3_offset / make_ast_node
          end
       end })

   -- call passed function with custom environment (5.1- and 5.2-style)
   if VER == " 5.1" then
      setfenv(func, env )
   end
   func( env )
   assert( g[ 1 ] and g[ g[ 1 ] ], "no start rule defined" )
   return g
end








local function refineMetas(metas)
  for id, meta in pairs(metas) do
    if id ~= 1 then
      if type(meta) == "table" then
        -- #todo is this actually necessary now?
        -- if all Node children are created with Node:inherit then
        -- it isn't.
        if not meta["__tostring"] then
          meta["__tostring"] = Node.toString
        end
        if not meta.id then
          meta.id = id
        end
      end
    end
  end
  if not metas[1] then
     metas[1] = Node
  end
  return metas
end























local function _fromString(g_str)
   local maybe_lua, err = loadstring(g_str)
   if maybe_lua then
      return maybe_lua()
   else
      s : halt ("cannot make function:\n" .. err)
   end
end

local function _toFunction(maybe_grammar)
   if type(maybe_grammar) == "string" then
      return _fromString(maybe_grammar)
   elseif type(maybe_grammar) == "table" then
      -- we may as well cast it to string, since it might be
      -- and sometimes is a Phrase class
      return _fromString(tostring(maybe_grammar))
   end
end

local P = assert(L.P)

local function new(grammar_template, metas, pre, post)
   if type(grammar_template) ~= "function" then
      -- see if we can coerce it
      grammar_template = _toFunction(grammar_template)
   end

   local metas = metas or {}
   metas = refineMetas(metas)
   local grammar = define(grammar_template, nil, metas)

   local function parse(str, start, finish)
      local sub_str, begin = str, 1
      local offset = start and start - 1 or 0
      if start and finish then
         sub_str = sub(str, start, finish)
      end
      if start and not finish then
         begin = start
         offset = 0
      end
      if pre then
         str = pre(str)
         assert(type(str) == "string")
      end

      local match = L.match(grammar, sub_str, begin, str, metas, offset)
      if match == nil then
         return nil
      elseif type(match) == 'number' then
         return sub(sub_str, 1, match)
      end
      if post then
        match = post(match)
      end
      match.complete = match.last == #sub_str + offset
      return match
   end

   return parse, grammar
end



return new

