











local L = require "espalier/elpatt"
local D, E, P, R, S, V   =  L.D, L.E, L.P, L.R, L.S, L.V
local Grammar = require "espalier/grammar"
local pegMetas = require "espalier/grammars/pegmeta"



local function pegylator(_ENV)
   START "rules"
   ---[[
   SUPPRESS ("enclosed", "form",
            "element" , "WS",
            "elements",
            "allowed_prefixed", "allowed_suffixed",
            "simple", "compound", "prefixed", "suffixed",
            "some_suffix",
            "pel", "per"  )
   --]]
   local comment_m  = -P"\n" * P(1)
   local comment_c =  comment_m^0 * P"\n"^0
   local letter = R"AZ" + R"az"
   local valid_sym = letter + P"-" + P"_"
   local digit = R"09"
   local sym = valid_sym + digit
   local symbol = letter * (sym)^0
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
   rule    =  V"lhs" * V"rhs"


   lhs     =  V"WS" * V"pattern" * V"WS" * (P"=" + ":=" + P"<-" + P"←")
   rhs     =  V"form" * V"WS"

   pattern =  symbol
           +  V"hidden_pattern"
           +  V"ws"

   hidden_pattern =  P"`" * symbol * P"`"
                  +  P"`_`"

   -- SUPPRESSED
   form    =  V"element" * V"elements"

   element  =   -V"lhs" * V"WS"
            *  ( V"simple"
            +    V"compound")

   elements  =  V"choice"
             +  V"cat"
             +  P""
   -- /SUPPRESSED

   choice =  V"WS" * P"/" * V"form"
   cat =  V"WS" * V"form"

   -- SUPPRESSED
   compound =  V"group"
          +  V"enclosed"
          +  V"hidden_match"
   -- /SUPPRESSED

   group   =  V"WS" * V"pel"
           *  V"WS" * V"form" * V"WS"
           *  V"per"

   hidden_match =  V"WS" * P"``"
                *  V"WS" * V"form" * V"WS"
                *  P"``"
   -- SUPPRESSED
   pel     = P "("
   per     = P ")"

   simple   =  V"suffixed"
            +  V"atom"
            +  V"prefixed"
            +  V"number"

   enclosed =  V"literal"
            +  V"hidden_literal"
            +  V"set"
            +  V"range"

   prefixed =  V"if_not_this"
            +  V"if_and_this"
            +  V"not_this"

   suffixed =  V"zero_or_more"
            +  V"more_than_one"
            +  V"optional"
            +  V"with_suffix"
            +  V"some_number"

   allowed_prefixed =  V"compound" + V"suffixed" + V"atom" + V"number"
   allowed_suffixed =  V"compound" + V"prefixed" + V"atom" + V"number"

   some_suffix   = P"$" * V"repeats"
   -- these are implicitly suppressed
   with_suffix   =  V"some_number" * V"which_suffix"
   which_suffix  =  ( P"*" + P"+" + P"?")
   -- /SUPPRESSED

      not_this = P"-" * V"WS" * V"allowed_prefixed"
   if_not_this = P"!" * V"WS" * V"allowed_prefixed"
   if_and_this = P"&" * V"WS" * V"allowed_prefixed"

   literal =  d_string
           +  s_string

   hidden_literal =  h_string

   set     =  P"{" * set_c^1 * P"}"

   range   =  P"[" * V"range_start" * P"-" * V"range_end" * P"]"
   range_start = range_capture
   range_end   = range_capture

   zero_or_more  =  V"allowed_suffixed" * V"WS" * P"*"
   more_than_one =  V"allowed_suffixed" * V"WS" * P"+"
   optional         =  V"allowed_suffixed" * V"WS" * P"?"
   some_number   =  V"allowed_suffixed" * V"WS" * V"some_suffix"

   repeats       =  some_num_c

   comment  =  P";" * comment_c

   atom =  V"ws" + symbol

   number = digit^1

   WS = V"comment" + (P' ' + P'\n' + P'\t' + P'\r')^0

   ws = P"_"
end



return Grammar(pegylator, pegMetas)
