














local L = require "lpeg"
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













local curry, dji  = assert(require "core:core/fn" . curry),
                    assert(require "espalier:dji")









local setmeta = setmetatable

local function recognizer(func, g, e)
   g = g or {}
   if e == nil then
      e = VER == " 5.1" and getfenv(func) or _G
   end
   local env = {}
   local env_index = {
      START = function(name) g[1] = name end,
      V = L.V,
      P = L.P }

    setmeta(env_index, { __index = e })
    setmeta(env, {
       __index = env_index,
       __newindex = function( _, name, val )
             g[ name ] = val
       end })

   -- call passed function with custom environment (5.1- and 5.2-style)
   if VER == " 5.1" then
      setfenv(func, env )
   end
   func( env )
   assert( g[ 1 ] and g[ g[ 1 ] ], "no start rule defined" )
   return g
end



return curry(dji, recognizer)

