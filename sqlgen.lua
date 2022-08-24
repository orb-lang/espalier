
--[[GEN]] require "espalier:espalier/grammars/sqlite"



--[[ SQLish stuff
Vav = require "espalier:vav"
local ts = use "repr:repr" . ts_color
sqlish = require "espalier:sqlish"
local trial = sqlish:try()
local num = Vav(sqlish.synth :pehFor 'number')
-- use "qor:core" . string.spit('sqlish_out.lua', sqlish.test_engine)
-- print(ts(num))

--]]
