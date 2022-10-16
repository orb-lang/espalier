# Node Spec


  This is an experiment\. Then again, aren't they all\.

We're converging sessions and Orb documents, and will use all this new
parsing goodness in Orb to start adding the missing bells and whistles\.

In the meantime, this is some combination of user documentation and raw
material for sesssions\.

```lua
local elden = use "cluster:library" ()
```


#### Elden

  Our test language is Elden, loosely based on Clojure's EDN, itself best
described as the JSON of Clojure\.

I have a grammar close to this format, for the bootstrap, let's copy\-paste
microlisp\.

```peg
lisp = _ ((atom)+ / list)
list = pel _ (atom / list)* per _
atom = _(number / symbol)_
symbol = _(alpha / other) (alpha / digit / other)*_
number = float / integer
`integer` = [0-9]+
`float` = [0-9]+ "." [0-9]+ ; expand
`pel` = '('
`per` = ')'
`alpha` = [A-Z]/[a-z]
`digit` = [0-9]
`other` = {-_-=+!@#$%^&*:/?.\\~}
  `_`     = { \t\r\n,}*
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
Vav = use "espalier:vav"
```

Our topic therefore being

```lua
eVav = Vav(elden_peh)
```

Which we apply to Mem to complete the Vav combinator\.

We'll provide a surface area for eVav after defining Mem\.


### Elden Clade

Mem provides all the behavior needed to do useful things with Peh, after the
parser recognizes a string as conforming to Peh's shape\.

```lua
Elden = require "espalier:peg/nodeclade"
```

This is not the final signature, it can't be, but extending clades is NYI
pending implementation of an extension protocol\.

With the code in the state that it is, let's just give ourselves a nice
closure to make a one\-liner out of getting to Nodes\.

```lua
function dji()
   return eVav:Mem(Elden):Dji()
end
```

```lua
return elden
```



