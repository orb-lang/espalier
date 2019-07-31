# Error



Rather than throwing errors, we prefer to add them to the parse tree in some
cases.


Optionally, we can include a pattern which, if the parse were to be correct,
would succeed. So a ``( ])`` type error could be "fail to close (" and =P")".

### includes #nw

```lua
local L   = require "lpeg"
local s   = require "singletons:status" ()
local Carg, Cc, Cp, P = L.Carg, L.Cc, L.Cp, L.P
```
```lua
local Err = require "espalier/node" : inherit()
Err.id = "ERROR"

```
#### Err.toLua #remove

This is while I work on having grammars catch terminal Errors.

```lua
function Err.toLua(err)
  local line, col = err:linePos(err.first)
  s:halt("ERROR at line: " .. line .. " col: " .. col)
end
```

We want parse_error to be able to return the actual point of failure,
which I think involves a match-time capture. In the meantime,
``err.last`` is set to be ``#str``.

```lua
local function parse_error(pos, name, msg, patt, str)
   local message = msg or name or "Not Otherwise Specified"
   s:verb("Parse Error: ", message)
   local errorNode =  setmetatable({}, Err)
   errorNode.first =  pos
   errorNode.last  =  #str -- See above
   errorNode.msg   =  message
   errorNode.name  =  name
   errorNode.str   =  str
   errorNode.rest  =  string.sub(str, pos)
   errorNode.patt  =  patt

   return errorNode
end

```
### Err.Err, Err.E : Capture an Error

For now these are synonyms. ``E`` will eventually use a back capture ``B`` at
the beginning of a rule, and a match-time at the end, to provide a
sensible, bookended approach to error diagnosis and possible recovery.


``Err`` is the catchbucket, that simply succeeds and poisons the AST if
non-terminal. It will at least prominently yell "ERROR" at you given
the least opportunity.

```lua
function Err.Err(name, msg, patt)
  return Cp() * Cc(name) * Cc(msg) * Cc(patt) * Carg(1) / parse_error
end

Err.E = Err.Err

function Err.EOF(name, msg)
  return -P(1) + Err.Err(name, msg), Cp()
end

return Err
```
