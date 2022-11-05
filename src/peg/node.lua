






























































































































































local core = use "qor:core"
local table, string = core.table, core.string
local cluster, clade = use ("cluster:cluster", "cluster:clade")

local Pal = use "text:palimpsest2"



















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








Node.v = 1

























local function adjust(node, v)
   -- parent version should always be >= child after updates
   if node.v < v then
      error ("node ." .. node.tag .. " has .v " .. node.v .. "< " .. v)
   end
   if node:isRoot() then
      return node.O - node.o, node.v
   end

   local skew, v = adjust(node.parent, node.v)
   if v > node.v then
      node.O = node.O + skew
      node.v = v
   end

   return node.O - node.o, v
end



function Node.adjust(node)
   if node.v == 0 then return end
   adjust(node, node.v)
end
















function Node.straighten(node)
   if #node == 0 then return end

   local V, skew = node.v, node.O - node.o
   for _, child in ipairs(node) do
      if child.v < V then
         child.v = V
         child.O = child.O + skew
      elseif child.v > V then
         error("child version " .. child.v .. " > parent " .. V)
      end
   end
end











function Node.bounds(node)   node:adjust()
   return node.O, node.O + node.stride
end












local sub = assert(string.sub)

function Node.span(node)   node:adjust()
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











function Node.isConcrete(node) node:straighten()
   if #node == 0 then
      return true
   end
   if node.O < node[1].O or node.O > node[#node].O then
      -- node is wider than left/right child
      return false
   end
   if #node == 1 then
      return true
   end
   for i = 1, #node - 1 do
      local first, second = node[i], node[i] + 1
      local left, right = first.O + first.stride, second.O
      if right - left ~= 1 then
         return false
      end
   end

   return true
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











function Node:back(node, left_side)
   if node:isRoot() then return nil end

   if left_side then
      return node.parent
   end
   -- later...

end















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









Node.filterer = Node.filter












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













































































local function thePalimpsest(node)
   if type(node.str) == 'table' then
      return node.str
   end
   if node:isRoot() then
      node.str = Pal(node.str)
      -- bump to v1 if we have to
      if node.v == 0 then
         for twig in node :walk() do
            assert(twig.v == 0, "some node was already editable?")
            twig.v = 1
         end
      end
      return node.str
   end
   local pal = thePalimpsest(node.parent)
   node.str = pal

   return pal
end













local function update(node, Δ)
   node.v = node.v + 1
   repeat
      local up = node.up
      node = node.parent
      node.v = node.v + 1
      node.stride = node.stride + Δ
      for i = up + 1, #node do
         local sib = node[i]
         sib.v = sib.v + 1
         sib.O = sib.O + Δ
      end
   until node:isRoot()
end

























local function removeNode(node) -- :span will adjust for us
   local span = node:span()
   local pal = thePalimpsest(node)
   pal:patch("", node:bounds())
   update(node, -node:len())
   local top = #node.parent
   for i = node.up, top - 1 do
      node.parent[i] = node.parent[i + 1]
      node.parent[i].up = i
   end
   node.parent[top] = nil
   node.parent, node.up = nil, nil
   node.unready = true
   return node, span
end





function Node.snip(node)
   local node, span = removeNode(node)
   local offset = 1 - node.O
   for twig in node:walk() do
      twig.v = 1
      twig.str = span
      twig.o = twig.O + offset
      twig.O = twig.o
   end
   node.unready = nil
   return node
end










local floor = math.floor

function Node.graft(node, child, i)
   assert(type(i) == 'number' and i > 0 and floor(i) == i,
          "i must be a positive integer")
   if i > #node + 1 then
      error("Node has " .. #node .. " children, can't insert at " .. i)
   end
   local _, cut;
   if node[i] then
      cut = node[i]:bounds()
   else
      _, cut = node[#node]:bounds()
   end
   local span = child:span()

   local pal = thePalimpsest(node)
   pal:patch(span, cut)
   update(node, #span)
   local top = #node
   local this = child
   for j = i, top + 1 do
      this.up = j
      local sib = node[j]
      node[j] = this
      this = sib
   end
   child.v = node.v
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









local tablib = require "repr:tablib"
local yieldName = assert(tablib.yieldName)
local yieldReprs = assert(tablib.yieldReprs)
local yieldToken = assert(tablib.yieldToken)
local concat = assert(table.concat)

local function blurb(node, w, c)
   if not node.span then return end
   local span = node:span()
   local phrase = {c.metatable(node.tag)}
   insert(phrase, ": ")
   insert(phrase, c.string(span))
   return concat(phrase)
end



local Lens = use "repr:lens"
local Set = core.set

local suppress = Set {
   'parent',
   'up',
   'str',
   --'o', 'O', 'v', 'stride',
}
local lens = { hide_key = suppress,
               blurb = blurb,
               depth = math.huge }
Node_M.__repr = Lens(lens)





return new

