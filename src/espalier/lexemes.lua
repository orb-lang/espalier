


















local L = require "lpeg"
local P, R, S, match = L.P, L.R, L.S, L.match
local sub, gsub = assert(string.sub), assert(string.gsub)
local concat = assert(table.concat)
local c = require "singletons/color"
local codepoints = assert(string.codepoints)











local Lex = meta {}



local WS = (P" ")^1

local NL = P"\n"

local terminal = S" \"'+-*^~%#;,<>={}[]().:\n" + -P(1)

local KW = (P"function" + "local" + "for" + "in" + "do"
           + "and" + "or" + "not" + "true" + "false"
           + "while" + "break" + "if" + "then" + "else" + "elseif"
           + "goto" + "repeat" + "until" + "return" + "nil"
           + "end") * #terminal

local OP = P"+" + "-" + "*" + "/" + "%" + "^" + "#"
           + "==" + "~=" + "<=" + ">=" + "<" + ">"
           + "=" + "(" + ")" + "{" + "}" + "[" + "]"
           + ";" + ":" + "..." + ".." + "." + ","

local digit = R"09"

local _decimal = P"-"^0 * ((digit^1 * P"."^-1 * digit^0
                           * ((P"e" + P"E")^-1 * P"-"^-1 * digit^1)^-1
                        + digit^1)^1 + digit^1)

local higit = R"09" + R"af" + R"AF"

-- hexadecimal floats. are a thing. that exists. in luajit.
local _hexadecimal = P"-"^0 * P"0" * (P"x" + P"X")
                        * ((higit^1 * P"."^-1 * higit^0
                           * ((P"p" + P"P")^-1 * P"-"^-1 * higit^1)^-1
                        + higit^1)^1 + higit^1)

-- long strings, straight from the LPEG docs
local _equals = P"="^0
local _open = "[" * L.Cg(_equals, "init") * "[" * P"\n"^-1
local _close = "]" * L.C(_equals) * "]"
local _closeeq = L.Cmt(_close * L.Cb("init"),
                          function (s, i, a, b) return a == b end)

local long_str = (_open * L.C((P(1) - _closeeq)^0) * _close) / 0 * L.Cp()

local str_esc = P"\\" * (S"abfnrtvz\\\"'[]\n"
                         + (R"09" * R"09"^-2)
                         + (P"x" + P"X") * higit * higit)

local double_str = P"\"" * (P(1) - (P"\"" + P"\\") + str_esc)^0 * P"\""
local single_str = P"\'" * (P(1) - (P"\'" + P"\\") + str_esc)^0 * P"\'"

local string_short = double_str + single_str

local string_long = long_str

local letter = R"az" + R"AZ"

local symbol =   (letter^1 + P"_"^1)
               * (letter + digit + P"_")^0
               * #terminal

local number = _hexadecimal + _decimal

local comment = P"--" * long_str
              + P"--" * (P(1) - NL)^0 * (NL + - P(1))

local ERR = P(1)



return { lua = { number      = number,
                 digit       = digit,
                 symbol      = symbol,
                 comment     = comment,
                 string      = string_short,
                 string_long = string_long,
                 WS          = WS,
                 terminal    = terminal,
                 keyword     = KW,
                 operator    = OP },
         digit  = digit,
         number = number,
         string = { str    = string_short,
                    single = single_str,
                    double = double_str },
         higit   = higit,
         hex     = _hexadecimal,
         decimal = _decimal,
         letter  = { latin = letter } }
