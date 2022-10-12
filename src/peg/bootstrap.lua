



































local load = assert(load)
local L = require "lpeg"
local Cp, Ct = L.Cp, L.Ct

local arg1_str, arg2_offset = L.Carg(1), L.Carg(2)

local function define(vav)
   local l_peh = vav:toLpeg()
   local lvav = assert(load(l_peh))

   local grammar, suppressed, env = {}, {}, {}
   local env_index = {
      L = L,
      START = function(name)
                 grammar[1] = name
              end,
      SUPPRESS = function(...)
                    suppressed = {}
                    for i = 1, select('#', ...) do
                       suppressed[select(i, ... )] = true
                    end
                 end }
   local seed = assert(vav.mem.seed)
   -- maybe not the place to do this?
   for name, builder in pairs(seed) do
      if type(builder) ~= 'function' then
         seed[name] = function(...)
                         return builder(...)
                      end
      end
   end

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
   --assert(grammar[1], "no start rule defined for:\n" .. l_peh)
   vav.gmap = grammar

   return grammar
end


















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






return Qoph

