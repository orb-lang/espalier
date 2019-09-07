





local Grammar = require "espalier/grammar"






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



return micro_lisp_peg
