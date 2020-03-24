# Node


  The Node class implements an abstract syntax tree, in collaboration with
the [[Grammar class][~/grammar.orb]] and lpeg more generally.


#### asserts

```lua
local yield = assert(coroutine.yield, "uses coroutines")
local wrap = assert(coroutine.wrap)
local sub, find = assert(string.sub, "uses string"), assert(string.find)
local setmeta, getmeta = assert(setmetatable), assert(getmetatable)
```
#### requires

```lua
local s = require "singletons" . status ()
local a = require "singletons/anterm"
local c_bw = require "singletons/color" . no_color
local core = require "core:core"
local Phrase = require "singletons/phrase"
local dot = require "espalier/dot"
```
```lua
   -- ergo
   --[[
   local html = require "espalier/html"
   local css  = require "espalier/css"
   local portal = require "espalier/portal"
   --]]
```
## Node metatable

  The Node metatable is the root table for any Node, all of which should
subclass through [[Node:inherit()][hts://~/node#node:inherit()]].

```lua
local Node = {}
Node.__index = Node
Node.isNode = Node
```

we would now say ``local Node = meta {}``.


The ``isNode`` is a quirk of the ``Node`` arcy, being distinct from ``idEst`` for
orthogonality.


## Fields

   - id :  A string naming the Node.
           This is identical to the name of the pattern that recognizes
           or captures it.


           This is never set on Node itself, and Grammar will fail to
           produce a Node which lacks this flag.


   - isNode :  A boolean, always ``true``/truthy.


## Methods


#### toLua

This is not a general method in any sense, it's here as a backstop
while I build out Clu.


I'm going to call it an important root method: it says, in plain English,
that a bare Node cannot be simply converted to Lua.

```lua
function Node.toLua(node)
  s:halt("No toLua method for " .. node.id)
end
```
## Visualizer

This gives us a nice, tree-shaped printout of an entire Node.

#todo write a =__repr= version with bells and whistles.#### Node:strTag(c)

Returns a Phrase which prints the id and first-last range of the Node.


``c`` is a color table, defaulting to no color.

```lua
function  Node.strTag(node, c)
   c = c or c_bw
   local phrase = Phrase ""
   phrase = phrase .. c.bold(node.id) .. "    "
      .. c.number(node.first) .. "-" .. c.number(node.last)
   return phrase
end
```
#### Node:strExtra(c)

A placeholder for inserting extra information about a Node subclass.


The base class merely returns ``""``.

```lua
function Node.strExtra(node, c)
   return ""
end
```
#### Node:strLine(c)

Returns a Phrase containing a single line of Node information.


``c`` is a color table and default to no color.

```lua
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
```
### Node:toString(depth, c)

Recursively calls ``node:strLine(c)`` and returns an indented Phrase visualizing
the entire Node tree.


``depth`` defaults to 0, ``c`` is a color table defaulting to black and white.

```lua
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
### Node__repr

```lua
local lines = assert(core.lines)

local function __repr(node, phrase, c)
   local node__repr = tostring(node:toString(0, c))
   return lines(node__repr)
end

Node.__repr = __repr
```
## Metrics

These retrieve various general properties of the Node.


The focus has been on correctness over speed.


#### node:span()

``node:span()`` returns a substring across the span of the Node.

```lua
function Node.span(node)
   return sub(node.str, node.first, node.last)
end
```
#### node:bounds()

Returns ``node.first`` and ``node.last``, such that
``string.sub(node.str, node:bounds())`` is equal to ``node:span()``.

```lua
function Node.bounds(node)
   return node.first, node.last
end
```
#### node:len()

ahh, the pleasure of indexing by one.


``node:len()`` gives the length of the node; we can't use ``#node`` because
``node[#node]`` is the pragmatic way to access the rightmost child.


hmm.

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
#### Node:gap(node)

#NB this is unused and hence untested
``Node.gap(left, right)`` compares the ``last`` field of the ``left`` parameter
with the ``first`` field of the ``right`` parameter, **if** this is greater than
0.


If it is negative, ``Node.gap`` attempts to measure the ``first`` field of the
``right`` parameter against the ``last`` field of the ``left`` parameter.


If this is a natural number we return the **negation** of this value.  If both
should prove to be positive, we halt.


No effort is made to check that the ``str`` field matches between nodes unless
we have an error, in which case it could prove helpful for diagnosis.


Indeed such a check would be a disaster in streams or other sort of
piecewise parse.  Which will require implementation in and of itself, but
in the meantime...

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
#### node:dotLabel()

This provides a label for dot files.


Perhaps over-specialized.  We might prefer a ``node:label()`` for generality
and call it when constructing labile trees.

```lua
function Node.dotLabel(node)
  return node.id
end
```
#### node:label()

A synonym, then. But a heritable one, you see.


``id`` being generic, and genre being all we have at the root:

```lua
function Node.label(node)
   return node.id
end
```
### Backstops

The backstops prevent malformed parsing of some key format transitions.


They also provide a paradigm for writing more of same for language-specific
cases.


#### node:toMarkdown()

This provides a literal string if called on a leaf node and otherwise halts.

```lua
function Node.toMarkdown(node)
  if not node[1] then
    return sub(node.str, node.first, node.last)
  else
    s:halt("no toMarkdown for " .. node.id)
  end
end
```
### node:dot(node)

Generates a entire ``dot`` node.

```lua
function Node.dot(node)
  return dot.dot(node)
end
```
### node:toValue()

Sometimes you want the value of a Node.


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

Methods to move around inside a Node.


#### Node:root()

Returns the root of a given Node tree structure.

```lua
local function _root(node)
   if node.parent == node then
      return node
   end
   return _root(node.parent)
end

Node.root = _root
```
#### Node.walkPost

Depth-first iterator, postfix

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
#### Node.walk

Presearch iterator.  This is the default.

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


#### Node.coro_select(node, pred)

  Takes the Node and walks it, yielding the Nodes which match the predicate.
``pred`` is either a string, which matches to ``id``, or a function, which takes
a Node and returns true or false on some premise.

```lua
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
```
#### Node.select(node)

This version uses a closure instead of a coroutine, to get around a crashing
problem we've been having in bridge.

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
#### Node.tokens(node)

  Iterator returning all captured values as strings.

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
#### Node.lines(node)

A simple wrapper around ``core.lines``, kept around because, due to the name,
it's moderately annoying to tell whether it's in use.

```lua
local lines = assert(core.lines)

function Node.lines(node)
  return lines(node:span())
end
```
#### Node.linePos(node)

Returns four values: the line, and column offset, of ``node.first``, followed by
the line and column offset of ``node.last``.



```lua
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
```
#### Node.lastLeaf(node)

Returns the last leaf of the node.


Useful to check for terminal errors, for stop-on-error parsing.

```lua
function Node.lastLeaf(node)
  if #node == 0 then
    return node
  else
    return Node.lastLeaf(node[#node])
  end
end
```
#### Node:gather(pred)

These return an array of all results.


- [ ] #todo  This could be reimplemented as
             ``core.collect(node.select, node, pred)`` and probably renamed
             ``node:collect(pred)`` while we're at it.


- [ ] #todo  Add a Forest class to provide the iterator interface for
             the return arrays of this class.

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
a Node mutably.


#### Node:clone()

This is a thin wrapper around ``cloneinstance``, which takes care of copying the
metatables and detecting the cycles created by the ``parent`` element.

```lua
local cloneinstance = assert(core.cloneinstance)

function Node.clone(node)
   return cloneinstance(node)
end
```
#### Node:pluck()

This method creates a self-contained Node.  So instead of the whole ``str``, we
have ``node:span()``, and the value of ``node.first`` at the root level is 1.

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
#### Node:graft(graft, [index])

Takes a proper Node and splices it into another Node at ``index``, which
defaults to ``#node + 1``.


There are several steps here, we need to:


-  Splice ``str`` on the old Node with ``str`` on the new Node, at the indicated
   position, which is calculated base on a ``.first`` or ``.last``, depending.


-  Iterate the ``graft`` node, replacing ``str`` and adjusting ``first`` and ``last``.


-  Iterate the root of the original ``node``, replacing ``str``, adjusting ``first``
   and ``last`` where appropriate (i.e. greater than the splice index).


   lastly:


-  Insert the ``graft`` node at the appropriate place, and set node.parent to
   point to ``node``.


This being a mutable table method, it returns nothing.  A case could be made
for this being an immutable method, which returns an entirely new Node, but
we can make that out of ``node:clone()`` and ``node:graft(graft)``, where the
reverse isn't possible with an immutable method.

```lua-noknit
function Node.graft(node, graft, index)
   local root = node:root()
   local new_str = ""
   if not index then
      new_str = node.str .. graft.str
      insert(node, graft)
   else -- to be continued...

   end
end
```
## Validation

These methods check that a Node, including all its children, meets the social
contract of Node behavior.


### Node:isValid()

Performs assertions on a single Node table.

```lua
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
```
### Node:validate()

Runs Node:isValid() on every Node in a tree.

```lua
function Node.validate(node)
  for twig in node:walk() do
    twig:isValid()
  end
  return true
end

```
### Subclassing and construction

These methods are used to construct specific Nodes, whether at ``femto`` or
within a given Grammar.


#### Node:inherit()

This does the familiar single-inheritance with inlined ``__index``ing, returning
both ``Meta`` and ``meta``.


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

And best understood on the [consumer side](hts://~/grammar.orb#tk).


#### Node:export(mod, constructor)

This prepares a Node for incorporation into a Grammar.

```lua
function Node.export(_, mod, constructor)
  mod.__call = constructor
  return setmeta({}, mod)
end
```
## Node Instances

  To be a Node, indexed elements of the Array portion must also be
Nodes.


If there are no children of the Node, it is considered to be a leaf node.


Most of the Node library will fail to halt, and probably blow stack, if
cyclic Node graphs are made.  The Grammar class will not do this to you.


### Fields

  There are invariant fields a Node is also expected to have, they are:


  - first    :  Index into ``str`` which begins the span.
  - last     :  Index into ``str`` which ends the span.
  - str      :  The string of which the Node spans part or the whole, or
                a Phrase of same.
  - isPhrase :  Equals ``Phrase`` iff str is a Phrase.
  - parent   :  A Node, which may be a self-reference for a root node.
  - isNode   :  This equals to ``Node``.


### Other fields

  In principle, anything at all.

```lua
return Node
```
