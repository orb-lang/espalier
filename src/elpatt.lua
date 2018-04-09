









local L = require "lpeg"
local s = require "status" ()
s.verbose = false
local Node = require "node"
local elpatt = {}
elpatt.P, elpatt.B, elpatt.V, elpatt.R = L.P, L.B, L.V, L.R

local P, C, Cc, Cp, Ct, Carg = L.P, L.C, L.Cc, L.Cp, L.Ct, L.Carg





















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




























local DROP = {}

elpatt.DROP = DROP

local function make_drop(caps)
   local dropped = setmetatable({}, DROP)
   dropped.DROP = true
   dropped.first = caps[1]
   dropped.last = caps[3]
   return dropped
end

function elpatt.D(patt)  
   return Ct(Cp() * Ct(patt) * Cp()) / make_drop
end













local Err = Node:inherit()
Err.id = "ERROR"

function Err.toLua(err)
  return "gabba gabba he"
end


local function parse_error(pos, name, msg, patt, str)
   local message = msg or name or "Not Otherwise Specified"
   io.write("remaining: " .. string.sub(str, pos) .. "\n")
   s:complain("Parse Error: ", message)
   local errorNode =  setmetatable({}, Err)
   errorNode.first =  pos
   errorNode.last  =  pos
   errorNode.msg   =  msg
   errorNode.name  =  name
   errorNode.str   =  str
   errorNode.rest  =  string.sub(str, pos)
   errorNode.patt  =  patt

   return errorNode
end

function elpatt.E(name, msg, patt)
  return Cp() * Cc(name) * Cc(msg) * Cc(patt) * Carg(1) / parse_error
end

function elpatt.EOF(name, msg)
  return -P(1) + elpatt.E(name, msg)
end













function elpatt.S(a, ...)
   if not a then return nil end
   local arg = {...}
   local set = P(a)
   for _, patt in ipairs(arg) do
      set = set + P(patt)
   end
   return set
end



return elpatt
