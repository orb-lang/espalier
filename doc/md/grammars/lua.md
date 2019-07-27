# A Grammer For Lua

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

```lua
local function lua_fn(ENV)
   START "lua"
   lua = V"chunk"^1
end
```
