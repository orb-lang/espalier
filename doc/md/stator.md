# Stator


  Having gotten about as far as I can with mere string concatenation, it's
time to put together a proper set of operations for transducing across a
Node\.

This isn't a great place to put theory, let's build the structure and
flesh out from there\.

\#todo


#### asserts

```lua
local setmeta = assert(setmetatable)
```

```lua
local Stator = meta {}
```


## Weak Table

I imagine we'll want weak references to every state keyed by Node, so

```lua
-- local _weakstate = setmeta({}, {__mode = 'v'})
```

One of these will be closed over a Stator\.

## Constructor

We set up a new stator on each Node we're transducing, so we want it to
be quick and cheap\.

\#todo
       right, we need to call with one argument for a root, say Doc from Orb\.

       Then subsequent Stator creation passes in the single `_weakstate`
       table, which will shall populate by and by\.

```lua
local function call(stator, _weakstate)
   local _weakstate = _weakstate or setmeta({}, {__mode = 'v'})
   local _M = setmeta({}, {__index = stator, __call = call })
   _M._weakstate =  _weakstate
   return _M
end
```


## New

The root Stator has a global context, which is itself\.  This is given
the synonyms `G`, `g` and `_G`, to suit various styles\.

```lua
local function new(Stator, _weakstate)
   local stator = call(Stator, _weakstate)
   stator.g, stator.G, stator._G = stator, stator, stator
   return stator
end
```


```lua
return setmetatable(Stator, {__call = new})
```