# Grammar Module

  The grammar module returns one function, which generates
a grammar. 

## Parameters

This function takes two parameters, namely:


  - grammar_template :  A function with one parameter, which must be `````_ENV`````.
  - metas :  A map with keys of string and values of Node subclass constructors.


Both of these are reasonably complex.


### grammar_template

  The internal function @define creates a custom environment variable, neatly
sidestepping lua's pedantic insistance on prepending `````local````` to all values of 
significance. 


More relevantly, it constructs a full grammar, which will return a table of
type Node. 


If you stick to `````lpeg````` patterns, as you should, all array values will be of
Node, as is intended.  Captures will interpolate various other sorts of Lua
values, which will induce halting in some places and silently corrupt
execution in others. 


Though as yet poorly thought through, the [elpatt module](./elpatt) is
intended to provide only those patterns which are allowed in Grammars, while
expanding the scope of some favorites to properly respect utf-8 and otherwise
behave. 


There are examples of the format in the [spec module](./spec).


Special fields include:


  -  START :  a string which must be the same as the starting rule.
  -  SUPPRESS :  either a string or an array of strings. These rules will be
                 removed from the Node. 
  -  P :  The lpeg P function.  Recognizes a certain pattern.
  -  V :  The lpeg V function.  Used for non-terminal rvalues in a grammar. 


### metas

  By default a node will inherit from the Node class.  If you want custom behavior,
you must pass in a table of metatable constructors.


That's a fairly specific beast.  Any rule defined above will have an `````id`````
corresonding to the name of the rule.  Unless `````SUPPRESS`````ed, this will become
a Node.  If the `````metas````` parameter has a key corresponding to `````id`````, then it
must return a function taking two parameters:
   
   - node :  The node under construction, which under normal circumstances will
             already have the `````first````` and `````last````` fields.
   - str  :  The entire str the grammar is parsing.


Which must return that same node, decorated in whatever fashion is appropriate.


The node will not have a metatable at this point, and the function must attach a
metatable with `````__index````` equal to some table which itself has the `````__index`````
Node as some recursive backstop.


You might say the return value must _inherit_ from Node, if we were using
a language that did that sort of thing. 


### includes


- [ ] #todo  Note the require strings below, which prevent this from
             being a usable library. 


             The problem is almost a philosophical one, and it's what I'm
             setting out to solve with `````bridge````` and `````manifest`````. 


             In the meantime, `````lpegnode````` has one consumer. Let's keep it
             happy. 

```lua
local L = require "lpeg"

local s = require "status" ()
s.verbose = false
s.angry   = false

local Node = require "node/node"
local elpatt = require "node/elpatt"

local DROP = elpatt.DROP
```

I like the dedication shown in this style of import.


It's the kind of thing I'd like to automate. 

```lua
local assert = assert
local string, io = assert( string ), assert( io )
local V = string.sub( assert( _VERSION ), -4 )
local _G = assert( _G )
local error = assert( error )
local pairs = assert( pairs )
local next = assert( next )
local type = assert( type )
local tostring = assert( tostring )
local setmetatable = assert( setmetatable )
if V == " 5.1" then
   local setfenv = assert( setfenv )
   local getfenv = assert( getfenv )
end
```
### define

```lua
local function make_ast_node(id, first, t, last, str, metas, offset)
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
      assert(t.id)
   else
      t.id = id
       setmetatable(t, {__index = Node,
                     __tostring = Node.toString})
   end


```
#### DROP

Making DROP work correctly will be somewhat painstaking. 


I don't need it in my short path, so I'm likely to leave it for
now.


Here's notes on the algorithm:


  -  `````D````` consumes the pattern.  If this is the leftmost match, we need
     to adjust `````first````` forward by the length of this capture.


     If it is the rightmost match, we need to adjust `````last````` accordingly.


     Using `````D````` in the middle of a non-terminal capture should simply
     nil out the capture and adjust accordingly.  The effect is the same
     as SUPPRESS but only for that instance of the rule, which needn't be
     a V. 


The use case is for eloquently expression 'wrapper' patterns, which occur
frequently in real languages. In a `````(typical lisp expression)````` we don't need
the parentheses and would like our span not to include them.


We could use a pattern like `````V"formwrap"````` and then SUPPRESS `````formwrap`````, but
this is less eloquent than `````D(P"(") * V"form" *  D(P")")`````. 


Which is admittedly hard to look at.  We prefer the form
`````D(pal) * V":form" * D(par)````` for this reason among others.

```lua
   for i=#t,1,-1 do 
      local v = t[i] 
      if type(v) ~= "table" then
         s:complain("CAPTURE ISSUE", 
                    "type of capture subgroup is " .. type(v) .. "\n")
      end
      if v == DROP then
        s:verb("-- child v of t is DROP")
        table.remove(v)
      end 
   end
   assert(t.isNode, "failed isNode: " .. id)
   assert(t.str)
   return t
end


-- some useful/common lpeg patterns
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
    e = V == " 5.1" and getfenv(func) or _G
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
  if V == " 5.1" then
    setfenv( func, env )
  end
  func( env )
  assert( g[ 1 ] and g[ g[ 1 ] ], "no start rule defined" )
  return g
end
```
```lua
local function refineMetas(metas)
  s:verb("refining metatables")
  for id, meta in pairs(metas) do
    s:verb("  id: " .. id .. " type: " .. type(meta))
    if type(meta) == "table" then
      if not meta["__tostring"] then
        meta["__tostring"] = Node.toString
      end
      if not meta.id then
        s:verb("    inserting metatable id: " .. id)
        meta.id = id
      else
        s:verb("    id of " .. id .. " is " .. meta.id)
      end
    end
  end
  return metas
end
```
```lua
local function new(grammar_template, metas)
  if type(grammar_template) == 'function' then
    local metas = metas or {}
    metas = refineMetas(metas)
    local grammar = define(grammar_template, nil, metas)

    local function parse(str, offset)
      local offset = offset or 0
      return L.match(grammar, str, 1, str, metas, offset) -- other 
    end

    return parse
  else
    s:halt("no way to build grammar out of " .. type(template))
  end
end
```
```lua
return new
```
