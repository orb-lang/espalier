
---[[GEN]] require "espalier:espalier/grammars/sqlite"

---[[ generate lua parser
Vav = require "espalier:vav"
lua_peg = require "scry:lua-peg"
v = Vav(lua_peg):synthesize()

print(tostring(v:toLpeg()))

--]]
--[[
sqlish = require "espalier:sqlish"
sqlish:analyze()
sqlish:dummyParser()
--]]
