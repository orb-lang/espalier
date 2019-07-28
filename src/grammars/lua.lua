














































































local Node    =  require "espalier/node"
local Grammar =  require "espalier/grammar"
local L       =  require "espalier/elpatt"

local P, R, E, V, S    =  L.P, L.R, L.E, L.V, L.S




















local _do, _end, _then = P"do", P"end", P"then"

local function lua_fn(ENV)
   START "lua"
   lua   = V"chunk"^1
   chunk = (V"stat" * P";"^0) * (V"laststat"^0 * P";"^0)^-1
   block = V"chunk"












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
end
