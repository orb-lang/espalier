














































































































local core = use "qor:core"
local cluster, clade = use ("cluster:cluster", "cluster:clade")



local new, Node, Node_M = cluster.order()







cluster.construct(new, function(_new, id, t, first, last, str)
   t.v = 0
   t.o = first
   t.O = first
   t.stride = first - last
   t.str = str
   if not t.parent then
      -- root is self, not null
      t.parent = t
      t.up = 0
   end
   -- we used to 'drop' invalid data which snuck in here,
   -- that should no longer be necessary
   for i, child in ipairs(t) do
      child.parent = t
      child.up = i
   end
   return t
end)











local sub = assert(string.sub)

function Node.span(node)
   if node.v == 0 then
      -- all is well
      return sub(node.str, node.o, node.o + node.stride)
   else
      -- the fun part
   end
end

