

























































local L = use "lpeg"
local core, cluster = use("qor:core", "cluster:cluster")
local table = core.table



local NodeQoph = {}










local Cp = L.Cp
local Cc = L.Cc
local Ct = L.Ct
local Carg = L.Carg

NodeQoph.capturePattern = {'name', Cp, 'capture', Cp,
                           {Carg, 1}, {Carg, 2}, {Carg, 3}}



















local compact = assert(table.compact)

function NodeQoph.oncapture(class, first, capture, last, str, metas, offset)
   t.first = first + offset
   t.last  = last + offset - 1
   t.str   = str
   if metas[class] then
      local meta = metas[class]
      if type(meta) == "function" then
        t.class = class
        t = meta(t, offset)
      else
        t = setmeta(t, meta)
      end
      assert(t.class, "no class on Node")
   else
      t.class = class
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
   assert(t.isNode, "failed isNode: " .. class)
   assert(t.str, "no string on node")
   assert(t.parent, "no parent on " .. t.class)
   return t
end











local ltype = assert(L.type)
local function makeBuilder(Qoph, engine, ...)
   -- these defaults should result in a 'pure' recognizer
   local capture_patt, oncapture = Qoph.capture_patt or {P(true)},
                                   Qoph.oncapture or 0
   local _env = Qoph.env or {}
   local g = {}
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

    setmeta(env_index, { __index = _env })
    setmeta(env, {
       __index = env_index,
       __newindex = function( _, name, capture )
          if suppressed[name] then
             g[name] = capture
             return
          end

          local patt = P ""
          for _, pattern in ipairs(capture_patt) do
            -- special cases
            if pattern == 'name' then
               patt = patt * Cc(name)
            elseif pattern == 'capture' then
               patt = patt * Ct(value)
            elseif type(pattern) == 'function' then
               patt = patt * pattern()
            elseif ltype(pattern) == 'pattern' then
               patt = patt * pattern
            elseif type(pattern) == 'table' then
               patt = patt * pattern[1](unpack(pattern, 2))
            end
            g[name] = patt / oncapture
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







return {NodeQoph = NodeQoph, makeBuilder = makeBuilder }

