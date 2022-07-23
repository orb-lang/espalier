















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
   assert(t.str, "no string on node")
   assert(t.parent, "no parent on " .. t.id)
   return t
end























local Cp = L.Cp
local Cc = L.Cc
local Ct = L.Ct
local arg1_str = L.Carg(1)
local arg2_metas = L.Carg(2)
local arg3_offset = L.Carg(3)






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



local function define(func, g, e, definer)
   return definer(func, g, e)
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

