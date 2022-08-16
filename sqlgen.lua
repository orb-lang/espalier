
---[[GEN]] require "espalier:espalier/grammars/sqlite"
Vav = require "espalier:vav"
local ts = use "repr:repr" . ts_color
---[[ generate lua parser

lua_peg = require "scry:lua-peg"
vav = Vav(lua_peg)
vav:constrain()
vav :dji()

function printRules()
   for i, rule in ipairs(vav.synth) do
      print(ts(rule))
   end
end

printRules()

--print(vav.lpeg_engine)

--]]
--[[ SQLish stuff
sqlish = require "espalier:sqlish"
local trial = sqlish:try()
local num = Vav(sqlish.synth :pehFor 'number')
-- use "qor:core" . string.spit('sqlish_out.lua', sqlish.test_engine)
-- print(ts(num))

--]]
