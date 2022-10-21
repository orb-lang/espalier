# Bootstrap Back End

I'm getting lost in detail here\.

New strategy: I have these Nodes, and I need to get them onto ASTs\.

I also have Vav\.

This takes Vav and does the needful\.


### AKA Grammar

We're just recreating the Grammar class here, but using new tools rather than
old ones\.

One of the important differences being clades\.  In the original Grammar, we
fall back to raw Node if no metas are provided, here we can just add a clade
to Vav if we have to\.


#### call\-only metatable

This smooths out the interface, because now we call the builder for each phyle
in the clade\.

We'll have a mechanism for subgrammars which inserts itself into this process
smoothly\.


### define\(vav\)

The original version of this has some ancient compatibility affordances which
we don't happen to need\.

```lua
local load = assert(load)
local L = require "lpeg"
local Cp, Ct = L.Cp, L.Ct

local arg1_str, arg2_offset = L.Carg(1), L.Carg(2)
local insert = table.insert

local function define(vav)
   local l_peh = vav:toLpeg()
   local lvav = assert(load(l_peh))

   local grammar, suppressed, env = {}, {}, {}
   local function suppress(...)
      local s = ...
      if s then
         suppressed[s] = true
         return suppress(select(2, ...))
      else
         return
      end
   end
   local env_index = {
      L = L,
      START = function(name)
                 grammar[1] = name
              end,
      SUPPRESS = suppress }

   local seed = assert(vav.mem.seed)
   ---[[DBG]] --[[ The clade should handle this when things are mature
   for name, builder in pairs(seed) do
      if type(builder) ~= 'function' then
         error "seed is not a function"
      end
   end
   --[[DBG]]

   setmetatable(env, {
      __index = env_index,
      __newindex = function(_, name, val)
         if suppressed[name] then
            grammar[name] = val
         else
            grammar[name] = Cp()
                          * Ct(val)
                          * Cp()
                          * arg1_str
                          * arg2_offset / seed[name]
         end
      end })

   setfenv(lvav, env)()(env)
   assert(grammar[1] and grammar[grammar[1]],
          "no start rule defined for:\n" .. l_peh)
   vav.gmap = grammar

   return grammar
end
```


### Qoph

Various Qophs scattered all over the Qodebase\.\.\.

Noting here that pre\- and post\-conditional actions, as well as the engine
used in define, are proper to Qoph\.

Example: cases where root wants to be special, such as having a closure to
provide state to every child, where such would need to be passed into Qoph\.

Postconditions can get fairly elaborate for a Qoph which can recover from
errors; we'll bubble them up to the parents as part of recognition, but it
remains to detect them at least\.

```lua
local match = assert(L.match)

local function Qoph(vav)
   if not vav:complete() then
      return nil, "incomplete vav"
   end
   local grammar = define(vav)
   -- pre and post process setup here
   local function dji(str, start, finish)
      local sub_str, begin = str, 1
      local offset = start and start - 1 or 0
      if start and finish then
         sub_str = sub(str, start, finish)
      end
      if start and not finish then
         begin = start
         offset = 0
      end
      -- pre-process here
      local matched = match(grammar, sub_str, begin, str, offset)
      if matched == nil then
         return nil
      end
      -- post-process here
      matched.complete = matched.stride == #sub_str + offset
      return matched
   end
   vav.dji = dji

   return dji
end
```

Once that's cleaned up, we should have the new nodes rigged up so we can do
interesting things with them\.

```lua
return Qoph
```