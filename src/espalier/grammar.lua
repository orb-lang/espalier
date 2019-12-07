
























































































































































local s = require "singletons" . status ()
s.verbose = false
s.angry   = false






local L = require "lpeg"
local a = require "singletons/anterm"

local Node = require "espalier/node"
local elpatt = require "espalier/elpatt"

local DROP = elpatt.DROP










local assert = assert
local string, io = assert( string ), assert( io )
local remove = assert(table.remove)
local VER = string.sub( assert( _VERSION ), -4 )
local _G = assert( _G )
local error = assert( error )
local pairs = assert( pairs )
local next = assert( next )
local type = assert( type )
local tostring = assert( tostring )
local setmeta = assert( setmetatable )
if VER == " 5.1" then
   local setfenv = assert( setfenv )
   local getfenv = assert( getfenv )
end







local _astMeta = { __index = Node,
                   __tostring = Node.toString,
                   __repr    = Node.__repr }








local function make_ast_node(id, first, t, last, str, metas, offset)





























   local offset = offset or 0
   t.first = first + offset
   t.last  = last + offset - 1
   t.str   = str
   if metas[id] then
      local meta = metas[id]
      if type(meta) == "function" then
        t = meta(t, offset)
      else
        t = setmeta(t, meta)
      end
      assert(t.id, "no id on Node")
   else
      t.id = id
      setmeta(t, _astMeta)
   end






















































   if not t.parent then
      t.parent = t
   end







   for i = #t, 1 --[[0]], -1 do
      t[i].parent = t
      local cap = t[i]
      if type(cap) ~= "table" then
         s:complain("CAPTURE ISSUE",
                    "type of capture subgroup is " .. type(v) .. "\n")
      end
      if cap.DROP == DROP then
         s:verb("drops in " .. a.bright(t.id))
         if i == #t then
            s:verb(a.red("rightmost") .. " remaining node")
            s:verb("  t.$: " .. tostring(t.last) .. " Δ: "
                   .. tostring(cap.last - cap.first))
            -- <action>
            t.last = t.last - (cap.last - cap.first)
            remove(t)
            -- </action>
            s:verb("  new t.$: " .. tostring(t.last))
         else
            -- Here we may be either in the middle or at the leftmost
            -- margin.  Leftmost means either we're at index 1, or that
            -- all children to the left, down to 1, are all DROPs.
            local leftmost = (i == 1)
            if leftmost then
               s:verb(a.cyan("  leftmost") .. " remaining node")
               s:verb("    t.^: " .. tostring(t.first)
                      .. " D.$: " .. tostring(cap.last))
               -- <action>
               t.first = cap.last
               --    <comment>
               s:verb("    new t.^: " .. tostring(t.first))
               --    </comment>
               remove(t, 1)
               -- </action>
            else
               leftmost = true -- provisionally since cap.DROP
               for j = i, 1, -1 do
                 leftmost = leftmost and t[j].DROP
                 if not leftmost then break end
               end
               if leftmost then
                  s:verb(a.cyan("  leftmost inner") .. " remaining node")
                  s:verb("    t.^: " .. tostring(t.first)
                         .. " D.$: " .. tostring(cap.last))
                  t.first = cap.last
                  s:verb("    new t.^: " .. tostring(t.first))
                  -- <action>
                  for j = i, 1, -1 do
                     -- this is quadradic but correct
                     -- and easy to understand.
                        remove(t, j)
                     break
                  end
                  -- </action>
               else
                  s:verb(a.green("  middle") .. " node dropped")
                  remove(t, i)
               end
            end
         end
      end
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
             g[ name ] = (Cc(name)
                * Cp()
                * Ct(val)
                * Cp()
                * arg1_str
                * arg2_metas)
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
    if type(meta) == "table" then
      if not meta["__tostring"] then
        meta["__tostring"] = Node.toString
      end
      if not meta.id then
        meta.id = id
      end
    end
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

local function new(grammar_template, metas, pre, post)
   if type(grammar_template) ~= "function" then
      -- see if we can coerce it
      grammar_template = _toFunction(grammar_template)
   end

   local metas = metas or {}
   metas = refineMetas(metas)
   local grammar = define(grammar_template, nil, metas)

   local function parse(str, offset)
      local offset = offset or 0
      --[[
      if pre then
         str = pre(str)
      end
      --]]
      local match = L.match(grammar, str, 1, str, metas, offset)
      if match == nil then
         return nil
      end
      --[[
      if post then
         error "error in post parsing"
        match = post(match)
      end
      --]]
      local maybeErr = match:lastLeaf()
      if maybeErr.id then
         if maybeErr.id == "ERROR" then
            local line, col = match:linePos(maybeErr.first)
            local msg = maybeErr.msg or ""
            s:complain("Parsing Error", " line: " .. tostring(line) .. ", "
                    .. "col: " .. tostring(col) .. ". " .. msg)
            return match, match:lastLeaf()
         else
            return match
         end
      else
         local maybeNode = maybeErr.isNode and " is " or " isn't "
         s:complain("No id on match" .. "match of type, " .. type(match)
                   .. maybeNode .. " a Node: " .. tostring(maybeErr))
      end
      -- This would be a bad match.
      return match
   end

   return parse, grammar
end



return new
