










local Stator = setmetatable({}, {__index = Stator})












function call(stator)
  return setmetatable({}, {__index = stator, __call = call })
end









function new(Stator)
  local stator = call(Stator)
  stator.g, stator.G, stator._G = stator, stator, stator
  return stator
end




return setmetatable(Stator, {__call = new})
