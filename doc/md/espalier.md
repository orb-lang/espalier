# Espalier

This library is now called ``espalier``.


Because it ``PEG``s trees to the wall.


Heh.

```lua
local ss      = require "singletons"
local dot     = require "espalier/dot"
local elpatt  = require "espalier/elpatt"
local Node    = require "espalier/node"
-- local Spec    = require "espalier/spec"
local Grammar = require "espalier/grammar"

return { dot     = dot,
         elpatt  = elpatt,
         node    = Node,
 --        spec    = Spec,
         phrase  = ss.Phrase,
         grammar = Grammar,
         stator  = ss.Stator }
```
