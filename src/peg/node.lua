
























































































































local core = use "qor:core"
local cluster, clade = use ("cluster:cluster", "cluster:clade")














local new, Node, Node_M = cluster.order {
   seed_fn = function(first, t, last, str, offset)
      assert(type(first) == 'number')
      assert(type(t) == 'table')
      assert(type(last) == 'number')
      assert(type(str) == 'string')
      t.v = 0
      t.o = first
      t.O = first
      t.stride = last - first
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
   end, }












function Node.adjust(node)
   if node.v == 0 then
      return true
   end
end









local sub = assert(string.sub)

function Node.span(node)
   if node.v == 0 then
      -- means we don't have to use a method to look at the string
      return sub(node.str, node.o, node.o + node.stride)
   end
   -- the fun part
   node:adjust()
end






function Node.bounds(node)  node:adjust()
   return node.O, node.O + node.stride
end






function Node.len(node)  node:adjust()
   return node.stride + 1
end









function Node.forward(node, done)
   if done or (#node == 0) then
      local sibling = node.parent[node.up + 1]
      if sibling then
         return sibling
      else
         -- right-most child returned
         return node.parent:forward(true)
      end
   end
   return node[1]:forward()
end















local utf8 = require "lua-utf8"

function Node.width(node) node:adjust()
   local wid = 0
   local first, last, str = node.o, node.o

end









local Lens = use "repr:lens"
local Set = core.set

local suppress, show = Set {
   'parent',
   'up'
}, Set {
   'tag'
}
local lens = { hide_key = suppress,
               show_key = show,
               depth = math.huge }
Node_M.__repr = Lens(lens)






return new

