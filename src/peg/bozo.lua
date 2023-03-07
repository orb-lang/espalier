









local V, bozo = {}, {}
V.bozo = bozo



local function Bozo(node)
   local the_bozo = true
   for i, child in ipairs(node) do
      the_bozo = the_bozo and child:bozo()
   end
   return the_bozo
end



function bozo.grammar(grammar)
   local bozz = true
   for _, child in ipairs(grammar) do
      bozz = bozz and child:bozo()
   end
   if bozz then
      grammar.the_bozo = "bozo!"
   end
end



bozo[1] = Bozo




























return V

