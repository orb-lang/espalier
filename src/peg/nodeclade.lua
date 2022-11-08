





local Clade, Node = use ("cluster:clade", "espalier:peg/node")



local function postindex(tab, field)
   tab[field].tag = field
   return tab[field]
end



local contract = {postindex = postindex, seed_fn = true}








return Clade(Node, contract):extend(contract)

