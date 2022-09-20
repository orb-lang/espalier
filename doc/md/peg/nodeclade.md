# Node Clade

```lua
local Clade, Node = use ("cluster:clade", "espalier:peg/node")
```

```lua
local function onindex(tab, field)
   tab.tag = field
   return tab
end
```

```lua
return Clade(Node, onindex)
```
