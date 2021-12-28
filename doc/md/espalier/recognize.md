# Recognize


Takes the same sort of grammar\-defining function as the Grammar module,
returning a recognizer over the same language\.

This either replies with the amount of the string it was able to recognize, or
`nil, err`; we'll define machinery to handle the `err` case later\.


## First step

I'm just going to copypasta jam it in there, so I can turn Pegs into this\.

```lua
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
```


### import from core\.fn, curry, and from espalier, the dji combinator


  A thank you to Haskell, the esteemed doctor Curry, whom I am sure would be
dismayed by the programmer socks\.  If I may be allowed to venture that
opinion\.

Sometimes types don't have to be inferred\.

```lua
local curry, dji  = assert(require "core:core/fn" . curry),
                    assert(require "espalier:dji")

```


### Recognizer definition function

 The equivalent of what's now called "nodemaker" in Grammar

```lua
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
```

```lua
return curry(dji, recognizer)
```