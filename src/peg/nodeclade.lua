


local Clade, Node = use ("cluster:clade", "espalier:peg/node")



local function onindex(tab, field)
   tab.tag = field
   return tab
end



return Clade(Node, onindex)

