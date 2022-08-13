
---[[GEN]] require "espalier:espalier/grammars/sqlite"
Vav = require "espalier:vav"
local ts = use "repr:repr" . ts_color
--[[ generate lua parser

lua_peg = require "scry:lua-peg"
vav = Vav(lua_peg)

vav :dji()

print(vav.lpeg_engine)

--]]
---[[
sqlish = require "espalier:sqlish"
local trial = sqlish:try()
local num = Vav(sqlish.synth :pehFor 'number')
print(ts(num))
--]]
