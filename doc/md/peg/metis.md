# Metis

The metatables responsible for building the Vav combinator\.


### Pasta

We birth this as just plain ol' pegmeta\.

The difference shall be that this performs all steps prior to binding to a
Qoph because this **is** determinate of codegen methodology\.


#### imports

```lua
local Node = require "espalier:espalier/node"
local Grammar = require "espalier:espalier/grammar"
local Seer   = require "espalier:espalier/recognize"
local Phrase = require "singletons/phrase"
local core = require "qor:core" -- #todo another qor
local insert, remove, concat = assert(table.insert),
                               assert(table.remove),
                               assert(table.concat)
local s = require "status:status" ()
```






### Metabuilder

  This pattern goes into its own module eventually/soon/as part of what I'm
doing right now\.

Lets us automatically build a metatable for class `something` by indexing
`Metas.something`\.

I'm tempted to do something automagic with `Metas.Something` but like, not,
right now\.


#### Twig

This is clearly part of what a generator does automatically *but*

```lua
local Twig = Node :inherit()
```


```lua
local function __index(metabuild, key)
   metabuild[key] = Twig :inherit(key)
   return metabuild[key]
end
```

```lua
local M = setmetatable({}, {__index = __index})
```


##### And— Scene

It's my birthday and there's only so much of this I actually wish to do\.