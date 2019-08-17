














































































local Node    =  require "espalier/node"
local Grammar =  require "espalier/grammar"
local L       =  require "espalier/elpatt"

local P, R, E, V, S    =  L.P, L.R, L.E, L.V, L.S

local lex     =  require "espalier/lexemes"


























local _do, _end, _then = P"do", P"end", P"then"

local function lua_fn(ENV)
   local K = P -- this is a hack

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
              ( P"elseif" * V"exp" * _then * V"block" )^0 *
              ( P"else" * V"block" )^-1 * _end +
           P"for" * V"Name" * P"=" * V"exp" * P"," * V"exp" *
              ( P"," * V"exp" )^-1 * _do * V"block" * _end +
           P"for" * V"namelist" * P"in" * V"explist" * _do *
              V"block" * _end +
           P"function" * V"funcname" * V"funcbody" +
           P"local" * P"function" * V"Name" * V"funcbody" +
           P"local" * V"namelist" * ( P"=" * V"explist" )^-1

   laststat = P"return" * V"explist"^-1 + P"break"

   funcname = V"Name" * ( P"." * V"Name" )^0 * ( P":" * V"Name" )

   varlist  = V"var" * ( P"," * V"var")^0

   var      = V"Name"
            + V"prefixexp" * P"[" * V"exp" * P"]"
            + V"prefixexp" * "." * V"Name"

   namelist = V"Name" * ( V"exp" * ",")^0 * V"exp"

   explist  = (V"exp" * P",")^0 * V"exp"






-- Let's come up with a syntax that does not use left recursion
  -- (only listing changes to Lua 5.1 extended BNF syntax)
  -- value ::= nil | false | true | Number | String | '...' | function |
  --           tableconstructor | functioncall | var | '(' exp ')'
  -- exp ::= unop exp | value [binop exp]
  -- prefix ::= '(' exp ')' | Name
  -- index ::= '[' exp ']' | '.' Name
  -- call ::= args | ':' Name args
  -- suffix ::= call | index
  -- var ::= prefix {suffix} index | Name
  -- functioncall ::= prefix {suffix} call

  -- Something that represents a value (or many values)
  value = K "nil" +
          K "false" +
          K "true" +
          V "Number" +
          V "String" +
          P "..." +
          V "func" +
          V "tableconstructor" +
          V "functioncall" +
          V "var" +
          P "(" * V "space" * V "exp" * V "space" * P ")";

  -- An expression operates on values to produce a new value or is a value
  exp = V "unop" * V "space" * V "exp" +
        V "value" * (V "space" * V "binop" * V "space" * V "exp")^-1;

  -- Index and Call
  index = P "[" * V "space" * V "exp" * V "space" * P "]" +
          P "." * V "space" * V "Name";
  call = V "args" +
         P ":" * V "space" * V "Name" * V "space" * V "args";

  -- A Prefix is a the leftmost side of a var(iable) or functioncall
  prefix = P "(" * V "space" * V "exp" * V "space" * P ")" +
           V "Name";
  -- A Suffix is a Call or Index
  suffix = V "call" +
           V "index";

  var = V "prefix" * (V "space" * V "suffix" * #(V "space" * V "suffix"))^0 *
            V "space" * V "index" +
        V "Name";
  functioncall = V "prefix" *
                     (V "space" * V "suffix" * #(V "space" * V "suffix"))^0 *
                 V "space" * V "call";

  explist = V "exp" * (V "space" * P "," * V "space" * V "exp")^0;

  args = P "(" * V "space" * (V "explist" * V "space")^-1 * P ")" +
         V "tableconstructor" +
         V "String";

  func = K "function" * V "space" * V "funcbody";

  funcbody = P "(" * V "space" * (V "parlist" * V "space")^-1 * P ")" *
                 V "space" *  V "block" * V "space" * K "end";

  parlist = V "namelist" * (V "space" * P "," * V "space" * P "...")^-1 +
            P "...";

  tableconstructor = P "{" * V "space" * (V "fieldlist" * V "space")^-1 * P "}";

  fieldlist = V "field" * (V "space" * V "fieldsep" * V "space" * V "field")^0
                  * (V "space" * V "fieldsep")^-1;

  field = P "[" * V "space" * V "exp" * V "space" * P "]" * V "space" * P "=" *
              V "space" * V "exp" +
          V "Name" * V "space" * P "=" * V "space" * V "exp" +
          V "exp";

  fieldsep = P "," +
             P ";";

  binop = K "and" + -- match longest token sequences first
          K "or" +
          P ".." +
          P "<=" +
          P ">=" +
          P "==" +
          P "~=" +
          P "+" +
          P "-" +
          P "*" +
          P "/" +
          P "^" +
          P "%" +
          P "<" +
          P ">";

  unop = P "-" +
         P "#" +
         K "not";














   Name      = lex.lua.symbol
   String    = lex.lua.string
   Number    = lex.lua.number
   Comment   = lex.lua.comment
   space     = lex.lua.WS
end




















return Grammar(lua_fn)
