







local core = use "qor:core"

local Vav = use "espalier:vav"

local phrase = "#!lua\n" .. Vav(use "espalier:peg/pegpeg"):toLpeg()
               .. "#/lua\n"

core.string.spit('peg-engine.orb', phrase)

