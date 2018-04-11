# Stator


  Having gotten about as far as I can with mere string concatenation, it's 
time to put together a proper set of operations for transducing across a
Node. 


This isn't a great place to put theory, let's build the structure and 
flesh out from there.

```lua
local Stator = setmetatable({}, {__index = Stator})
```
## Constructor

We set up a new stator on each Node we're transducing, so we want it to
be quick and cheap.


I recommend either lifting this method or providing an override if 
subclassing Stator. 

```lua
function call(stator)
  return setmetatable({}, {__index = stator, __call = call })
end
```
## New

The root Stator has a global context, which is itself.  This is given
the synonyms ``G``, ``g`` and ``_G``, to suit various styles. 

```lua
function new(Stator)
  local stator = call(Stator)
  stator.g, stator.G, stator._G = stator, stator, stator
  return stator
end
```
```lua
return setmetatable(Stator, {__call = new})
```