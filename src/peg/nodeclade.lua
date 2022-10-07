





local Clade, Node = use ("cluster:clade", "espalier:peg/node")



local function postindex(tab, field)
   tab[field].tag = field
   return tab[field]
end



return Clade(Node, postindex)

