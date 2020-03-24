









local yield = assert(coroutine.yield, "uses coroutines")
local wrap = assert(coroutine.wrap)
local sub, find = assert(string.sub, "uses string"), assert(string.find)
local setmeta, getmeta = assert(setmetatable), assert(getmetatable)






local s = require "singletons" . status ()
local a = require "singletons/anterm"
local c_bw = require "singletons/color" . no_color
local core = require "core:core"
local Phrase = require "singletons/phrase"
local dot = require "espalier/dot"





   -- ergo
   --[[
   local html = require "espalier/html"
   local css  = require "espalier/css"
   local portal = require "espalier/portal"
   --]]









local Node = {}
Node.__index = Node
Node.isNode = Node
































function Node.toLua(node)
  s:halt("No toLua method for " .. node.id)
end




















function  Node.strTag(node, c)
   c = c or c_bw
   local phrase = Phrase ""
   phrase = phrase .. c.bold(node.id) .. "    "
      .. c.number(node.first) .. "-" .. c.number(node.last)
   return phrase
end










function Node.strExtra(node, c)
   return ""
end










local function _truncate(str, base_color, c)
   local phrase
   if #str > 56 then
       --  Truncate in the middle
       local pre, post = sub(str, 1, 26), sub(str, -26, -1)
       phrase = base_color(pre)
                     .. c.bold("………") .. base_color(post)
   else
       phrase = base_color(str)
   end
   return phrase
           : gsub("\n", "◼︎")
           : gsub("[ ]+", c.greyscale("_")
           .. base_color())
end

function Node.strLine(node, c)
   c = c or c_bw
   local phrase = Phrase ""
   phrase = phrase .. node:strTag(c)
   if node[1] then
      phrase = phrase .. " " .. node:strExtra(c) .. "   "
               .. _truncate(node:span(), c.greyscale, c) .. "\n"
   else
      local val = node.str:sub(node.first, node.last)
      phrase = phrase .. "    " .. _truncate(val, c.string,c)  .. "\n"
   end
   return phrase
end











function Node.toString(node, depth, c)
   depth = depth or 0
   local line =  node:strLine(c)
   local phrase = Phrase ""
   if tostring(line) ~= "" then
      phrase = phrase .. ("  "):rep(depth)
      phrase = phrase .. line
   end
   ---[[
   if node[1] then
      for _,v in ipairs(node) do
         if (v.isNode) then
            phrase = phrase .. v:toString(depth + 1, c)
         end
      end
   end
   --]]
   return phrase
end



local function __tostring(node)
   if not node.str then
      return "Node"
   end
   return tostring(node:toString())
end

Node.__tostring = __tostring






local lines = assert(core.lines)

local function __repr(node, phrase, c)
   local node__repr = tostring(node:toString(0, c))
   return lines(node__repr)
end

Node.__repr = __repr















function Node.span(node)
   return sub(node.str, node.first, node.last)
end









function Node.bounds(node)
   return node.first, node.last
end













function Node.len(node)
    return 1 + node.last - node.first
end





































function Node.gap(left, right)
  assert(left.last, "no left.last")
  assert(right.first, "no right.first")
  assert(right.last, "no right.last")
  assert(left.first, "no left.first")
  if left.first >= right.last then
    local left, right = right, left
  elseif left.last > right.first then
    s:halt("overlapping regions or str issue")
  end
  local gap = left - right - 1
  if gap >= 0 then
    return gap
  else
    s:halt("some kind of situation where gap is " .. tostring(gap))
  end

  return nil
end













function Node.dotLabel(node)
  return node.id
end










function Node.label(node)
   return node.id
end
















function Node.toMarkdown(node)
  if not node[1] then
    return sub(node.str, node.first, node.last)
  else
    s:halt("no toMarkdown for " .. node.id)
  end
end







function Node.dot(node)
  return dot.dot(node)
end










function Node.toValue(node)
  if node.__VALUE then
    return node.__VALUE
  end
  if node.str then
    return node.str:sub(node.first,node.last)
  else
    s:halt("no str on node " .. node.id)
  end
end













local function _root(node)
   if node.parent == node then
      return node
   end
   return _root(node.parent)
end

Node.root = _root








function Node.walkPost(node)
    local function traverse(ast)
        if not type(ast) == 'table' and ast.isNode then return nil end

        for _, v in ipairs(ast) do
            if type(v) == 'table' and v.isNode then
              traverse(v)
            end
        end
        yield(ast)
    end

    return wrap(function() traverse(node) end)
end








function Node.walk(node)
  local function traverse(ast)
    if not type(ast) == 'table' and ast.isNode then return nil end
    yield(ast)
    for _, v in ipairs(ast) do
      if type(v) == 'table' and v.isNode then
        traverse(v)
      end
    end
  end

  return wrap(function() traverse(node) end)
end



















function Node.coro_select(node, pred)
   local function qualifies(ast, pred)
      if type(pred) == 'string' then
         if type(ast) == 'table'
          and ast.id and ast.id == pred then
            return true
         else
            return false
         end
      elseif type(pred) == 'function' then
         return pred(ast)
      else
         s:halt("cannot select on predicate of type " .. type(pred))
      end
   end

   local function traverse(ast)
      -- breadth first
      if qualifies(ast, pred) then
         yield(ast)
      end
      if type(ast) == 'table' and ast.isNode then
         for _, v in ipairs(ast) do
            traverse(v)
         end
      end
   end

   return wrap(function() traverse(node) end)
end









local function qualifies(ast, pred)
    if type(pred) == 'string' then
       if type(ast) == 'table'
        and ast.id and ast.id == pred then
          return true
       else
          return false
       end
    elseif type(pred) == 'function' then
       return pred(ast)
    else
       s:halt("cannot select on predicate of type " .. type(pred))
    end
 end

local remove = assert(table.remove)

function Node.select(node, pred)
   -- build up all the nodes that match
   local matches = {}
   local function traverse(ast)
      -- depth-first, right to left
      if type(ast) == 'table' and ast.isNode then
         for i = #ast, 1, -1 do
            traverse(ast[i])
         end
      end
      if qualifies(ast, pred) then
         matches[#matches + 1] = ast
      end
   end
   traverse(node)
   return function()
      return remove(matches)
   end
end








function Node.tokens(node)
  local function traverse(ast)
    for node in Node.walk(ast) do
      if not node[1] then
        yield(node:toValue())
      end
    end
  end

  return wrap(function() traverse(node) end)
end









local lines = assert(core.lines)

function Node.lines(node)
  return lines(node:span())
end











function Node.linePos(node)
   local row, col = 0, 0
   local row_first, col_first, row_last, col_last
   local cursor, target = 0, node.first
   for line in lines(node.str) do
      row = row + 1
      ::start::
      if cursor + #line >= target then
         -- we have our row
         col = target - cursor
         if target == node.first then
            row_first, col_first = row, col
            target = node.last
            goto start
         else
            row_last, col_last = row, col
            break
         end
      else
         cursor = cursor + #line + 1 -- for newline
      end
   end
   if not row_last then return "no row_last", cursor end

   return row_first, col_first, row_last, col_last
end










function Node.lastLeaf(node)
  if #node == 0 then
    return node
  else
    return Node.lastLeaf(node[#node])
  end
end















function Node.gather(node, pred)
  local gathered = {}
  for ast in node:select(pred) do
    gathered[#gathered + 1] = ast
  end

  return gathered
end















local cloneinstance = assert(core.cloneinstance)

function Node.clone(node)
   return cloneinstance(node)
end









local function _pluck(node, str, offset, parent)
   local clone = setmetatable({}, getmetatable(node))
   parent = parent or clone
   for k, v in pairs(node) do
      if type(k) == "number" then
        clone[k] = _pluck(v, str, offset, clone)
      elseif k == "first" or k == "last" then
        clone[k] = v + offset
      elseif k == "parent" then
        clone.parent = parent
      else
        clone[k] = v
      end
   end
   clone.str = str
   return clone
end

function Node.pluck(node)
   local str = node:span()
   local offset = - node.first + 1
   local plucked = _pluck(node, str, offset)
--   assert(plucked.first == 1)
   return plucked
end




















































function Node.isValid(node)
  assert(node.isNode == Node, "isNode flag must be Node metatable, id: "
         .. node.id .. " " .. tostring(node))
  assert(node.first, "node must have first")
  assert(type(node.first) == "number", "node.first must be of type number")
  assert(node.last, "node must have last")
  assert(type(node.last) == "number", "node.last must be of type number")
  assert(node.str, "node must have str")
  assert(type(node.str) == "string"
         or node.str.isPhrase, "str must be string or phrase")
  assert(node.parent and node.parent.isNode == Node, "node must have parent")
  assert(type(node:span()) == "string", "span() must yield string")
  return true
end








function Node.validate(node)
  for twig in node:walk() do
    twig:isValid()
  end
  return true
end


















function Node.inherit(node, id)
  local Meta = setmeta({}, node)
  Meta.__index = Meta
  local _repr, _tostring = __repr, __tostring
  local node_M = getmetatable(node)
  if node_M then
    _repr = node_M.__repr
    _tostring = node_M.__tostring
  end
  Meta.__repr = _repr
  Meta.__tostring = _tostring
  if id then
    Meta.id = id
  end
  return Meta
end












function Node.export(_, mod, constructor)
  mod.__call = constructor
  return setmeta({}, mod)
end
































return Node
