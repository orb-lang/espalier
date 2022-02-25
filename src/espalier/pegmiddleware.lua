




local Peg_M = require "espalier:espalier/pegmeta"










local P_ENV = setmetatable({}, { __index = getfenv(1) })

setfenv(1, P_ENV)
assert(getmetatable) -- sanity check



local upper = assert(string.upper)

for name, category in pairs(Peg_M) do
  if type(name) == 'string' then
     local up_name = upper(name:sub(1,1)) .. name:sub(2)
     P_ENV[up_name] = category:inherit(category.id)
  end
  -- no action for [1] which we are about to inherit and call Peg
end
-- another sanity check
assert(Rules)



return P_ENV

