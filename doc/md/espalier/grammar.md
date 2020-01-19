# Grammar Module


  The grammar module returns one function, which generates a grammar.


## Introduction

This module is in a very real sense a **duet**.


It is an adaptation, refinement, extension, of Phillipe Janda's work,
``luaepnf``:


**[[luaepnf][http://siffiejoe.github.io/lua-luaepnf/]]**


While ``femto`` is based on a repl by Tim Caswell, that is a case of taking a
sketch and painting a picture.


Many difficult aspects of this algorithm are found directly in the source
material upon which this is based.


Don Phillipe has my thanks, and my fervent hope that he enjoys what follows.


#### Aside to the Knuthian camp

I have written a semi-literate boostrap.


I make no apology for this.  Cleaning what follows into a literate order is
a tractable problem.


In the meantime, let us build a Grammar from parts.


## Return Parameters of the Grammar Function

This function takes two parameters, namely:


  - grammar_template :  A function with one parameter, which must be ``_ENV``.
  - metas :  A map with keys of string and values of Node subclass
             constructors.


Both of these are reasonably complex.


### grammar_template

  The internal function ``define`` creates a custom environment variable, neatly
sidestepping Lua's pedantic insistance on prepending ``local`` to all values of
significance.


Thus equipped, it constructs a full grammar, which will return a table of type
Node.


If you stick to ``lpeg`` patterns, as you should, all array values will be of
Node.  Captures will interpolate various other sorts of Lua values, which will
induce halting in some places and silently corrupt execution in others.


You can use captures in your rules, if it's helpful, as with named groups,
just toss them away at the end of the rule like so:

```lua-example
divisible_by_three = Cmt( C(R"09"^1),
   function(s, i, val)
      if tonumber(val) % 3 == 0
         return true
      else
         return false
      end
   end ) / 0
```

Giving a rule which matches an integer evenly divisible by three.


The [[elpatt module][~/elpatt.orb]] is intended to provide those
patterns which are allowed in Grammars, while expanding the scope of some
favorites to properly respect utf-8 and otherwise behave.


Also included are two functions:


  -  START :  A string which must be the same as the starting rule.
  -  SUPPRESS :  Either a string or an array of strings. These rules will be
                 removed from the resulting AST, while keeping all leaf nodes,
                 if any.


The use of ALL-CAPS was Phillipe Janda's convention, I agree that it reads
well in this singular instance.


### metas

  By default a node will inherit from the Node class.  If you want custom
behavior, you must pass in a table of metatable constructors.


That's a fairly specific beast.  Any rule defined above will have an ``id``
corresonding to the name of the rule.  Unless ``SUPPRESS``ed, this will become
a Node.  If the ``metas`` parameter has a key corresponding to ``id``, then it
must return a function taking two parameters:


   - node   :  The node under construction, which will already have the
               ``first``, ``last``, and ``str`` fields.


   - offset :  The offset, which indicates how much to add to the ``str``
               field to get the actual offset into the string.


               This is zero by default and is used to parse a string
               piecewise.


Which must return that same node, decorated in whatever fashion is
appropriate.


The node will not have a metatable at this point, and the function must attach
a metatable with ``__index`` equal to some table which itself has the ``__index``
Node as some recursive backstop.


You might say the return value must _inherit_ from Node, if we were using
a language that did that sort of thing.


A metatable with the key ``__DEFAULT`` is given special treatment, used to
replace Node itself for classes which are not provided with a metatable.


## Roadmap

  The Grammar class needs to be expanded to cover a broader array of use
cases, and specifically to enable the features we'll be able to add given the
declarative PEG format front end.


To this end:


- [ ] #Todo #version @0.0.2


   - [ ]  Make ``new`` return a callable table, instead of a function.


          This will allow us to decorate the now-single return value with
          the grammar, and eventually grammars.  We'll include ``new`` as
          ``grammar.new``.


          This is the most important step for this class; other capabilities
          are either being baked in Node, or will be their own module, for
          instance using Lua-native combinators to validate deltas into an
          existing Node structure.

## Implementation

All of ``espalier`` is in principle compatible with the entire '5' series of
Luas.  Any failure to execute through at least 5.4 is considered a bug.


### imports

We follow a strict coding style for admitting dependencies into the module,
localizing everything as an upvalue before using it.


#### requires


##### status

```lua
local s = require "singletons" . status ()
s.verbose = false
s.angry   = false
```
#### requires, contd.

```lua
local L = require "lpeg"
local a = require "singletons/anterm"
local compact = assert(require "core/table" . compact)
local Node = require "espalier/node"
local elpatt = require "espalier/elpatt"

local DROP = elpatt.DROP
```

It's the kind of thing I'd like to automate.


#### asserts

```lua
local assert = assert
local string, io = assert( string ), assert( io )
local remove = assert(table.remove)
local VER = string.sub( assert( _VERSION ), -4 )
local _G = assert( _G )
local error = assert( error )
local pairs = assert( pairs )
local next = assert( next )
local type = assert( type )
local tostring = assert( tostring )
local setmeta = assert( setmetatable )
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

- Parameters:
  - id      :  'string' naming the Node
  - first   :  'number' of the first byte of ``str``
  - t       :  'table' capture of grammatical information
  - last    :  'number' of the last byte of ``str``
  - str     :  'string' being parsed
  - metas   :  'table' of Node-inherited metatables (complex)
  - offset  :  'number' of optional offset.  This would be provided if
               e.g. byte 1 of ``str`` is actually byte 255 of a larger
               ``str``.  Normally ``nil``.


``first``, ``last`` and ``offset`` follow Wirth indexing conventions.


Because of course they do.


#### Set up values and metatables

  We accept two types of value for a metatable. A table must be derived from
the Node class, while a function must return an appropriately-shaped table,
given the capture and offset.


This can be used to process captures which aren't strings, perform validation,
or run another grammar and return an entire AST, but currently cannot fail to
return a Node of some sort.

```lua
   t.first = first + offset
   t.last  = last + offset - 1
   t.str   = str
   if metas[id] then
      local meta = metas[id]
      if type(meta) == "function" then
        t = meta(t, offset)
      else
        t = setmeta(t, meta)
      end
      assert(t.id, "no id on Node")
   elseif metas.__DEFAULT then
      t.id = id
      setmeta(t, metas.__DEFAULT)
   else
      t.id = id
      setmeta(t, Node)
   end

   if not t.parent then
      t.parent = t
   end
```
#### DROP

I'm removing all of this logic, but leaving the hook in place.


We want to be able to drop things.  We want to be able to tag captures as
ignorable, and we want to be able to do that soon.


But the right way to do it, is to iterate the children, and if we see
something we don't like, we trip a flag.


If that flag is tripped, then, and only then, we compact the table, in a
single pass, with a helper function.

```lua

```

This means the special case isn't a ``nil``, which I think is better.


Now we iterate the children, caching the value of ``#t`` before we begin.  I
don't actually know if the VM will update that value on each iteration, and
don't want to find out.  Also, we need it to ``compact`` the table if we drop
anything.

```lua
   local top, touched = #t, false
   for i = 1, top do
      local cap = t[i]
      if type(cap) ~= "table" or not cap.isNode then
         touched = true
         t[i] = nil
      else
         cap.parent = t
      end
   end
   if touched then
      compact(t, top)
   end
   -- post conditions
   assert(t.isNode, "failed isNode: " .. id)
   assert(t.str)
   assert(t.parent, "no parent on " .. t.id)
   return t
end
```
## define(func, g, e)

This is [Phillipe Janda](http://siffiejoe.github.io/lua-luaepnf/)'s
algorithm, with my adaptations.


``e``, either is or becomes ``_ENV``.


This is not needed in LuaJIT, while for Lua 5.2 and above, it is.


``func`` is the grammar definition function, pieces of which we've provided.
We'll see how the rest is put together presently.


``g`` is, or becomes, a ``Grammar``.


#### localizations

We localize the patterns we use.

```lua
local Cp = L.Cp
local Cc = L.Cc
local Ct = L.Ct
local arg1_str = L.Carg(1)
local arg2_metas = L.Carg(2)
local arg3_offset = L.Carg(3)
```

Setup an environment where you can easily define lpeg grammars
with lots of syntax sugar, compatible with the 5 series of Luas:

```lua
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
      P = L.P }

    setmeta(env_index, { __index = e })
    setmeta(env, {
       __index = env_index,
       __newindex = function( _, name, val )
          if suppressed[ name ] then
             g[ name ] = val
          else
             g[ name ] = Cc(name)
                       * Cp()
                       * Ct(val)
                       * Cp()
                       * arg1_str
                       * arg2_metas
                       * arg3_offset / make_ast_node
          end
       end })

   -- call passed function with custom environment (5.1- and 5.2-style)
   if VER == " 5.1" then
      setfenv(func, env )
   end
   func( env )
   assert( g[ 1 ] and g[ g[ 1 ] ], "no start rule defined" )
   return g
end
```
### refineMetas(metas)

Takes metatables, distributing defaults and denormalizations.

```lua
local function refineMetas(metas)
  for id, meta in pairs(metas) do
    if id ~= "__DEFAULT" then
      if type(meta) == "table" then
        -- #todo is this actually necessary now?
        -- if all Node children are created with Node:inherit than
        -- it isn't.
        if not meta["__tostring"] then
          meta["__tostring"] = Node.toString
        end
        if not meta.id then
          meta.id = id
        end
      end
    end
  end
  return metas
end
```
## new

Given a grammar_template function and a set of metatables,
yield a parsing function and the grammar as an ``lpeg`` pattern.


#### _fromString(g_str), _toFunction(maybe_grammar)

Currently this is expecting pure Lua code; the structure of the module is
such that we can't call the PEG grammar from ``grammar.orb`` due to the
circular dependency thereby created.


This implies wrapping some porcelain around everything so that we can at least
try to build the declarative form first.

```lua
local function _fromString(g_str)
   local maybe_lua, err = loadstring(g_str)
   if maybe_lua then
      return maybe_lua()
   else
      s : halt ("cannot make function:\n" .. err)
   end
end

local function _toFunction(maybe_grammar)
   if type(maybe_grammar) == "string" then
      return _fromString(maybe_grammar)
   elseif type(maybe_grammar) == "table" then
      -- we may as well cast it to string, since it might be
      -- and sometimes is a Phrase class
      return _fromString(tostring(maybe_grammar))
   end
end

local P = assert(L.P)

local function new(grammar_template, metas, pre, post)
   if type(grammar_template) ~= "function" then
      -- see if we can coerce it
      grammar_template = _toFunction(grammar_template)
   end

   local metas = metas or {}
   metas = refineMetas(metas)
   local grammar = define(grammar_template, nil, metas)

   local function parse(str, start, finish)
      local sub_str, begin = str, 1
      local offset = start and start - 1 or 0
      if start and finish then
         sub_str = string.sub(str, start, finish)
      end
      if start and not finish then
         begin = start
         offset = 0
      end

      --[[
      if pre then
         str = pre(str)
         assert(type(str) == "string")
      end
      --]]
      local match = L.match(grammar, sub_str, begin, str, metas, offset)
      if match == nil then
         return nil
      end
      --[[
      if post then
        match = post(match)
      end
      --]]
      --[[ All of this needs rethinking
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
      --]]
      return match
   end

   return parse, grammar
end
```
```lua
return new
```
