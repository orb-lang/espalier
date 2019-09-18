# Parsing Expression Grammar


Now, at last, we are ready to swallow the tail.


Parsing Expression Grammars can be expressed in a format which is itself
grammatical.  We could use this to build Lua code against our Node class,
generating a parser from the description.


So let's do that.

```lua
local L = require "espalier/elpatt"
local D, E, P, R, S, V   =  L.D, L.E, L.P, L.R, L.S, L.V
local Grammar = require "espalier/grammar"
-- local lex = require "espalier/lexemes"
local pegMetas = require "espalier/grammars/pegmeta"
```
```lua
local function pegylator(_ENV)
   START "rules"
   ---[[
   SUPPRESS ("WS",  "enclosed", "form",
            "element" ,
            "elements",
            "allowed_prefixed", "allowed_suffixed",
            "simple", "compound", "prefixed", "suffixed",
            "some_suffix",
            "pel", "per"  )
   --]]
   local comment_m  = -P"\n" * P(1)
   local comment_c =  comment_m^0 * P"\n"^0
   local letter = R"AZ" + R"az"
   local valid_sym = letter + P"-"
   local digit = R"09"
   local sym = valid_sym + digit
   local WS = (P' ' + P'\n' + P'\t' + P'\r')^0
   local symbol = letter * ( -(P"-" * WS) * sym )^0
   local d_string = P "\"" * (P "\\" * P(1) + (1 - P "\""))^0 * P "\""
   local h_string = P "`" * (P "\\" * P(1) + (1 - P "`"))^0 * P "`"
   local s_string = P "'" * (P "\\" * P(1) + (1 - P "'"))^0 * P "'"
   local range_match =  -P"-" * -P"\\" * -P"]" * P(1)
   local range_capture = (range_match + P"\\-" + P"\\]" + P"\\")
   local range_c  = range_capture^1 * P"-" * range_capture^1
   local set_match = -P"}" * -P"\\" * P(1)
   local set_c    = (set_match + P"\\}" + P"\\")^1
   local some_num_c =   digit^1 * P".." * digit^1
                +   (P"+" + P"-")^0 * digit^1


   rules   =  V"rule"^1
   rule    =  V"lead_comment"^0 * V"lhs" * V"rhs"

   lead_comment = V"comment"
   lhs     =  WS * V"pattern" * WS * ( P":" + P"=" + ":=")
   rhs     =  V"form" * (WS * V"comment")^0

   pattern =  symbol
           +  V"hidden_pattern"
           +  V"ws"

   hidden_pattern =  P"`" * symbol * P"`"
                  +  P"`_`"

   -- SUPPRESSED
   form    =  V"element" * V"elements"

   element  =   -V"lhs" * WS
            *  ( V"simple"
            +    V"compound")

   elements  =  V"choice"
             +  V"cat"
             +  P""
   -- /SUPPRESSED

   choice =  WS * P"/" * V"form"
   cat =  WS * V"form"

   -- SUPPRESSED
   compound =  V"group"
          +  V"enclosed"
          +  V"hidden_match"
   -- /SUPPRESSED

   group   =  WS * V"pel"
           *  WS * V"form" * WS
           *  V"per"

   hidden_match =  WS * P"``"
                *  WS * V"form" * WS
                *  P"``"
   -- SUPPRESSED
   pel     = P "("
   per     = P ")"

   simple   =  V"suffixed"
            +  V"prefixed"
            +  V"atom"

   enclosed =  V"literal"
            +  V"hidden_literal"
            +  V"set"
            +  V"range"

   prefixed =  V"if_not_this"
            +  V"not_this"
            +  V"if_and_this"
            +  V"capture"

   suffixed =  V"optional"
            +  V"more_than_one"
            +  V"maybe"
            +  V"with_suffix"
            +  V"some_number"

   allowed_prefixed =  V"compound" + V"suffixed" + V"atom"
   allowed_suffixed =  V"compound" + V"prefixed" + V"atom"

   some_suffix   = P"$" * V"repeats"
   -- these are implicitly suppressed
   with_suffix   =  V"some_number" * V"which_suffix"
   which_suffix  =  ( P"*" + P"+" + P"?")
   -- /SUPPRESSED

   if_not_this = P"!" * WS * V"allowed_prefixed"
   not_this    = P"-" * WS * V"allowed_prefixed"
   if_and_this = P"&" * WS * V"allowed_prefixed"
   capture     = P"~" * WS * V"allowed_prefixed"

   literal =  d_string
           +  s_string

   hidden_literal =  h_string

   set     =  P"{" * set_c^1 * P"}"

-- #Todo
-- Change range to not use '-' separator instead require even # of bytes.
-- Ru catches edge cases involving multi-byte chars.

   range   =  P"[" * V"range_start" * P"-" * V"range_end" * P"]"
   range_start = range_capture
   range_end   = range_capture

   optional      =  V"allowed_suffixed" * WS * P"*"
   more_than_one =  V"allowed_suffixed" * WS * P"+"
   maybe         =  V"allowed_suffixed" * WS * P"?"
   some_number   =  V"allowed_suffixed" * WS * V"some_suffix"

   repeats       =  some_num_c

   comment  =  WS * P";" * comment_c

   atom =  V"ws" + symbol

   ws = P"_"
end
```
## Roadmap

This is not quite a fully-operational Death Star.



- [ ]  #Todo #version @0.0.1alpha


  - [ ]  Get a trivial grammar compiling.


  - [ ]  Write microLisp parser.


  - [ ]  Translate date parser into PEG format and 'complete' it.


         'complete' in air quotes because I'm happy with a parser for the
         most-common subset of ISO 8610 dates, I don't require approximates
         or by-week or the like, not right away.


  - [ ]  Write a Lua parser in PEG format.


         This is of course a prerequisite to release, and will be actively
         used throughout the codebase.

```lua
return Grammar(pegylator, pegMetas)
```
