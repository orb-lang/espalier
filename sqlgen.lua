
---[[GEN]] require "espalier:espalier/grammars/sqlite"

---[[ generate lua parser
Vav = require "espalier:vav"
lua_peg = require "scry:lua-peg"
vav = Vav(lua_peg)

vav :dji()

print(vav.lpeg_engine)

--]]
--[[
sqlish = require "espalier:sqlish"
sqlish:analyze()
sqlish:dummyParser()
--]]
