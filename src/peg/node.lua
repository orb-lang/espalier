
























































































































local core = use "qor:core"
local cluster, clade = use ("cluster:cluster", "cluster:clade")











local function onmatch(first, t, last, str, offset)
   --[[DBG]] --[[
   assert(type(first) == 'number')
   assert(type(t) == 'table')
   assert(type(last) == 'number')
   assert(type(str) == 'string')
   assert(type(offset) == 'number')
   --[[DBG]]
   t.v = 0
   t.o = first + offset
   t.O = t.o
   t.stride = last - first + offset
   t.str = str
   if not t.parent then
      -- root is self, not null
      t.parent = t
      -- since t.parent[t.up] == t, we do this:
      t.up = 'parent'
   end
   -- we used to 'drop' invalid data which snuck in here,
   -- that should no longer be necessary
   for i, child in ipairs(t) do
      child.parent = t
      child.up = i
   end

   return t
end



local new, Node, Node_M = cluster.order { seed_fn = onmatch }












function Node.adjust(node)
   if node.v == 0 then
      return true
   end
end











function Node.bounds(node)  node:adjust()
   return node.O, node.O + node.stride
end












local sub = assert(string.sub)

function Node.span(node)
   if node.v == 0 then
      -- means we don't have to use a method to look at the string
      return sub(node.str, node.o, node.o + node.stride)
   end
   -- the fun part
   node:adjust()
   if string(node.str) then
      -- we're within a single string, small o
      return sub(node.str, node.o, node.o + node.stride)
   else
      -- palimpsest, big O
      return node.str:sub(node.O, node.O + node.stride)
   end
end














function Node.len(node)
   return node.stride + 1
end
























function Node.forward(node, done, short)
   if short and rawequal(node, short) then
      return node
   end
   if done or (#node == 0) then
      if node.parent == node then
         return nil
      end
      local sibling = node.parent[node.up + 1]
      if sibling then
         return sibling
      else
         -- right-most child returned
         return node.parent:forward(true, short)
      end
   end
   return node[1]
end











local function walk(base, last)
   if not last then
      return base
   else
      local short = nil
      if not rawequal(base, last) then
         short = base
      end
      local next = last:forward(false, short)
      if rawequal(base, next) then
         return nil
      else
         return next
      end
   end
end





function Node.walk(node)
   return walk, node
end












function Node.walker(node)
   local last;
   return function()
      local next = walk(node, last)
      if next then
         last = next
         return next
      else
         return nil
      end
   end
end
















local iscallable = assert(core.fn.iscallable)

local function predicator(node, pred)
   return (
      type(pred) == 'string'
      and (node.tag == pred)

      or iscallable(pred)
      and (not not pred(node))

      or false )
end










function Node.take(node, pred)
   for twig in walk, node do
      if predicator(twig, pred) then
         if twig ~= node then
            return twig
         end
      end
   end
   return nil
end










function Node.hoist(node)
   if node.parent == node then
      return nil, "can't hoist root node"
   end
   if #node ~= 1 then
      return nil, "can only hoist a node with one child"
   end
   node.parent[node.up] = node[1]
   return true
end















local utf8 = require "lua-utf8"
local width = assert(utf8.width)

function Node.width(node) node:adjust()
   local wid = 0
   local first, last, str = node.o, node.o

end









local Lens = use "repr:lens"
local Set = core.set

local suppress, show = Set {
   'parent',
   --'up'
}, Set {
   'tag'
}
local lens = { hide_key = suppress,
               show_key = show,
               depth = math.huge }
Node_M.__repr = Lens(lens)





return new

