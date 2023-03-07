# Recognize

\#Legacy


Takes the same sort of grammar\-defining function as the Grammar module,
returning a recognizer over the same language\.

This either replies with the amount of the string it was able to recognize, or
`nil, err`; we'll define machinery to handle the `err` case later\.


## First step

I'm just going to copypasta jam it in there, so I can turn Pegs into this\.

##### status

```lua
local s = require "status:status" ()
s.verbose = false
s.angry   = false
```


#### requires, contd\.

```lua
local L = require "lpeg"
local compact = assert(require "core/table" . compact)
local Node = require "espalier/node"
```

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

And the rest of the copypasta:


```lua
local function define(definer, func, g, e)
   return definer(func, g, e)
end
```


### refineMetas\(metas\)

Takes metatables, distributing defaults and denormalizations\.

```lua
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
```


## new

Given a grammar\_template function and a set of metatables,
yield a parsing function and the grammar as an `lpeg` pattern\.


#### \_fromString\(g\_str\), \_toFunction\(maybe\_grammar\)

Currently this is expecting pure Lua code; the structure of the module is
such that we can't call the PEG grammar from `grammar.orb` due to the
circular dependency thereby created\.

\#Todo
the module, since it would happen at run time, not load time\.  This might not
be worthwhile, but it's worth thinking about at least\.

This implies wrapping some porcelain around everything so that we can at least
try to build the declarative form first\.

```lua
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
   local grammar = define(recognizer, grammar_template, nil, metas)

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
         return match
      end
      if post then
        match = post(match)
      end
      match.complete = match.last == #sub_str + offset
      return match
   end

   return parse, grammar
end
```

```lua
return new
```

