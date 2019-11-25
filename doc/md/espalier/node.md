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
local core = require "singletons/core"
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
### Visualizer

This gives us a nice, tree-shaped printout of an entire Node.


We're less disciplined than we should be about up-assigning this to
inherited Node classes.

```lua
local function toString(node, depth, c)
   c = c or c_bw
   depth = depth or 0
   local phrase = Phrase ""
   phrase = ("  "):rep(depth) .. c.bold(node.id) .. "    "
      .. c.number(node.first) .. "-" .. c.number(node.last)
   if node[1] then
      local extra = "    "
      if node:len() > 56 then
         --  Truncate in the middle
         local span = node:span()
         local pre, post = sub(span, 1, 26), sub(span, -26, -1)
         extra = extra .. c.greyscale(pre)
                       .. c.bold("………") .. c.greyscale(post)
         extra = extra:gsub("\n", "◼︎")
      else
         extra = extra .. c.greyscale(node:span():gsub("\n", "◼︎"))
      end
      phrase = phrase .. extra .. "\n"
      for _,v in ipairs(node) do
         if (v.isNode) then
            phrase = phrase .. v:toString(depth + 1, c)
         end
      end
   else
      local val = node.str:sub(node.first, node.last)
                          :gsub(" ", a.clear()
                                .. c.greyscale("_") .. c.string())
      val = c.string(val)
      phrase = phrase .. "    " .. val  .. "\n"
   end
   return phrase
end

Node.toString = toString
```
```lua
local function __tostring(node)
   if not node.str then
      return "Node"
   end
   return tostring(toString(node))
end

Node.__tostring = __tostring
```
```lua
local function __repr(node, phrase, c)
   local node__repr = toString(node, 0, c)
   return core.lines(node__repr)
end

Node.__repr = __repr
```
### Metrics

These retrieve various general properties of the Node.


The focus has been on correctness over speed.


#### node:span()

``node:span()`` returns a substring across the span of the Node.

```lua
function Node.span(node)
   return sub(node.str, node.first, node.last)
end
```
#### node:len()

ahh, the pleasure of indexing by one.


``node:len()`` gives the ``#node`` and I think we can just add that as a synonym.


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

yes, we can:

```lua
Node.__len = Node.len
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
  local gap = left
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

Worth writing twice.


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
### Iterators

Traversal may be done several ways.


#### Node.walkPost

Depth-first iterator, postfix

```lua
function Node.walkPost(node)
    local function traverse(ast)
        if not ast.isNode then return nil end

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
    if not ast.isNode then return nil end
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
### Selection

We are frequently in search of a subset of Nodes:


#### Node.select(node, pred)

  Takes the Node and walks it, yielding the Nodes which match the predicate.
``pred`` is either a string, which matches to ``id``, or a function, which takes
a Node and returns true or false on some premise.

```lua
function Node.select(node, pred)
   local function qualifies(node, pred)
      if type(pred) == 'string' then
         if type(node) == 'table'
          and node.id and node.id == pred then
            return true
         else
            return false
         end
      elseif type(pred) == 'function' then
         return pred(node)
      else
         s:halt("cannot select on predicate of type " .. type(pred))
      end
   end

   local function traverse(ast)
      -- breadth first
      if qualifies(ast, pred) then
         yield(ast)
      end
      if ast.isNode then
         for _, v in ipairs(ast) do
            traverse(v)
         end
      end
   end

   return wrap(function() traverse(node) end)
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

A memoized iterator returning ``str`` one line at a time.


Newlines are not included.


In addition, the first ``node:lines()`` traversal builds up
a source map subsequently used by ``node:atLine(pos)`` to
return the line and column of a given position.

```lua
function Node.lines(node)
  local function yieldLines(node, linum)
     for _, str in ipairs(node.__lines) do
        yield(str)
      end
  end

  if node.__lines then
     return wrap(function ()
                    yieldLines(node)
                 end)
  else
     node.__lines = {}
  end

  local function buildLines(str)
      if str == nil then
        return nil
      end
      local rest = ""
      local first, last = find(str, "\n")
      if first == nil then
        return nil
      else
        local line = sub(str, 1, first - 1) -- no newline
        rest       = sub(str, last + 1)    -- skip newline
        node.__lines[#node.__lines + 1] = line
        yield(line)
      end
      buildLines(rest)
  end

  return wrap(function ()
            buildLines(node.str)
         end)
end
```
#### Node.linePos(node, position)

Returns the line and column given a position.


This currently builds up the line array.


- [ ]  #todo  Optimal Node.linePos().


       This needs to be more optimal; it should use ``string.find`` to
       build up a memoized collection of start and end points and
       never break up the string directly.


       At least we're only paying the price once, but Node is supposed
       to be lazy about slicing strings, and this is eager.

```lua
function Node.linePos(node, position)
   if not node.__lines then
      for _ in node:lines() do
        -- nothing, this generates the line map
      end
   end
   local offset = 0
   local position = position
   local linum = nil
   for i, v in ipairs(node.__lines) do
       linum = i
       local len = #v + 1 -- for nl
       local offset = offset + len
       if offset > position then
          return linum, position
       elseif offset == position then
          return linum, len
       else
          position = position - #v - 1
       end
   end
   -- this position is off the end of the string
   return nil, "exceeds #str", - offset  -- I think that's the best 3rd value?
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
### Collectors

These return an array of all results.


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
### Validation

This checks that a Node, including all its children, meets the social
contract of Node behavior.

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
  local _repr, _tostring
  local node_M = getmetatable(node)
  if node_M then
    _repr = node_M.__repr
    _tostring = node_M.__tostring
  else
    _repr = __repr
    _tostring = __tostring
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
