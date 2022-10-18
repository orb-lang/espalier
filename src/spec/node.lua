






















return (function()











local elden_peh = [[
    elden  ←  _ ((atom)+ / list)
     list  ←  pel _ (atom / list)* per _
     atom  ←  _(number / symbol)_
   symbol  ←  _ sym1 sym2*
   `sym1`  ←  (alpha / other)
   `sym2`  ←  (alpha / digit / other)
   number  ←  float / integer
`integer`  ←  [0-9]+
  `float`  ←  [0-9]+ "." [0-9]+ ; expand
    `pel`  ←  '('
    `per`  ←  ')'
  `alpha`  ←  [A-Z]/[a-z]
  `digit`  ←  [0-9]
  `other`  ←  {-_-=+!@#$%^&*:/?.\\~}
      `_`  ←  { \t\r\n,}*
]]
















local Vav = use "espalier:vav"





local eVav = Vav(elden_peh)













local Elden = require "espalier:peg/nodeclade"









local function dji()
   return eVav:Mem(Elden):Dji()
end



return { eVav = eVav,
         Elden = Elden,
         dji = dji }





end) ()

