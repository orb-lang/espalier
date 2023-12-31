









local yield = assert(coroutine.yield, "uses coroutines")
local wrap = assert(coroutine.wrap)
local sub, find = assert(string.sub, "uses string"), assert(string.find)
local setmeta, getmeta = assert(setmetatable), assert(getmetatable)






local s = require "status:status" ()
local a = require "anterm:anterm"
local c_bw = require "singletons/color" . no_color
local core = require "core:core"
--local Phrase = require "singletons/phrase"
local dot = require "espalier/dot"




















local Node = {}
Node.__index = Node
Node.isNode = Node





























Node.super = core.super














function Node.bustCache(node)
   return
end












function Node.toLua(node)
  s:halt("No toLua method for " .. node.id)
end




















function  Node.strTag(node, c)
   c = c or c_bw
   return c.bold(node.id) .. "    "
      .. c.number(node.first) .. "-" .. c.number(node.last)
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
           : gsub("[ ]+", c.greyscale("␣")
           .. base_color())
end

function Node.strLine(node, c)
   c = c or c_bw
   local phrase =  ""
   phrase = phrase .. node:strTag(c)
   if node[1] then
      phrase = phrase .. " " .. node:strExtra(c) .. "   "
               .. _truncate(node:span(), c.greyscale, c) .. "\n"
   else
      local val = node.str:sub(node.first, node.last)
      phrase = phrase .. "    " .. _truncate(val, c.string, c)  .. "\n"
   end
   return phrase
end











function Node.toString(node, depth, c)
   depth = depth or 0
   local line =  node:strLine(c)
   local phrase = ""
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









function Node.selectFrom(node, pred, index)
   index = index or node.last
   assert(type(index) == 'number', "index must be a number")
   -- build up all the nodes that match
   local matches = {}

   local function traverse(ast)
      -- depth-first, right to left
      for i = #ast, 1, -1 do
        if ast[i].last >= index then
            traverse(ast[i])
        end
      end
      if ast.first > index and qualifies(ast, pred) then
         matches[#matches + 1] = ast
      end
   end

   traverse(node:root())

   return function()
      return remove(matches)
   end
end










function Node.selectBack(node, pred)
   -- reject any node after this
   local boundary = node.first
   -- set up a function which moonwalks the tree
   local function moonwalk(ast)
      -- depth first, right to left, starting with peers of the node
      for i = #ast, 1, -1 do
         local suspect = ast[i]
         -- don't check anything if ast[i].first >= boundary
         if suspect.first < boundary then
            -- candidate
            moonwalk(suspect)
         end
      end
      if ast.first < boundary and qualifies(ast, pred) then
         yield(ast)
      end
   end
   return wrap(function() return moonwalk(node:root()) end)
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






























local _nl_map = setmetatable({}, { __mode = 'kv' })
local findall = assert(require "core:core/string".findall)

local function _findPos(nl_map, target, start)
   local line = start or 1
   local cursor = 0
   local col
   while true do
      if line > #nl_map then
         -- technically two possibilities: node.last is after the
         -- end of node.str, or it's on a final line with no newline.
         -- the former would be quite exceptional, so we assume the latter
         -- here.
         -- so we need the old cursor back:
         cursor = nl_map[line - 1][1] + 1
         return line, target - cursor + 1
      end
      local next_nl = nl_map[line][1]
      if target > next_nl then
         -- advance
         cursor = next_nl + 1
         line = line + 1
      else
         return line, target - cursor + 1
      end
   end
end

function Node.linePos(node)
   local nl_map
   if _nl_map[node.str] then
      nl_map = _nl_map[node.str]
   else
      nl_map = findall(node.str, "\n")
      _nl_map[node.str] = nl_map
   end
   if not nl_map then
      -- there are no newlines:
      return 1, node.first, 1, node.last
   end
   -- otherwise find the offsets
   local line_first, col_first = _findPos(nl_map, node.first)
   local line_last, col_last = _findPos(nl_map, node.last, line_first)
   return line_first, col_first, line_last, col_last
end










local function _lastLeaf(node)
  if #node == 0 then
    return node
  else
    return _lastLeaf(node[#node])
  end
end

Node.lastLeaf = _lastLeaf















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




































local inbounds = assert(require "core:math" . inbounds)
local insert = assert(table.insert)

local function _offsetBy(node, str, offset, dupes)
   if dupes[node] then return end
   node.str = str
   node.first = node.first + offset
   node.last = node.last + offset
   dupes[node] = true
   node:bustCache()
   for i = 1, #node do
      _offsetBy(node[i], str, offset, dupes)
   end
end

local function _applyGraft(node, branch, index, insertion, replace)
   local branch = cloneinstance(branch)
   if replace then
      assert(node[insertion].first == index,
             "illegal replacement: index is " .. index .. " but first of "
             .. node.id .. ", '" .. node:span() .. "', is " .. node.first)
   end
   -- create new string
   local str = ""
   if replace then
      str = sub(node.str, 1, index - 1)
            .. branch.str .. sub(node.str, node[insertion].last + 1)
   else
      str = sub(node.str, 1, index - 1) .. branch.str .. sub(node.str, index)
   end
   -- calculate offset for first and last adjustment
   local offset
   if replace then
      -- difference between new span and old (could be negative)
      local old_span = node[insertion].last - node[insertion].first + 1
      offset = #branch.str - old_span
   else
      offset = #branch.str
   end
   -- avoid offsetting nodes more than once by keeping a dupes collection:
   local dupes = {}

   -- offset the branch clone to the new index
   _offsetBy(branch, str, index - 1, dupes)
   -- now graft
   branch.parent = node
   if replace then
      node[insertion] = branch
   else
      insert(node, insertion, branch)
   end
   -- - all parents must be adjusted on .last += offset
   -- - all left peers of any parent get strings replaced, no adjustment
   -- - any right peers of any parent must be adjusted by offset
   local walking = true
   local parent = node
   local child = node[insertion]
   repeat
      if parent.parent == parent then
         -- this is the root
         walking = false
      end
      dupes[parent] = true
      parent.last = parent.last + offset
      parent.str = str
      local on_left = true
      for i, sibling in ipairs(parent) do
         if on_left and sibling ~= child then
            -- (only) replace the string
            _offsetBy(sibling, str, 0, dupes)
         elseif sibling == child then
            on_left = false
          -- we've offset this already
         else
            _offsetBy(sibling, str, offset, dupes)
         end
      end
      child = parent
      parent = parent.parent
   until not walking

end

local function graft(node, branch, index, replace)
   assert(type(index) == 'number', "index must be a number")
   if #node == 0 then
     -- we can't graft onto a token
     local line, col = node:linePos()
     error("can't graft in the middle of token " .. node.id
           .. "at line: " .. line .. ", col: " .. col .. ", index: " .. index)
   end
   -- search for a graft point at index
   -- we can graft anywhere between node.first and node[1].first:
   if inbounds(index, node.first, node[1].first) then
      return _applyGraft(node, branch, index, 1, replace)
   -- same for node[#node].last + 1 and node.last + 1:
   elseif inbounds(index, node[#node].last + 1, node.last + 1) then
      return _applyGraft(node, branch, index, #node + 1, replace)
   end
   -- we either find a gap, or a sub-node we should search through.
   -- first we look for gaps:
   for i = 2, #node do
      if inbounds(index, node[i - 1].last + 1, node[i].first) then
         return _applyGraft(node, branch, index, i, replace)
      end
   end
   -- now, check for compatible subnodes:
   for _, twig in ipairs(node) do
     if inbounds(index, twig.first + 1, twig.last) then
        return graft(twig, branch, index, replace)
     end
   end
   -- here we're just stuck: bad index is likely
   error("unable to graft " .. branch.id .. " onto " .. node.id
         .. "'" .. node:span().. "'" .. " at index " .. index
         .. ". #node.str == " .. #node.str)
end

function Node.graft(node, branch, index)
   return graft(node, branch, index)
end















function Node.replace(node, branch, index)
   return graft(node, branch, index, true)
end














function Node.isValid(node)
  assert(node.id, "node must have an id")
  assert(node.isNode == Node, "isNode flag must be Node metatable, id: "
         .. node.id .. " " .. tostring(node))
  assert(node.first, "node must have first")
  assert(type(node.first) == "number", "node.first must be of type number")
  assert(node.last, "node must have last")
  assert(type(node.last) == "number", "node.last must be of type number")
  assert(node.str, "node must have str")
  assert(type(node.str) == "string"
         or node.str.isPhrase, "str must be string or phrase")
  assert(getmetatable(node), "node must have a metatable: " .. node.id)
  assert(node.parent and node.parent.isNode == Node,
         "node must have parent: " .. node.id)
  assert(type(node:span()) == "string", "span() must yield string")
  return true
end








local function _validate(node)
   node:isValid()
   for _, twig in ipairs(node) do
      assert(twig.parent == node, "illegal parent " .. twig.parent.id
             .. " should be a " .. node.id)
      _validate(twig)
   end
   return true
end
Node.validate = _validate










local function _isCompact(node, breaks)
   local is_compact = true
   local subCompact
   if #node > 0 then
      -- node.first must match first of subnode
      local first_match = node.first == node[1].first
      if not first_match then
        -- register the 'break'
        local line, col = node:linePos()
        insert(breaks.pre, {node.id, node[1].first - node.first,
                            line, col,
                            node.str:sub(node.first, node[1].first - 1)})
      end
      is_compact = is_compact and first_match
      for i = 2, #node do
        -- check gap between subNodes
        local left, right = node[i-1].last, node[i].first
        local inter_match = left == right - 1
        if not inter_match then
           local _, __, line, col =  node[i-1]:linePos()
           insert(breaks.inter, {node[i-1].id, i, node[i].id,
                                 right - left - 1, line, col + 1,
                                 node.str:sub(left + 1, right - 1)})
        end
        is_compact = is_compact and inter_match
        -- run isCompact recursively
        subCompact = _isCompact(node[i-1], breaks)
        is_compact = is_compact and subCompact
      end
      -- test last node
      subCompact = _isCompact(node[#node], breaks)
      is_compact = is_compact and subCompact
      -- node.last must match last of subnode
      local last_match = node.last == node[#node].last
      if not last_match then
        local _, __, line, col = node[#node]:linePos()
        insert(breaks.post, {node.id, node.last - node[#node].last,
                             line, col + 1,
                             node.str:sub(node[#node].last + 1, node.last)})
      end
      is_compact = is_compact and last_match
   end
   return is_compact
end

function Node.isCompact(node)
   local breaks = { pre = {}, inter = {}, post = {} }
   local is_compact = _isCompact(node, breaks)
   return is_compact, breaks
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

