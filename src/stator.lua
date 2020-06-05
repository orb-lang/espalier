















local setmeta = assert(setmetatable)



local Stator = meta {}








-- local _weakstate = setmeta({}, {__mode = 'v'})
















local function call(stator, _weakstate)
   local _weakstate = _weakstate or setmeta({}, {__mode = 'v'})
   local _M = setmeta({}, {__index = stator, __call = call })
   _M._weakstate =  _weakstate
   return _M
end









local function new(Stator, _weakstate)
   local stator = call(Stator, _weakstate)
   stator.g, stator.G, stator._G = stator, stator, stator
   return stator
end




return setmetatable(Stator, {__call = new})
