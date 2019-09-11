





local Grammar = require "espalier/grammar"






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
  _     = { \t\n,}*
]]



return micro_lisp_peg
