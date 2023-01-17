






















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









local eDji = eVav:Mem(Elden):Dji()

local function dji()
   return eDji
end






local pegpeg = use "espalier:peg/pegpeg"
local mem = use "espalier:peg/mem"

local function vav()
   return Vav(pegpeg, mem)
end






local insert = assert(table.insert)

local function walker()
   local one2 = eDji [[ (1 2) ]]
   local tags = {}
   for node in one2:walk() do
      insert(tags, node.tag)
   end
   return tags
end



local function subwalker()
   local walk3 = eDji [[ ( (1 two 3) (4 5))]]
   local tags = {}
   for node in walk3[1][1]:walk() do
      insert(tags, node.tag)
   end
   return tags, walk3[1][1]
end






local function searcher()
   local find_syms = eDji [[ ((1 (2 three 4) five (7 seven)))]]
   local sym1 = find_syms :take 'symbol'
   assert(sym1:span() == 'three', "expected a symbol 'three'")
   local spans = {}
   for match in sym1:search 'symbol' do
      insert(spans, match:span())
   end

   return spans
end



local function filterer()
   local twos = eDji [[((1 2 3) (2 (2 (3))) (3 (4 (2))))]]
   local function isTwo(twig)
      return twig:span() == "2"
   end
   local spans = {}
   for twig in twos :filter(isTwo) do
      insert(spans, twig:span())
   end
   return #spans, spans
end






local lua_peh = use "scry:lua-peg"

local function lvav()
   local Dji = vav():Dji()
   return Dji(lua_peh)
end




return { eVav = eVav,
         Elden = Elden,
         walker = walker,
         subwalker = subwalker,
         searcher = searcher,
         filterer = filterer,
         dji = dji,
         pegpeg = pegpeg,
         lua_peh = lua_peh,
         vav = vav,
         lvav = lvav, }





end) ()

