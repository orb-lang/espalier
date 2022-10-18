






















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






local insert = assert(table.insert)

local function walker()
   local eDji = eVav.dji or dji()
   local one2 = eDji [[ (1 2) ]]
   local tags = {}
   for node in one2:walk() do
      insert(tags, node.tag)
   end
   return tags
end



local function subwalker()
   local eDji = eVav.dji or dji()
   local walk3 = eDji [[ ( (1 two 3) (4 5))]]
   local tags = {}
   for node in walk3[1][1]:walk() do
      insert(tags, node.tag)
   end
   return tags, walk3[1][1]
end




return { eVav = eVav,
         Elden = Elden,
         walker = walker,
         subwalker = subwalker,
         dji = dji }





end) ()

