# A Grammar For Lua

While the most important grammar for pegylator is pegylator itself, it's
time to make a Lua language parser.


The hard work is done on this, it's a matter of translation into the
Pegylator paradigm.


While this a hell of a lot of work, the complete BNF of Lua is available,
and reproduced here.

```bnf
chunk ::= {stat [`;´]} [laststat [`;´]]

   block ::= chunk

   stat ::=  varlist `=´ explist |
       functioncall |
       do block end |
       while exp do block end |
       repeat block until exp |
       if exp then block {elseif exp then block} [else block] end |
       for Name `=´ exp `,´ exp [`,´ exp] do block end |
       for namelist in explist do block end |
       function funcname funcbody |
       local function Name funcbody |
       local namelist [`=´ explist]

   laststat ::= return [explist] | break

   funcname ::= Name {`.´ Name} [`:´ Name]

   varlist ::= var {`,´ var}

   var ::=  Name | prefixexp `[´ exp `]´ | prefixexp `.´ Name

   namelist ::= Name {`,´ Name}

   explist ::= {exp `,´} exp

   exp ::=  nil | false | true | Number | String | `...´ | function |
       prefixexp | tableconstructor | exp binop exp | unop exp

   prefixexp ::= var | functioncall | `(´ exp `)´

   functioncall ::=  prefixexp args | prefixexp `:´ Name args

   args ::=  `(´ [explist] `)´ | tableconstructor | String

   function ::= function funcbody

   funcbody ::= `(´ [parlist] `)´ block end

   parlist ::= namelist [`,´ `...´] | `...´

   tableconstructor ::= `{´ [fieldlist] `}´

   fieldlist ::= field {fieldsep field} [fieldsep]

   field ::= `[´ exp `]´ `=´ exp | Name `=´ exp | exp

   fieldsep ::= `,´ | `;´

   binop ::= `+´ | `-´ | `*´ | `/´ | `^´ | `%´ | `..´ |
       `<´ | `<=´ | `>´ | `>=´ | `==´ | `~=´ |
       and | or

   unop ::= `-´ | not | `#´
```
## Implementation

Let's try it.


### Imports

```lua
local Node    =  require "espalier/node"
local Grammar =  require "espalier/grammar"
local L       =  require "espalier/elpatt"

local P, R, E, V, S    =  L.P, L.R, L.E, L.V, L.S
```
### lua_fn

This is provided to the Grammar engine to create a Lua parser.


- #Todo this being a 5.1 grammar, need to add goto statements.


- #Todo add the whitespace


- #Todo add precedence parsing of ``exp``


## The Grammar of the Lua Language

A Lua program consists of one or more ``chunks``, which are
anonymous functions.

```lua
local _do, _end, _then = P"do", P"end", P"then"

local function lua_fn(ENV)
   START "lua"
   lua   = V"chunk"^1
   chunk = (V"stat" * P";"^0) * (V"laststat"^0 * P";"^0)^-1
   block = V"chunk"
```
### Statement

Lua is a statement-oriented language in which expressions are
a special case.


Thus ``2 + 3`` is not a valid Lua program, whereas ``return 2 + 3``
is, and is equivalent to ``(function() return 2 + 3 end)()``

```lua
   stat  = V"varlist" * P"=" * V"explist" +
           V"functioncall" +
           _do * V"block" * _end +
           P"while" * V"exp" * _do * V"block" * _end +
           P"repeat" * V"block" * P"until" * _end +
           P"if" * V"exp" * _then * V"block" *
              ( P"elseif" V"exp" * _then * V"block" )^0 *
              ( P"else" * V"block" )^-1 * _end +
           P"for" * V"Name" * P"=" * V"exp" * P"," * V"exp" *
              ( P"," * V"exp" )^-1 * _do * V"block" * _end +
           P"for" * V"namelist" * P"in" * V"explist" * _do *
              V"block" * _end +
           P"function" * V"funcname" * V"funcbody" +
           P"local" * P"function" * V"Name" * V"funcbody" +
           P"local" * V"namelist" * ( P"=" * V"explist" )^-1

   laststat = P"return" * V"explist"^-1 + P"break"

   funcname = V"Name" * ( P"." * V"Name" )^0 * ( P":" V"Name" )

   varlist  = V"var" * ( P"," V"var")^0

   var      = V"Name" + V"prefixexp" * P"[" * V"exp" * P"]" +
                 V"prefixexp" * "." * V"Name"

   namelist = V"Name" * ( V"exp" * ",")^0 * V"exp"

   explist  = (V"exp" *)^0 * V"exp"
```
### Expressions

Expressions are necessarily somewhat complex because of
operator precedence; Lua has fewer operators than languages
such as C, but this translation from the grammar will require
further elaboration to correctly resolve order of operations.

```lua
   exp      = P"nil" + P"false" + P"true"
              + V"Number" + V"String" + P"..." + V"fn"
              + V"prefixexp" + V"tableconstructor"
              + V"exp" * V"binop" * V"exp"
              + V"unop" * V"exp"

   prefixexp = V"var" + V"functioncall" + P"(" * V"exp" * P")"

   functioncall = V"prefixexp" * V"args" +
                  V"prefixexp" * P":" * V"Name" * V"args"

   args      = P"(" * V"explist"^0 * P")"
               + V"tableconstructor"
               + V"String"

   fn        = P"function" * V"funcbody"

   funcbody  = P"(" * V"parlist"^0 * P")" * V"block" * _end

   parlist   = V"namelist" ( P"," * P"...") + P"..."

   tableconstructor = P"{" * V"fieldlist"^0 * P"}"

   fieldlist = V"field" * ( V"fieldsep" * V"field" )^1 * V"fieldsep"^0

   field     = P"[" * V"exp" * P"]" * P"=" * V"exp"
               + V"exp"

   fieldsep  = P"," * P";"

   binop     = P"+" + P"-" + P"*" + P"/" + P"^" + P"%" + P".."
               + P"<" + P"<=" + P">" + P">=" + P"==" + P"~=" +
               + P"and" + P"or"

   unop      = P"-" + P"not" + P"#"
end
```
### Afterword

So there's a first-pass at a literal transcription of the Lua 5.1 spec into
LPEG/espalier format.


There's bound to be some spelling errors in there, such as a ``+`` where I
meant ``*``, but in writing out the spec I'm fairly sure I won't need to
rewrite terms to compensate for direct left recursion.


I do need to add whitespace, ``goto`` statements and labels, and get ``espalier``
running in ``femto``, which isn't happening yet due to remaining problems with
the modules system.


















