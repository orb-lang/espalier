### Qoph


This much we know, this is the Endjinn, the "I see we have recognized a rule\.
What shall we do with this rule?" of the ingenium\.

This has travelled with us from the original codebase, living in Grammar\.

I'll start with non\-functional snippets of Grammar, in a didactic order\.


### nodemaker

This is the recognition engine\.

```lua
local function nodemaker(func, g, e)
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
```

Stripped down to parts:

```lua
local function nodemaker(func, g, e)
   g = g or {}
   if e == nil then
      e = getfenv(func)
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
             onsuppress(g, name, val)
          else
             g[ name ] = oncapture / withcapture
          end
       end })


   setfenv(func, env)
   func(env)
   -- vav will not let rules get to qoph in this state:
   -- assert( g[ 1 ] and g[ g[ 1 ] ], "no start rule defined" )
   return g
end
```

In English: when we recognize a rule, we run `onsuppress` on it if it's a
suppressed rule, otherwise we execute the capture pattern and pass those
parameters to `withcapture`, which is called `make_ast_node` in the current
Grammar engine\.

I don't know what we call these operations yet\.



### make\_ast\_node

This is what we need to make generic

This takes a lot of parameters and does a lot of things\.

```lua
local function make_ast_node(id, first, t, last, str, metas, offset)
```


- Parameters:
  - id      :  'string' naming the Node
  - first   :  'number' of the first byte recognized from `str`
  - t       :  'table' capture of grammatical information
  - last    :  'number' of the last byte recognized from `str`
  - str     :  'string' being parsed
  - metas   :  'table' of Node\-inherited metatables \(complex\)
  - offset  :  'number' of optional offset\.  This would be provided if
      e\.g\. byte 1 of `str` is actually byte 255 of a larger
      `str`\.  Normally 0\.

`first`, `last` and `offset` follow Wirth indexing conventions\.

Because of course they do\.


#### Set up values and metatables

  We accept two types of value for a metatable\. A table must be derived from
the Node class, while a function must return an appropriately\-shaped table,
given the capture and offset\.

This can be used to process captures which aren't strings, perform validation,
or run another grammar and return an entire AST, but currently cannot fail to
return a Node of some sort\.

```lua
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
```


#### Drop non\-Nodes

  We discourage you to use captures inside grammars, and if you do, it's
better to discard them\.

But just in case, we iterate and drop anything which isn't a Node\.

It's actually possible that everything below here, up to the return, isn't
necessary\.  I'll leave it in for now; if it does guard against problems, they
would be difficult ones to debug\.

```lua
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
```


#### post\-conditions and return

These guard against certain simple mistakes which could arise from the use of
subgrammars\.

```lua
   -- post conditions
   assert(t.isNode, "failed isNode: " .. id)
   assert(t.str, "no string on node")
   assert(t.parent, "no parent on " .. t.id)
   return t
end
```


## define\(func, g, e\)

This is [Phillipe Janda](http://siffiejoe.github.io/lua-luaepnf/)'s
algorithm, with my adaptations\.

`func` is the grammar definition function, pieces of which we've provided\.
We'll see how the rest is put together presently\.

`e`, either is or becomes `_ENV`\.

This is not needed in LuaJIT, while for Lua 5\.2 and above, it is\.

`g` is, or becomes, a `Grammar`\.


#### localizations

We localize the patterns we use\.

```lua
local Cp = L.Cp
local Cc = L.Cc
local Ct = L.Ct
local arg1_str = L.Carg(1)
local arg2_metas = L.Carg(2)
local arg3_offset = L.Carg(3)
```

Setup an environment where you can easily define lpeg grammars with lots of
syntax sugar, compatible with the 5 series of Luas:

```lua
local function nodemaker(func, g, e)
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
```

```lua
local function define(func, g, e, definer)
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



#### Code Drop

This is an example of qoph, not vav, and yet\.

```lua
---
-- Adds hooks to a grammar to print debugging information
--
-- Debugging LPeg grammars can be difficult. Calling this function on your
-- grammmar will cause it to print ENTER and LEAVE statements for each rule, as
-- well as position and subject after each successful rule match.
--
-- For convenience, the modified grammar is returned; a copy is not made
-- though, and the original grammar is modified as well.
--
-- @param grammar The LPeg grammar to modify
-- @param printer A printf-style formatting printer function to use.
--                Default: stdnse.debug1
-- @return The modified grammar.
function debug (grammar, printer)
  printer = printer or printf
  -- Original code credit: http://lua-users.org/lists/lua-l/2009-10/msg00774.html
  for k, p in pairs(grammar) do
    local enter = lpeg.Cmt(lpeg.P(true), function(s, p, ...)
      printer("ENTER %s", k) return p end)
    local leave = lpeg.Cmt(lpeg.P(true), function(s, p, ...)
      printer("LEAVE %s", k) return p end) * (lpeg.P("k") - lpeg.P "k");
    grammar[k] = lpeg.Cmt(enter * p + leave, function(s, p, ...)
      printer("---%s---", k) printer("pos: %d, [%s]", p, s:sub(1, p-1)) return p end)
  end
  return grammar
end
```