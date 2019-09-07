





local Grammar = require "espalier/grammar"






local micro_lisp_peg = [[
lisp = (_atom_)+ / list
list = pel _ (atom_ / list_)* per
atom = (alpha / other) (alpha / digit / other)*
`pel` = '('
`per` = ')'
`alpha` = [A-Z]/[a-z]
`digit` = [0-9]
`other` = {-_-=+!@#$%^&*:/?.\\~}
  _     = { \t\n,}*
]]



return micro_lisp_peg
