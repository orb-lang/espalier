# Microlisp


A declarative PEG parser for a Platonic sexpr language.

```lua
local Grammar = require "espalier/grammar"
```
## micro_lisp_peg

```lua
local micro_lisp_peg = [[
lisp = (_atom_)+ / list
list = pel _ (atom / list)* per _
atom = _(alpha / other) (alpha / digit / other)*_
`pel` = '('
`per` = ')'
`alpha` = [A-Z]/[a-z]
`digit` = [0-9]
`other` = {-_-=+!@#$%^&*:/?.\\~}
  _     = { \t\n,}*
]]
```
```lua
return micro_lisp_peg
```
