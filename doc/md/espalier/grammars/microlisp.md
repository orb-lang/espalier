# Microlisp


A declarative PEG parser for a Platonic sexpr language\.

```lua
local Grammar = require "espalier/grammar"
local Peg = require "espalier/peg"
local Node = require "espalier/node"
```


## micro\_lisp\_peg

```lua
local micro_lisp_peg = [[
lisp = _ ((atom)+ / list)
list = pel _ (atom / list)* per _
atom = _(number / symbol)_
symbol = _(alpha / other) (alpha / digit / other)*_
number = float / integer
`integer` = [0-9]+
`float` = [0-9]+ "." [0-9]+ ; expand
`pel` = '('
`per` = ')'
`alpha` = [A-Z]/[a-z]
`digit` = [0-9]
`other` = {-_-=+!@#$%^&*:/?.\\~}
  `_`     = { \t\r\n,}*
]]
```

```lua
local micro_lisp_metas = { lisp = Node : inherit "lisp",
                           atom = Node : inherit "atom",
                           symbol = Node : inherit "symbol",
                           number = Node : inherit "number" }
```

```lua
return Peg(micro_lisp_peg) : toGrammar(micro_lisp_metas)
```