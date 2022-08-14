# Peg Debugger


Likely to be integrated more closely into the Espalier ecosystem, we begin
with the script as\-is


### Use

```lua
local grammar = require('pegdebug').trace(lpegGrammar, traceOptions)
lpeg.match(lpeg.P(grammar),"subject string")
```


#### License


```license
Copyright (C) 2014 Paul Kulchenko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```


## PegDebug

```lua
--
-- PegDebug -- A debugger for LPeg expressions and processing
-- Copyright 2014 Paul Kulchenko
--

local lpeg = require "lpeg"

local Cmt = lpeg.Cmt
local Cp  = lpeg.Cp
local P   = lpeg.P

local pegdebug = {
  _NAME = "pegdebug",
  _VERSION = 0.41,
  _COPYRIGHT = "Paul Kulchenko",
  _DESCRIPTION = "Debugger for LPeg expressions and processing",
}

function pegdebug.trace(grammar, opts)
  opts = opts or {}
  local serpent = opts.serializer
    or pcall(require, "serpent") and require("serpent").line
    or pcall(require, "mobdebug") and require("mobdebug").line
    or nil
  local function line(s) return (string.format("%q", s):gsub("\\\n", "\\n")) end
  local function pretty(...)
    if serpent then return serpent({...}, {comment = false}):sub(2,-2) end
    local res = {}
    for i = 1, select('#', ...) do
      local v = select(i, ...)
      local tv = type(v)
      res[i] = tv == 'number' and v or tv == 'string' and line(v) or tostring(v)
    end
    return table.concat(res, ", ")
  end
  local level = 0
  local start = {}
  local print = print
  if type(opts.out) == 'table' then
    print = function(...) table.insert(opts.out, table.concat({...}, "\t")) end
  end
  for k, p in pairs(grammar) do
    local enter = Cmt(P(true), function(s, p, ...)
        start[level] = p
        if opts['+'] ~= false then
          print((" "):rep(level).."+", k, p, line(s:sub(p,p)))
        end
        level = level + 1
        return true
      end)
    local leave = Cmt(P(true), function(s, p, ...)
        level = level - 1
        if opts['-'] ~= false then
          print((" "):rep(level).."-", k, p)
        end
        return true
      end) * (P(1) - P(1))
    local eq = Cmt(P(true), function(s, p, ...)
        level = level - 1
        if opts['='] ~= false then
          print((" "):rep(level).."=", k, start[level]..'-'..(p-1), line(s:sub(start[level],p-1)))
        end
        return true
      end)
    if k ~= 1 and (not opts.only or opts.only[k]) then
      if opts['/'] ~= false
      and (type(opts['/']) ~= 'table' or opts['/'][k] ~= false) then
        -- Cp() is needed to only get captures (and not the whole match)
        p = Cp() * p / function(pos, ...)
            print((" "):rep(level).."/", k, pos, select('#', ...), pretty(...))
            return ...
          end
      end
      grammar[k] = enter * p * eq + leave
    end
  end
  return grammar
end

return pegdebug
```
