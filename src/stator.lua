










local Stator = setmetatable({}, {__index = Stator})



function call(stator)
  return setmetatable({}, {__index = stator, __call = call })
end



return setmetatable(Stator, {__call = call})
