# Strap o' the Boot


A user script for generating the PEGPEG engine\.

Will serve as a shim while we round the corner on MetaMeld\.

```lua
local core = use "qor:core"

local Vav = use "espalier:vav"

local phrase = "#!lua\n" .. Vav(use "espalier:peg/pegpeg"):toLpeg()
               .. "#/lua\n"

core.string.spit('peg-engine.orb', phrase)
```