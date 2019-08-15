# ortho 8600: date format


Let's start with the EBNF for a date, straight from
[[iso][]]:

```ebnf
(* Base definitions *)
year = positiveYear | negativeYear | "0000" ;

positiveYear = positiveDigit, digit, digit,
             | "0", positiveDigit, digit,
             | "00", positiveDigit, digit
             | "000", positiveDigit ;

negativeYear = "-", positiveYear ;

monthDay = ("01" | "03" | "05" |"07" |"08" |"10" |"12"),
            "-", OneThru31 | ("04" | "06" | "09" | "11"), "-", OneThru30
            | "02-", OneThru29 ;

yearMonth = year "-" month ;
month = oneThru12 ;
day = oneThru31 ;
date = year | yearMonth | yearMonthDay ;
oneThru12 = ("0", positiveDigit) | "10" | "11" | 12" ;
oneThru29 = ("0", positiveDigit) | (("1" | "2"), digit);
oneThru30 = OneThru29 | "30" ;
oneThru31 = OneThru30 | "31" ;
digit = positiveDigit | "0" ;
positiveDigit = "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;

(* 4. Date and Time Extensions *)
(* 4.1.1 Extended Format *) yearMonthDay = year, "-", monthDay ; (* 4.1.1 Levels *)
(* For the extension features, two levels are defined: level 1 *) (* and level 2. Each major subsection of section 4 covers a *) (* general feature; some functions covered by that feature are *) (* level 1 and some are level 2. These levels are defined for *) (* the purpose of profiles, which may refer to the levels when *) (* specifying conformance to the profile. *)
(* 4.2.1 Level 1 - Uncertain and/or Approximate Date *) uaDate = yearMonthDay, uaSymbol ;
uaSymbol = "?" | "~" | "%" ;
(* Reduced accuracy *)
reducedDate = (year | yearMonth), uaSymbol ;
(* 4.2.2 Level 2 - Uncertain and/or Approximate Date *) qualifiedDate = [uaSymbol], year, [uaSymbol], "-",
[uaSymbol], month, [uaSymbol], "-", [uaSymbol], day, [uaSymbol] ;
(* 4.3.1 Level 1 - Unspecified Date *)
unspecifiedDate = (yearMonth, "-XX") | (year, "-XX-XX") | "XXXX-XX-XX" ; (* Reduced accuracy *)
reduceAccuracyDate = (2 * digit, "XX") | (3 * digit, "X")
| ("XXXX", ["-XX"]) | (year, "-XX") ;
(* 4.3.2 Level 2 - Unspecified Date *)
replacementDate = 4 * (digit | "X"),
["-", 2 * (digit | "X"),
["-", 2 * (digit | "X")]] ; (* 4.4.1 Level 1 - Before or After *)
(* This feature is not used in level 1. *)
(* 4.4.2 Level 2 - Before or After *)
beforeAfterDate = ("..", year, ["-", month, ["-", day]])
| (year, ["-", month, ["-", day]], "..") ; (* 4.5.1 Level 1 - Enhanced Interval *)
```

Then we translate this into Lua:

```lua
--local Node    =  require "espalier/node"
--local Grammar =  require "espalier/grammar"
local require = assert(require)
local L       =  require "espalier/elpatt"

local P, R, E, V, S    =  L.P, L.R, L.E, L.V, L.S
```
### date grammar

```lua
local function _date_fn(_ENV)

   START "date"

   SUPPRESS ( "positiveYear", "negativeYear",
              "oneThru12", "oneThru29",
              "oneThru30", "oneThru31",
              "posDigit", "digit" )

   date         = V"year"
                + V"yearMonth"
                * V"yearMonthDay"

   year         = V"positiveYear" + V"negativeYear" + P"0000"

   positiveYear = P"0" * V"posDigit" * V"digit" * V"digit"
                + P"00" * V"posDigit" * V"digit"
                + P"000" * V"posDigit"

   negativeYear =  P"-" * V"positiveYear"

   monthDay     = (P"01" + P"03" + P"05" + P"07" + "08" + "10" + "12")
                + P"-" * V"oneThru31"
                + (P"04" + P"06" + P"09" + P"11") *"P-" * V"oneThru30"
                + P"02" * P"-" * V"oneThru29"

   yearMonth    = V"year" * P"-" * V"month"

   yearMonthDay = V"year" * P"-" *  V"monthDay"

   month        = V"oneThru12"

   day          = V"oneThru31"

   oneThru12    = (P"0" *  V"posDigit") + P"10" + P"11" + P"12"

   oneThru29    = (P"0" * P"posDigit")
                + (P"1" + P"2") * V"digit";

   oneThru30    = V"oneThru29" + P"30"

   oneThru31    = V"oneThru30" + P"31"

   digit        = R"09"

   posDigit     = R"19"

   -- (* 4. Date and Time Extensions *)
end
```
```lua
   return _date_fn
```
