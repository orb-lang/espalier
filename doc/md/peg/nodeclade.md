# Node Clade

This is Mem, as it turns out\.


```lua
local Clade, Node = use ("cluster:clade", "espalier:peg/node")
```

```lua
local function postindex(tab, field)
   tab[field].tag = field
   return tab[field]
end
```

```lua
return Clade(Node, {postindex = postindex, seed_fn = true})
```
