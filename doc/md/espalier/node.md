# Node


  The Node class implements an abstract syntax tree, in collaboration with
the [Grammar class](~/grammar.orb) and lpeg more generally\.


### \[ \] Use cluster\.clade

Nodes are used in a fashion which the `clade` protocol in cluster is intended
for\.

Since I have yet to begin implementing it, that's about as much note as I
feel the need for, right this very instant\.


#### asserts

```lua
local yield = assert(coroutine.yield, "uses coroutines")
local wrap = assert(coroutine.wrap)
--local sub, find = assert(string.sub, "uses string"), assert(string.find)
local setmeta, getmeta = assert(setmetatable), assert(getmetatable)
```


#### requires

```lua
local s = require "status:status" ()
local a = require "anterm:anterm"
local c_bw = require "singletons/color" . no_color
local core = require "core:core"
--local Phrase = require "singletons/phrase"
local dot = require "espalier/dot"
```


- [ ] \#todo Planned expansions:

```lua
local html = require "espalier/html"
local css  = require "espalier/css"
local portal = require "espalier/portal"
```


## Node metatable

  The Node metatable is the root table for any Node, all of which should
subclass through [Node:inherit()](hts://~/node#node:inherit())\.

```lua
local Node = {}
Node.__index = Node
Node.isNode = Node
```

we would now say `local Node = meta {}`\.

The `isNode` is a quirk of the `Node` arcy, being distinct from `idEst` for
orthogonality\.


## Fields

   - id :  A string naming the Node\.
       This is identical to the name of the pattern that recognizes
       or captures it\.

       This is never set on Node itself, and Grammar will fail to
       produce a Node which lacks this flag\.

   - isNode :  A boolean, always `true`/truthy\.


## Methods


### Node:bustCache\(\)

The root Node class doesn't cache derived values but derived classes might\.

`:linePos` caches the map of newlines, but it keys off `node.str`, which is
changed by grafting, so no action is required in that case\.

We provide this method so that `graft` can call it\. Specifically because the
Orb Twig class does cache calls to `:select`, and we need to remove those\.

```lua
function Node.bustCache(node)
   return
end
```


#### toLua

This is not a general method in any sense, it's here as a backstop
while I build out Clu\.

I'm going to call it an important root method: it says, in plain English,
that a bare Node cannot be simply converted to Lua\.

```lua
function Node.toLua(node)
  s:halt("No toLua method for " .. node.id)
end
```


## Visualizer

This gives us a nice, tree\-shaped printout of an entire Node\.

We're less disciplined than we should be about up\-assigning this to
inherited Node classes\.

\#todo


#### Node:strTag\(c\)

Returns a string which prints the id and first\-last range of the Node\.

`c` is a color table, defaulting to no color\.

```lua
function Node.strTag(node, c)
   c = c or c_bw
   return c.bold(node.id) .. "    "
      .. c.number(node.first) .. "-" .. c.number(node.last)
end
```


#### Node:strExtra\(c\)

A placeholder for inserting extra information about a Node subclass\.

The base class merely returns `""`\.

```lua
function Node.strExtra(node, c)
   return ""
end
```


#### Node:strLine\(c\)

Returns a Phrase containing a single line of Node information\.

`c` is a color table and default to no color\.

```lua
local function _truncate(str, base_color, c)
   local phrase;

   if #str > 56 then
       --  Truncate in the middle
       local pre, post = str:sub(1, 26), str:sub(-26, -1)
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
```


### Node:toString\(depth, c\)

Recursively calls `node:strLine(c)` and returns an indented Phrase visualizing
the entire Node tree\.

`depth` defaults to 0, `c` is a color table defaulting to black and white\.

```lua
function Node.toString(node, depth, c, limit)
   depth = depth or 0
   if limit and depth >= limit then
      return ""
   end
   local line =  node:strLine(c)
   local phrase = ""
   if tostring(line) ~= "" then
      phrase = phrase .. ("  "):rep(depth)
      phrase = phrase .. line
   end
   for _, twig in ipairs(node) do
      if (twig.isNode) then
         phrase = phrase .. twig:toString(depth + 1, c, limit)
      end
   end
   return phrase
end
```

```lua
local function __tostring(node)
   if not node.str then
      return "Node"
   end
   return tostring(node:toString())
end

Node.__tostring = __tostring
```


### Node\_\_repr

```lua
local lines = assert(core.lines)

local function __repr(node, phrase, c)
   local node__repr = tostring(node:toString(0, c))
   return lines(node__repr)
end

Node.__repr = __repr
```


## Metrics

These retrieve various general properties of the Node\.

The focus has been on correctness over speed\.


#### node:span\(\)

`node:span()` returns a substring across the span of the Node\.

```lua
function Node.span(node)
   return node.str:sub(node.first, node.last)
end
```


#### node:bounds\(\)

Returns `node.first` and `node.last`, such that
`string.sub(node.str, node:bounds())` is equal to `node:span()`\.

```lua
function Node.bounds(node)
   return node.first, node.last
end
```


#### node:len\(\)

ahh, the pleasure of indexing by one\.

`node:len()` gives the length of the node; we can't use `#node` because
`node[#node]` is the pragmatic way to access the rightmost child\.

hmm\.

```lua
function Node.len(node)
    return 1 + node.last - node.first
end
```

Hence

```lun
fn Node.len(node)
   -> @last - @first
end
```


#### Node:gap\(node\)

\#NB


- [ ] \#todo either use this, validate it, or get rid of it

    \[ \]  validate\.  Validate and use\.  that sounds right

`Node.gap(left, right)` compares the `last` field of the `left` parameter
with the `first` field of the `right` parameter, **if** this is greater than
0\.

If it is negative, `Node.gap` attempts to measure the `first` field of the
`right` parameter against the `last` field of the `left` parameter\.

If this is a natural number we return the **negation** of this value\.  If both
should prove to be positive, we halt\.

No effort is made to check that the `str` field matches between nodes unless
we have an error, in which case it could prove helpful for diagnosis\.

Indeed such a check would be a disaster in streams or other sort of
piecewise parse\.  Which will require implementation in and of itself, but
in the meantime\.\.\.

```lua
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
```


#### node:dotLabel\(\)

This provides a label for dot files\.

Perhaps over\-specialized\.  We might prefer a `node:label()` for generality
and call it when constructing labile trees\.

```lua
function Node.dotLabel(node)
  return node.id
end
```


#### node:label\(\)

A synonym, then\. But a heritable one, you see\.

`id` being generic, and genre being all we have at the root:

```lua
function Node.label(node)
   return node.id
end
```


### Backstops

The backstops prevent malformed parsing of some key format transitions\.

They also provide a paradigm for writing more of same for language\-specific
cases\.


#### node:toMarkdown\(\)

This provides a literal string if called on a leaf node and otherwise halts\.

```lua
function Node.toMarkdown(node)
  if not node[1] then
    return sub(node.str, node.first, node.last)
  else
    s:halt("no toMarkdown for " .. node.id)
  end
end
```

### node:dot\(node\)

Generates a entire `dot` node\.

```lua
function Node.dot(node)
  return dot.dot(node)
end
```


### node:toValue\(\)

Sometimes you want the value of a Node\.

So you call this:

```lua
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
```


## Traversal

Methods to move around inside a Node\.


#### Node:root\(\)

Returns the root of a given Node tree structure\.

```lua
local function _root(node)
   if node.parent == node then
      return node
   end
   return _root(node.parent)
end

Node.root = _root
```


#### Node:next\(pred?\), Node:prev\(pred?\)

These rather essential primitives to add this late\!

Starting with the one I need most which is :next\(pred\), in the cheapest
possible implementation in terms of thought and typing\.

Currently these have misleading semantics: they should return the next
predicate match, no excuses, and instead they select in the subframe\.

The plan is to replace all uses of `:next` with `:take`, which will implement
the same \(useful\!\) semantic \(but optimally\), and then rewrite these\.


```lua
function Node.next(node, pred)
   assert(pred, ':next needs a predicate at the moment')
   return node:select(pred)()
end
```


#### Node\.walkPost

Depth\-first iterator, postfix

```lua
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
```


#### Node:walkBreadth\(\) \-> \( \): Node, integer, index

  Returns a breadth\-first iterator, recursively returning all child Nodes, the
stack depth, and the index against the parent yielding this Node\.

This doesn't return the Node itself\.

```lua
function Node.walkBreadth(node)
   local function traverse(ast, depth)
      for i = 1, #ast do
         yield(ast[i], depth, i)
      end
      for j= 1, #ast do
         traverse(ast[j], depth + 1)
      end
   end

   return wrap(function() traverse(node, 1) end)
end
```


#### Node\.walk

Presearch iterator\.  This is the default\.

```lua
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

```


## Selection

We are frequently in search of a subset of Nodes:


#### Node:select\(pred\)

  Takes the Node and walks it, yielding the Nodes which match the predicate\.
`pred` is either a string, which matches to `id`, or a function, which takes
a Node and returns true or false on some premise\.

Stubbed out, because it can cause the interpreter to throw a spurious error\.

Which is\.\.\. bad\.

Note that we would prefer to use this one, because the closed\-over version
walks the entire tree, which isn't always necessary\.

```lua
local function _qualifies(ast, pred)
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

function Node.select(node, pred)
   local function traverse(ast)
      -- breadth first
      if _qualifies(ast, pred) then
         yield(ast)
      end
      if type(ast) == 'table' and ast.isNode then
         for i = 1, #ast do
            traverse(ast[i])
         end
      end
   end

   return wrap(function() traverse(node) end)
end
```


#### Node:\_select\(pred\)

This version uses a closure instead of a coroutine, to get around a crashing
problem we've been having in bridge\.


```lua
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
```


### Node:take\(pred\)

Returns only the first match for the predicate within the Node, which may
include the node itself\.

```lua
local function _take(node, pred)
   if qualifies(node, pred) then
      return node
   end
   for _, twig in ipairs(node) do
      local took = _take(twig, pred)
      if took then
         return took
      end
   end
   return nil
end

Node.take = _take
```


#### Node:selectFrom\(pred, index\)

    Selects on the predicate, returning any matching Nodes for which
`node.first` is greater than `index`\.

```lua
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
```


#### Node:selectBack\(pred\)


  Selects backward on the predicate, returning all nodes prior to the calling
node which match\.

```lua
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
```


#### Node:hasParents\(\.\.\.\)

Checks each parent up to root for all strings passed, returning `true` if any
`.id` is equal to any\.

```lua
function Node.hasParents(node, ...)
   if node.parent == node then return false end -- roots don't have parents.
   local rents = {}
   for i = 1, select('#', ...) do
      rents[select(i, ...)] = true
   end
   local parent = node.parent
   repeat
      if rents[parent.id] then
         return true
      end
      parent = parent.parent
   until parent == parent.parent -- root

   return false
end
```


#### Node:rootDistance\(\)

Returns the number of hops to root, which is `1`, not `0`, for root itself\.

Awkward name avoids the easy shadowing of `depth` in specialized Node form\.

```lua
function Node.rootDistance(node)
   if node == node.parent then return 1 end
   local count, parent = 1, node.parent
   repeat
      count = count + 1
      parent = parent.parent
   until parent == parent.parent
   return count
end
```


#### Node\.tokens\(node\)

  Iterator returning all captured values as strings\.

```lua
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
```


#### Node:lines\(\)

A simple wrapper around `core.lines`, kept around because, due to the name,
it's moderately annoying to tell whether it's in use\.

```lua
local lines = assert(core.lines)

function Node.lines(node)
  return lines(node:span())
end
```


#### Node:linePos\(\)

Returns four values: the line, and column offset, of `node.first`, followed by
the line and column offset of `node.last`\.



##### \_findPos\(nl\_map, target, start\)

\#DONE

 `_findPos` is suboptimal\.  Because it's a linear search, it's O\(n\), and we
could switch to a binary search and get O\(log n\)\.

When we start doing source mapping, `linePos` will be a pretty hot loop, so
it's probably worth doing this right\.

This would be annoying to get right with our existing data structure\.  At the
cost of some extra allocation, we could gather up all the newlines, then put
them in an array wherein `[1]` is the start of a line and `[2]` is the newline;
if there is a final line with no newline, it doesn't have a `[2]`\.

This would allow for an ordinary binary search by testing if `target` was
bounded by `[1]` and `[2]`, with the only exceptional case being the last
line\.

```lua
local linepos = assert(require "qor:core" .string .linepos)

function Node.linePos(node)
   -- unfortunately we return twice as much info as we normally need 'just
   -- in case'
   local line_first, col_first = linepos(node.str, node.first)
   local line_last, col_last = linepos(node.str, node.last)
   return line_first, col_first, line_last, col_last
end
```


#### Node:lastLeaf\(\)

Returns the last leaf of the node\.

Useful to check for terminal errors, for stop\-on\-error parsing\.

```lua
local function _lastLeaf(node)
  if #node == 0 then
    return node
  else
    return _lastLeaf(node[#node])
  end
end

Node.lastLeaf = _lastLeaf
```


#### Node:gather\(pred\)

These return an array of all results\.


- [ ] \#todo  This could be reimplemented as
    `core.collect(node.select, node, pred)` and probably renamed
    `node:collect(pred)` while we're at it\.


- [ ] \#todo  Add a Forest class to provide the iterator interface for
    the return arrays of this class\.

```lua
function Node.gather(node, pred)
  local gathered = {}
  for ast in node:select(pred) do
    gathered[#gathered + 1] = ast
  end

  return gathered
end
```


## Mutation

Methods to create another Node from a given Node, or change the structure of
a Node mutably\.


#### Node:clone\(\)

This is a thin wrapper around `cloneinstance`, which takes care of copying the
metatables and detecting the cycles created by the `parent` element\.

```lua
local cloneinstance = assert(core.cloneinstance)

function Node.clone(node)
   return cloneinstance(node)
end
```


#### Node:pluck\(\)

This method creates a self\-contained Node\.  So instead of the whole `str`, we
have `node:span()`, and the value of `node.first` at the root level is 1\.

```lua
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
```


#### Node:graft\(graft, \[index\]\)

Takes a proper Node and splices it into another Node at `index`, which
defaults to `#node + 1`\.

There are several steps here, we need to:


-  Splice `str` on the old Node with `str` on the new Node, at the indicated
    position, which is calculated base on a `.first` or `.last`, depending\.


-  Iterate the `graft` node, replacing `str` and adjusting `first` and `last`\.


-  Iterate the root of the original `node`, replacing `str`, adjusting `first`
    and `last` where appropriate \(i\.e\. greater than the splice index\)\.

    lastly:


-  Insert the `graft` node at the appropriate place, and set node\.parent to
    point to `node`\.

This being a mutable table method, it returns nothing\.  A case could be made
for this being an immutable method, which returns an entirely new Node, but
we can make that out of `node:clone()` and `node:graft(graft)`, where the
reverse isn't possible with an immutable method\.

By Lua convention, `index` must be either the same as a `.first`, or one more
than a `.last`, or in between\.  That way, a graft at `1` will succeed in
displacing the rest of the Nodes\.

Without an index, we will attempt to append the graft; this must be performed
on a root node, to avoid unexpected behavior\.

```lua
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
```


### Node:replace\(branch, index\)

Replaces the Node at `index` with `branch`\.

`index` must equal the old `node.first`, exactly; this is different from
`node:graft()`, which is legal between two Nodes which have a gap in the
string between them\.

If there are several Nodes with a compatible `node.first`, the one nearest to
the calling Node will be chosen\.

```lua
function Node.replace(node, branch, index)
   return graft(node, branch, index, true)
end
```


## Validation

These methods check that a Node, including all its children, meets the social
contract of Node behavior\.


### Node:isValid\(\)

Performs assertions on a single Node table\.

```lua
function Node.isValid(node)
  assert(node.id, "node must have an id")
  assert(node.isNode == Node, "isNode flag must be Node metatable, id: "
         .. node.id .. " " .. tostring(node))
  assert(node.first, "node must have first")
  assert(type(node.first) == "number", "node.first must be of type number")
  assert(node.last, "node must have last")
  assert(type(node.last) == "number", "node.last must be of type number")
  assert(node.str, "node must have str")
  assert(type(node.str) == "string",  "str must be string")
  assert(getmetatable(node), "node must have a metatable: " .. node.id)
  assert(node.parent and node.parent.isNode == Node,
         "node must have parent: " .. node.id)
  assert(type(node:span()) == "string", "span() must yield string")
  return true
end
```


### Node:validate\(\)

Runs Node:isValid\(\) on every Node in a tree\.

```lua
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
```


### Node:isCompact\(\)

Checks if a Node is compact: that is, that the Tokens in the Node are either
empty, or collectively span all substrings of the `str` field\.

```lua
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
```


### Subclassing and construction

These methods are used to construct specific Nodes, whether at `femto` or
within a given Grammar\.


#### Node:inherit\(\)

This does the familiar single\-inheritance with inlined `__index`ing, returning
both `Meta` and `meta`\.

It's easier to read than to describe:

```lua
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
```

And best understood on the [consumer side](hts://~/grammar.orb#tk)\.


#### Node:export\(mod, constructor\)

This prepares a Node for incorporation into a Grammar\.

\#Deprecated

```lua
function Node.export(_, mod, constructor)
  mod.__call = constructor
  return setmeta({}, mod)
end
```


## Node Instances

  To be a Node, indexed elements of the Array portion must also be
Nodes\.

If there are no children of the Node, it is considered to be a leaf node\.

Most of the Node library will fail to halt, and probably blow stack, if
cyclic Node graphs are made\.  The Grammar class will not do this to you\.


### Fields

  There are invariant fields a Node is also expected to have, they are:

  - first    :  Index into `str` which begins the span\.
  - last     :  Index into `str` which ends the span\.
  - str      :  The string of which the Node spans part or the whole, or
      a Phrase of same\.
  - isPhrase :  Equals `Phrase` iff str is a Phrase\.
  - parent   :  A Node, which may be a self\-reference for a root node\.
  - isNode   :  This equals to `Node`\.


### Other fields

  In principle, anything at all\.

```lua
return Node
```


