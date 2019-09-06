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

local ortho8600 = require "espalier/grammars/ortho-8600"

local dot_grammar  = require "espalier/grammars/dot"

local lua_grammar  = require "espalier/grammars/lua"

local peg_grammar  = require "espalier/grammars/peg"

local lisp_grammar = require "espalier/grammars/microlisp"

local lexemes = require "espalier/lexemes"

local grammars = { ortho8600 = ortho8600,
                   dot       = dot_grammar,
                   lua       = lua_grammar,
                   peg       = peg_grammar,
                   lisp      = lisp_grammar, }

return { dot      = dot,
         elpatt   = elpatt,
         node     = Node,
         lex      = lexemes,
 --        spec    = Spec,
         phrase   = ss.Phrase,
         grammar  = Grammar,
         grammars = grammars,
         stator   = ss.Stator }
```
