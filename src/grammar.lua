







































































local L = require "lpeg"

local s = require "status" 
local Node = require "node/node"







local assert = assert
local string, io = assert( string ), assert( io )
local V = string.sub( assert( _VERSION ), -4 )
local _G = assert( _G )
local error = assert( error )
local pairs = assert( pairs )
local next = assert( next )
local type = assert( type )
local tostring = assert( tostring )
local setmetatable = assert( setmetatable )
if V == " 5.1" then
   local setfenv = assert( setfenv )
   local getfenv = assert( getfenv )
end






local function make_ast_node(id, first, t, last, str, metas, offset)
   local offset = offset or 0
   t.first = first + offset
   t.last  = last + offset - 1
   t.str   = str
   if metas[id] then
      local meta = metas[id]
      if type(meta) == "function" or meta.__call then
        t = metas[id](t, str)
      else
        t = setmetatable(t, meta)
      end
      assert(t.id == id)
   else
    t.id = id
    setmetatable(t, {__index = Node,
                     __tostring = Node.toString})
   end
   assert(t.isNode, "failed isNode: " .. id)
   assert(t.str)
   return t
end


-- some useful/common lpeg patterns
local Cp = L.Cp
local Cc = L.Cc
local Ct = L.Ct
local arg1_str = L.Carg(1)
local arg2_metas = L.Carg(2)
local arg3_offset = L.Carg(3)


-- setup an environment where you can easily define lpeg grammars
-- with lots of syntax sugar
local function define(func, g, e)
  g = g or {}
  if e == nil then
    e = V == " 5.1" and getfenv(func) or _G
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
    P = L.P,
  }

  setmetatable(env_index, { __index = e })
  setmetatable(env, {
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
    end
  })
  -- call passed function with custom environment (5.1- and 5.2-style)
  if V == " 5.1" then
    setfenv( func, env )
  end
  func( env )
  assert( g[ 1 ] and g[ g[ 1 ] ], "no start rule defined" )
  return g
end



local function refineMetas(metas)
  io.write("refining metatables\n")
  for id, meta in pairs(metas) do
    io.write("  id: " .. id .. " type: " .. type(meta) .. "\n")
    if type(meta) == "table" then
      if not meta["__tostring"] then
        meta["__tostring"] = Node.toString
      end
      if not meta.id then
        io.write("    inserting metatable id: " .. id .. "\n")
        meta.id = id
      else
        io.write("    id of " .. id .. " is " .. meta.id .. "\n")
      end
    end
  end
  return metas
end




local function new(grammar_template, metas)
  if type(grammar_template) == 'function' then
    local metas = metas or {}
    metas = refineMetas(metas)
    local grammar = define(grammar_template, nil, metas)

    local function parse(str, offset)
      local offset = offset or 0
      return L.match(grammar, str, 1, str, metas, offset) -- other 
    end

    return parse
  else
    s:halt("no way to build grammar out of " .. type(template))
  end
end



return new
