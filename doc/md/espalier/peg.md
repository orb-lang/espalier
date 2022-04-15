# Parsing Expression Grammar


Now, at last, we are ready to swallow the tail\.

Parsing Expression Grammars can be expressed in a format which is itself
grammatical\.  We could use this to build Lua code against our Node class,
generating a parser from the description\.

So let's do that\.

#### Imports

```lua
local L = require "espalier/elpatt"
local P, R, V = L.P, L.R, L.V
local Grammar = require "espalier:espalier/grammar"
local pegMetas = require "espalier:espalier/pegmeta"
```


## Pegylator: A Parsing Expression Grammar for Parsing Expression Grammars

```lua
local function pegylator(_ENV)
   START "rules"
   ---[[
   SUPPRESS ("enclosed", "form",
            "element" , "WS",
            "elements", "allowed_repeated",
            "allowed_prefixed", "allowed_suffixed", "allowed_referred",
            "simple", "compound", "prefixed", "suffixed",
            "referred", "named_suffix", "back_referred", "equal_referred",
            "greater_equal_referred", "greater_referred",
            "lesser_equal_referred", "lesser_referred",
            "pel", "per" )
   --]]
   local comment_m  = -P"\n" * P(1)
   local comment_c =  comment_m^0
   local letter = R"AZ" + R"az"
   local valid_sym = letter + P"-" + P"_"
   local digit = R"09"
   local sym = valid_sym + digit
   local symbol = letter * (sym)^0
   local d_string = P "\"" * (P "\\" * P(1) + (1 - P "\""))^0 * P "\""
   local h_string = P "`" * (P "\\" * P(1) + (1 - P "`"))^0 * P "`"
   local s_string = P "'" * (P "\\" * P(1) + (1 - P "'"))^0 * P "'"
   local range_match =  -P"-" * -P"\\" * -P"]" * P(1)
   local range_capture = (range_match + P"\\-" + P"\\]" + P"\\")^1
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

   simple   =  V"repeated"
            +  V"named"
            +  V"prefixed"
            +  V"suffixed"
            +  V"atom"
            +  V"number"

   enclosed =  V"literal"
            +  V"hidden_literal"
            +  V"set"
            +  V"range"

   prefixed =  V"not_predicate"
            +  V"and_predicate"

   suffixed =  V"zero_or_more"
            +  V"one_or_more"
            +  V"optional"

   allowed_prefixed =  V"suffixed" + V"compound" +  V"atom" + V"number"
   allowed_suffixed =  V"prefixed" + V"compound" +  V"atom" + V"number"

   allowed_repeated =  V"prefixed"
                    +  V"suffixed"
                    +  V"compound"
                    +  V"atom"
                    +  V"number"

   -- /SUPPRESSED

   not_predicate = P"!" * V"WS" * V"allowed_prefixed"
   and_predicate = P"&" * V"WS" * V"allowed_prefixed"

   literal =  d_string
           +  s_string

   hidden_literal =  h_string

           set =  P"{" * set_c^1 * P"}"

       range   =  P"[" * V"range_start" * P"-" * V"range_end" * P"]"
   range_start = range_capture
   range_end   = range_capture

    zero_or_more =  V"allowed_suffixed" * V"WS" * P"*"
     one_or_more =  V"allowed_suffixed" * V"WS" * P"+"
        optional =  V"allowed_suffixed" * V"WS" * P"?"
        repeated =  V"allowed_repeated" * V"WS" * P"%" * V"number_repeat"
           named =  V"allowed_repeated" * V"WS" * V"named_suffix"

   named_suffix  =  P"@" * ( V"named_match"
                           + V"back_referred"
                           + V"equal_referred"
                           + V"greater_equal_referred"
                           + V"greater_referred"
                           + V"lesser_equal_referred"
                           + V"lesser_referred" )

   back_referred   =  P"(" * V"back_reference" * P")"
   equal_referred  =  P"(#" * V"equal_reference" * P")"
   greater_equal_referred = P"(>=" * V"gte_reference" * P")"
   greater_referred = P"(>" * V"gt_reference" * P")"
   lesser_equal_referred = P"(<=" * V"lte_reference" * P")"
   lesser_referred = P"(<" * V"lt_reference" * P")"

   named_match     = symbol
   back_reference  = symbol
   equal_reference = symbol
   gte_reference   = symbol
   gt_reference    = symbol
   lte_reference   = symbol
   lt_reference    = symbol

   number_repeat =  some_num_c

   comment  =  P";" * comment_c

   atom =  V"ws" + symbol

   number = P"-"^-1 * digit^1

   WS = (V"comment" + V"dent" + P' ' + P'\t' + P'\r')^0

   dent = P"\n" * (P"\n" + P" ")^0

   ws = P"_"
end
```

```lua
local PegGrammar = Grammar(pegylator, pegMetas)
```

```lua
local function new(peg_str, metas, pre, post)
   local peg_node = PegGrammar(peg_str)
   if not peg_node then return nil end
   local ok;
   ok, peg_node.parse, peg_node.grammar = pcall(Grammar,peg_node:toLpeg(),
                                              metas, pre, post)
   if not ok then
      peg_node.parse, peg_node.grammar = nil, nil
   end
   peg_node.metas = metas
   return peg_node
end
```

```lua
return new
```
