









local L = require "lpeg"
local elpatt = {}

local Cc = L.Cc





















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

function elpatt.D(patt)
   return (patt / 0) * Cc(DROP)
end





return elpatt
