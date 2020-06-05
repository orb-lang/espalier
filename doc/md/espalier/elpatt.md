# Extended Lpeg module


  This is where we add extended captures a la the old `epeg`
module\.

The difference here is that we include lpeg as a metatable \_\_index
and can therefore use elpeg as L everywhere we currently use lpeg\.

```lua
local L = require "lpeg"
local s = require "singletons" . status ()
s.verbose = false
local Node = require "espalier/node"
local elpatt = {}
elpatt.P, elpatt.B, elpatt.V, elpatt.R = L.P, L.B, L.V, L.R

local P, C, Cc, Cp, Ct, Carg = L.P, L.C, L.Cc, L.Cp, L.Ct, L.Carg
```

### Errors

```lua
local Err = require "espalier/error"
elpatt.E, elpatt.EOF = Err.E, Err.EOF
```

## Ppt : Codepoint pattern \#Todo

Captures one Unicode point

I actually have no idea how to do this yet\.\.\.

Looks like byte 97 is just `\97` in Lua\. That's easy enough\.


### num\_bytes\(str\)

Captures the number of bytes in the next codepoint of a string\.

The string must be well\-formed utf\-8, more precisely, a malformed
string will return `nil`\.  A zero byte is correctly allowed by the
standard and will match here\.

```lua
local function num_bytes(str)
--returns the number of bytes in the next character in str
   local c = str:byte(1)
   if type(c) == 'number' then
      if c >= 0x00 and c <= 0x7F then
         return 1
      elseif c >= 0xC2 and c <= 0xDF then
         return 2
      elseif c >= 0xE0 and c <= 0xEF then
         return 3
      elseif c >= 0xF0 and c <= 0xF4 then
         return 4
      end
   end
end
```


## D : Drop a capture

  We discourage the use of captures in the Node class\.  The architecture
requires that all array values of a Node table be themselves Nodes\. This is
frequently checked for, in that we use `isNode` to filter in iterators etc,
but this is defensive and will be phased out\.

The use of SUPPRESS lets us drop rules that we don't want to see in the
final AST\.  A normal approach to parsing has explicit captures, but this is
inelegant compared to treating any Node without children as a leaf\.

What about regions of text that don't interest us?  Canonically this
includes whitespace\.  For those occasions, we have `elpatt.D`\.

`D` needs to take a pattern, and if it succeeds in matching it, return a
special table, while discarding the captures if any\. In `define`, we will
check for this table, and drop it whenever encountered\.


  \- patt :  The pattern to match and drop

  \- \#return : descendant of special table DROP

```lua

local DROP = {}
elpatt.DROP = DROP

local function make_drop(caps)
   local dropped = setmetatable({}, DROP)
   dropped.DROP = DROP
   dropped.first = caps[1]
   dropped.last = caps[3]
   return dropped
end

function elpatt.D(patt)
   return Ct(Cp() * Ct(patt) * Cp()) / make_drop
end

```




### S : Capture set

  Uses ordered choice to create a pattern which will match any provided
pattern\.

This will patternize anything you feed it, which is convenient for strings\.

Despite being called "Set", it makes no attempt at uniqueness and will
match against patterns in the order provided\.

```lua
function elpatt.S(a, ...)
   if not a then return nil end
   local arg = {...}
   local set = P(a)
   for _, patt in ipairs(arg) do
      set = set + P(patt)
   end
   return set
end
```

```lua
return elpatt
```