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
local Set = core.set
local insert, remove, concat = assert(table.insert),
                               assert(table.remove),
                               assert(table.concat)
local s = require "status:status" ()
```


### Qualia

This strikes me as a good place to start\.

```lua
local Q = {}
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


## Analysis


### What is a 'rule'

One of the first things we do is 'reify' the rule structure by assigning
names to any rule which doesn't have one\.  So a rule is any pattern which
recognizes some area of a string in some context\.

The product of Dji may or may not be in a position to work with phantom or
suppressed rules, it may in fact ignore rule structure completely if it is,
say, a validator\.


#### lock rules

A rule is a lock if, once the containing rule has succeeded against this rule,
the container must either succeed the rest of the rule or fail: specifically
it cannot backtrack past a lock rule and succeed\.

Example being `"` for a string and so on, some of them are easy to spot but I
do expect that rules like `("k" b "y") / ("K" B "Y")` will be more
interesting, this is really two rules tried one after the other and inlined,
the rule itself doesn't have a lock but rather two\.  Noting that it has two
locks is easier than reducing the **lock** partof the rule to `{Kk}`\.


#### gate rules

A rule is a gate if it must be passed for the containing rule to succeed\.
