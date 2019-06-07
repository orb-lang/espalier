# Grammar Module

  The grammar module returns one function, which generates
a grammar.

```lua
local s = require "status" ()
s.verbose = false
s.angry   = false
```
## Parameters

This function takes two parameters, namely:


  - grammar_template :  A function with one parameter, which must be ``_ENV``.
  - metas :  A map with keys of string and values of Node subclass
             constructors.


Both of these are reasonably complex.


### grammar_template

  The internal function @define creates a custom environment variable, neatly
sidestepping lua's pedantic insistance on prepending ``local`` to all values of
significance.


More relevantly, it constructs a full grammar, which will return a table of
type Node.


If you stick to ``lpeg`` patterns, as you should, all array values will be of
Node.  Captures will interpolate various other sorts of Lua values, which will
induce halting in some places and silently corrupt execution in others.


The [elpatt module](./elpatt) is intended to provide those patterns which
are allowed in Grammars, while expanding the scope of some favorites to
properly respect utf-8 and otherwise behave.


There are examples of the format in the [spec module](./spec).


Also included are two functions:


  -  START :  a string which must be the same as the starting rule.
  -  SUPPRESS :  either a string or an array of strings. These rules will be
                 removed from the Node.


### metas

  By default a node will inherit from the Node class.  If you want custom
behavior, you must pass in a table of metatable constructors.


That's a fairly specific beast.  Any rule defined above will have an ``id``
corresonding to the name of the rule.  Unless ``SUPPRESS``ed, this will become
a Node.  If the ``metas`` parameter has a key corresponding to ``id``, then it
must return a function taking two parameters:


   - node :  The node under construction, which under normal circumstances
             will already have the ``first`` and ``last`` fields.
   - str  :  The entire str the grammar is parsing.


Which must return that same node, decorated in whatever fashion is
appropriate.


The node will not have a metatable at this point, and the function must attach
a metatable with ``__index`` equal to some table which itself has the ``__index``
Node as some recursive backstop.


You might say the return value must _inherit_ from Node, if we were using
a language that did that sort of thing.


### includes


- [ ] #todo  Note the require strings below, which prevent this from
             being a usable library, because ``node`` not ``lpegnode``.


             The problem is almost a philosophical one, and it's what I'm
             setting out to solve with ``bridge`` and ``manifest``.


             In the meantime, ``lpegnode`` has one consumer. Let's keep it
             happy.


             I'm renaming it ``espalier`` anyway.

```lua
local L = require "lpeg"
local a = require "anterm"

local Node = require "espalier/node"
local elpatt = require "espalier/elpatt"

local DROP = elpatt.DROP
```

I like the dedication shown in this style of import.


It's the kind of thing I'd like to automate.

```lua
local assert = assert
local string, io = assert( string ), assert( io )
local VER = string.sub( assert( _VERSION ), -4 )
local _G = assert( _G )
local error = assert( error )
local pairs = assert( pairs )
local next = assert( next )
local type = assert( type )
local tostring = assert( tostring )
local setmetatable = assert( setmetatable )
if VER == " 5.1" then
   local setfenv = assert( setfenv )
   local getfenv = assert( getfenv )
end
```
### make_ast_node

  This takes a lot of parameters and does a lot of things.


```lua
local function make_ast_node(id, first, t, last, str, metas, offset)
```
#### setup values and metatables

  As [covered elsewhere](httk://), we accept three varieties of
metatable verb.  An ordinary table is assigned; a table with __call is
called, as is an ordinary function.


The latter two are expected to return the original table, now a descendent
of ``Node``.  This need not have an ``id`` field which is the same as the ``id``
parameter.

```lua
   local offset = offset or 0
   t.first = first + offset
   t.last  = last + offset - 1
   t.str   = str
   if metas[id] then
      local meta = metas[id]
      if type(meta) == "function" or meta.__call then
        t = metas[id](t, str)
      else
        t = setmetatable(t, meta)
      end
      assert(t.id, "no id on Node")
   else
      t.id = id
       setmetatable(t, {__index = Node,
                     __tostring = Node.toString})
   end
```
#### DROP

  The rule ``elpatt.D`` causes the match to be dropped. In order for
this to give use the results we want, we must adjust the peer and
parent nodes while removing the captured element from the table.


The use case is for eloquently expressed 'wrapper' patterns, which occur
frequently in real languages. In a ``(typical lisp expression)`` we don't need
the parentheses and would like our span not to include them.


We could use a pattern like ``V"formwrap"`` and then SUPPRESS ``formwrap``, but
this is less eloquent than ``D(P"(") * V"form" *  D(P")")``.


Which is admittedly hard to look at.  We prefer the form
``D(pal) * V"form" * D(par)`` for this reason among others.


The algorithm moves from the right to the left, because ``table.remove(t)``
is O(1) so we can strip any amount of rightward droppage first.  It is
correspondingly more expensive to strip middle drops, and most expensive
to strip leftmost drops.


More importantly, if we counted up, we'd be tracking ``#t``, a moving target.
Counting to 1 neatly prevents this.


   -  [ ] #Todo :Faster:


     -  This algorithm, as we discussed, goes quadratic toward the left side.
        The correct way to go is if we see any drop, flip a dirty bit, and
        compact upward.


     -  More to the point, the mere inclusion of this much ``s:`` slows the
        algorithm to an utter crawl. The concatenations happen anyway, to
        pass the string into the status module.


        This is probably 10x the cost in real work.


        Why am I doing it in such a dumb way? This is a literate programming
        environment, and I'm building a language with templates and macros
        and other useful access to state at compile time.


        That's two ways to remove the verbosity and other printfs when they
        aren't wanted.  Better to simulate the correct behavior until I can
        provide it.


anyway back to our program


The parent of the first node is always itself:

```lua
   if not t.parent then
      t.parent = t
   end
```

This means the special case isn't a ``nil``, which I think is better.


Now we iterate the children

```lua
   for i = #t, 1, -1 do
      t[i].parent = t
      local cap = t[i]
      if type(cap) ~= "table" then
         s:complain("CAPTURE ISSUE",
                    "type of capture subgroup is " .. type(v) .. "\n")
      end
      if cap.DROP == DROP then
         s:verb("drops in " .. a.bright(t.id))
         if i == #t then
            s:verb(a.red("rightmost") .. " remaining node")
            s:verb("  t.$: " .. tostring(t.last) .. " Δ: "
                   .. tostring(cap.last - cap.first))
            t.last = t.last - (cap.last - cap.first)
            table.remove(t)
            s:verb("  new t.$: " .. tostring(t.last))
         else
            -- Here we may be either in the middle or at the leftmost
            -- margin.  Leftmost means either we're at index 1, or that
            -- all children to the left, down to 1, are all DROPs.
            local leftmost = (i == 1)
            if leftmost then
               s:verb(a.cyan("  leftmost") .. " remaining node")
               s:verb("    t.^: " .. tostring(t.first)
                      .. " D.$: " .. tostring(cap.last))
               t.first = cap.last
               s:verb("    new t.^: " .. tostring(t.first))
               table.remove(t, 1)
            else
               leftmost = true -- provisionally since cap.DROP
               for j = i, 1, -1 do
                 leftmost = leftmost and t[j].DROP
                 if not leftmost then break end
               end
               if leftmost then
                  s:verb(a.cyan("  leftmost inner") .. " remaining node")
                  s:verb("    t.^: " .. tostring(t.first)
                         .. " D.$: " .. tostring(cap.last))
                  t.first = cap.last
                  s:verb("    new t.^: " .. tostring(t.first))
                  for j = i, 1, -1 do
                     -- this is quadradic but correct
                     -- and easy to understand.
                     table.remove(t, j)
                     break
                  end
               else
                  s:verb(a.green("  middle") .. " node dropped")
                  table.remove(t, i)
               end
            end
         end
      end
   end
   assert(t.isNode, "failed isNode: " .. id)
   assert(t.str)
   assert(t.parent, "no parent on " .. t.id)
   return t
end


-- localize the patterns we use
local Cp = L.Cp
local Cc = L.Cc
local Ct = L.Ct
local arg1_str = L.Carg(1)
local arg2_metas = L.Carg(2)
local arg3_offset = L.Carg(3)


-- setup an environment where you can easily define lpeg grammars
-- with lots of syntax sugar
local function define(func, g, e)
  g = g or {}
  if e == nil then
    e = VER == " 5.1" and getfenv(func) or _G
  end
  local suppressed = {}
  local env = {}
  local env_index = {
    START = function(name) g[1] = name end,
    SUPPRESS = function(...)
      suppressed = {}
      for i = 1, select('#', ...) do
        suppressed[select(i, ... )] = true
      end
    end,
    V = L.V,
    P = L.P,
  }

  setmetatable(env_index, { __index = e })
  setmetatable(env, {
    __index = env_index,
    __newindex = function( _, name, val )
      if suppressed[ name ] then
        g[ name ] = val
      else
        g[ name ] = (Cc(name)
              * Cp()
              * Ct(val)
              * Cp()
              * arg1_str
              * arg2_metas)
              * arg3_offset / make_ast_node
      end
    end
  })
  -- call passed function with custom environment (5.1- and 5.2-style)
  if VER == " 5.1" then
    setfenv( func, env )
  end
  func( env )
  assert( g[ 1 ] and g[ g[ 1 ] ], "no start rule defined" )
  return g
end
```
```lua
local function refineMetas(metas)
  for id, meta in pairs(metas) do
    if type(meta) == "table" then
      if not meta["__tostring"] then
        meta["__tostring"] = Node.toString
      end
      if not meta.id then
        meta.id = id
      end
    end
  end
  return metas
end
```
## new

Given a grammar_template function and a set of metatables,
yield a parsing function and the grammar as an ``lpeg`` pattern.

```lua
local function new(grammar_template, metas)
  if type(grammar_template) == "function" then
    local metas = metas or {}
    metas = refineMetas(metas)
    local grammar = define(grammar_template, nil, metas)

    local function parse(str, offset)
      local offset = offset or 0
      local match = L.match(grammar, str, 1, str, metas, offset)
      local maybeErr = match:lastLeaf()
      if maybeErr.id then
        if maybeErr.id == "ERROR" then
          local line, col = match:linePos(maybeErr.first)
          local msg = maybeErr.msg or ""
          s:complain("Parsing Error", " line: " .. tostring(line) .. ", "
                     .. "col: " .. tostring(col) .. ". " .. msg)
          return match, match:lastLeaf()
        else
          return match
        end
      else
          local maybeNode = maybeErr.isNode and " is " or " isn't "
          s:complain("No id on match" .. "match of type, " .. type(match)
                    .. maybeNode .. " a Node: " .. tostring(maybeErr))
      end

      -- This would be a bad match.
      return match
    end

    return parse, grammar
  else
    s:halt("no way to build grammar out of " .. type(template))
  end
end
```
```lua
return new
```
