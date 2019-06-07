# Espalier

This library is now called ``espalier``.


Because it ``PEG``s trees to the wall.


Heh.

```lua
local dot     = require "espalier/dot"
local elpatt  = require "espalier/elpatt"
local Node    = require "espalier/node"
-- local Spec    = require "espalier/spec"
local Phrase  = require "espalier/phrase"
local Grammar = require "espalier/grammar"
local Stator  = require "espalier/stator"

return { dot     = dot,
         elpatt  = elpatt,
         node    = Node,
 --        spec    = Spec,
         phrase  = Phrase,
         grammar = Grammar,
         stator  = Stator }
```
