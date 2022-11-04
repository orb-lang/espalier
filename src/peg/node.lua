






























































































































































local core = use "qor:core"
local table, string = core.table, core.string
local cluster, clade = use ("cluster:cluster", "cluster:clade")



















local function onmatch(first, t, last, str, offset)
   ---[[DBG]] assert(type(first) == 'number')
   ---[[DBG]] assert(type(t) == 'table')
   ---[[DBG]] assert(type(last) == 'number')
   ---[[DBG]] assert(type(str) == 'string')
   ---[[DBG]] assert(type(offset) == 'number')
   t.o = first + offset
   t.O = t.o
   t.stride = last - t.o - 1
   t.str = str
   for i, child in ipairs(t) do
      child.parent = t
      child.up = i
   end

   return t
end



local new, Node, Node_M = cluster.order { seed_fn = onmatch }








Node.v = 0









function Node.adjust(node)
   if node.v == 0 then
      return true
   end
   local root = node:root()
   if node.v == root.v then
      return true
   end
   -- now what
   --
   -- well. we make mutations, then we figure
   -- this part out.
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








local function _deep(node, depth)
   if node:isRoot() then
      return depth
   else
      return _deep(node.parent, depth + 1)
   end
end

function Node.depth(node)
   return _deep(node, 0)
end








function Node.isRoot(node)
   return not node.parent
end











local linepos = assert(string.linepos)

function Node.linepos(node)
   if node.v == 0 then
      return linepos(node.str, node.o)
   end
end


















function Node.root(node)
   return not node.parent
          and node
           or node.parent:root()
end













function Node.forward(node, right_side, short)
   if short and rawequal(node, short) then
      return node
   end
   if right_side or (#node == 0) then
      if node:isRoot() then
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











-- #Todo















local function walk(base, latest)
   if not latest then
      return base
   else
      local short = nil
      if not rawequal(base, latest) then
         short = base
      end
      local next = latest:forward(false, short)
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
   local latest;
   return function()
      local next = walk(node, latest)
      if next then
         latest = next
         return next
      else
         return nil
      end
   end
end

























local iscallable = assert(core.fn.iscallable)

local function predicator(pred, node)
   if type(pred) == 'string' then
      return node.tag == pred
   elseif iscallable(pred) then
      return not not pred(node)
   else
      error "invalid predicate"
   end
end










function Node.take(node, pred)
   for twig in walk, node do
      if predicator(pred, twig) then
         if twig ~= node then
            return twig
         end
      end
   end
   return nil
end

















function Node.filter(node, pred)
   local latest = nil
   return function()
      for twig in walk, node, latest do
         if predicator(pred, twig) then
            latest = twig
            return twig
         end
      end
      return nil
   end
end












local function searcher(pred, node, latest)
   if not latest then
      latest = node
   end

   local further = latest:forward()
   if further == node then
      further = further:forward()
   end
   if further == nil then return end

   if predicator(pred, further) then
      return further
   end

   return searcher(pred, node, further)
end



local curry = core.fn.curry

function Node.search(node, pred)
   return curry(searcher, pred), node
end




































local function adjust(node, v)
   -- parent version should always be >= child after updates
   if node.v < v then
      error ("node ." .. node.tag .. " has .v " .. node.v .. "< " .. v)
   end
   if node:isRoot() then
      return node.O - node.o, node.v
   end

   local skew, v = adjust(node.parent)
   if v > node.v then
      node.O = node.O + skew
      node.v = v
   end

   return node.O - node.o, v
end







local function update(node, Δ)
   repeat
      local parent = node.parent
      parent.v = parent.v + 1
      parent.stride = parent.stride + Δ
      for i = node.up + 1, #parent do
         local sib = parent[i]
         sib.v = sib.v + 1
         sib.O = sib.O + Δ
      end
   until parent:isRoot()
end
























function Node.hoist(node)
   if node:isRoot() then
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

