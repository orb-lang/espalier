# Node Spec


  This is an experiment\. Then again, aren't they all\.

We're converging sessions and Orb documents, and will use all this new
parsing goodness in Orb to start adding the missing bells and whistles\.

In the meantime, this is some combination of user documentation and raw
material for sesssions\.


#### yielding module

This is a weird pattern\.

Sessions reset the *environment* but they don't purge modules and load them
fresh for each session\.

So we wrap everything in an anonymous function call, like this is Javascript
in the mid Teens\.

```lua
return (function()
```


#### Elden

  Our test language is Elden, loosely based on Clojure's EDN, itself best
described as the JSON of Clojure\.

I have a grammar close to this format, for the bootstrap, let's copy\-paste
microlisp\.

```peg
    elden  ←  _ ((atom)+ / list)
     list  ←  pel _ (atom / list)* per _
     atom  ←  _(number / symbol)_
   symbol  ←  _ sym1 sym2*
   `sym1`  ←  (alpha / other)
   `sym2`  ←  (alpha / digit / other)
   number  ←  float / integer
`integer`  ←  [0-9]+
  `float`  ←  [0-9]+ "." [0-9]+ ; expand
    `pel`  ←  '('
    `per`  ←  ')'
  `alpha`  ←  [A-Z]/[a-z]
  `digit`  ←  [0-9]
  `other`  ←  {-_-=+!@#$%^&*:/?.\\~}
      `_`  ←  { \t\r\n,}*
```


### eVav

  For various reasons best explained elsewhere, our subject for constructing
everything is called Vav, which we create in the familiar way with `Vav(peh)`\.

In the underlying theory, Vav is a combinator of Peh, the shape, and Mem,
the topic of this module\.

Lua being, by design, both eager and mutable, our implementation is different
from the theory\.  The latter is an extension of parser combinators, which are
a mathematical abstraction best *discussed* in terms of a lazy and immutable
semantic\.

```lua
local Vav = use "espalier:vav"
```

Our topic therefore being

```lua
local eVav = Vav(elden_peh)
```

Which we apply to Mem to complete the Vav combinator\.

We'll provide a surface area for eVav after defining Mem\.


### Elden Clade

Mem provides all the behavior needed to do useful things with Peh, after the
parser recognizes a string as conforming to Peh's shape\.

```lua
local Elden = require "espalier:peg/nodeclade"
```

This is not the final signature, it can't be, but extending clades is NYI
pending implementation of an extension protocol\.

With the code in the state that it is, let's just give ourselves a nice
closure to make a one\-liner out of getting to Nodes\.

```lua
local function dji()
   return eVav:Mem(Elden):Dji()
end
```


### Walk Spec

```lua
local insert = assert(table.insert)

local function walker()
   local eDji = eVav.dji or dji()
   local one2 = eDji [[ (1 2) ]]
   local tags = {}
   for node in one2:walk() do
      insert(tags, node.tag)
   end
   return tags
end
```


```lua
return { eVav = eVav,
         Elden = Elden,
         walker = walker,
         dji = dji }
```

With a fresh instance for each require:

```lua
end) ()
```



