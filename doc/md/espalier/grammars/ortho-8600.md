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
```

Then we translate this into Lua:

```lua
--local Node    =  require "espalier/node"
--local Grammar =  require "espalier/grammar"
local require = assert(require)
local L       =  require "espalier/elpatt"
local Node    =  require "espalier/node"
local Grammar =  require "espalier/grammar"

local P, R, E, V, S, D   =  L.P, L.R, L.E, L.V, L.S, L.D
```
### metatables

```lua
local Day = Node : inherit ()
Day.id = "day"
local Month = Node : inherit ()
Month.id = "month"
local Year = Node : inherit ()
Year.id =  "year"

local date_metas = { oneThru30 = Day,
                     oneThru29 = Day,
                     m31       = Month,
                     m30       = Month,
                     mFeb      = Month,
                     year      = Year }
```
### date grammar

```lua
local function _date_fn(_ENV)

   START "date"

   SUPPRESS ("positiveYear", "negativeYear"
            , "yearMonth", "yearMonthDay", "monthDay"
             -- , "oneThru12", "oneThru29",
             -- , "oneThru30", "oneThru31"
             )

   date         = V"yearMonthDay"
                + V"yearMonth"
                + V"year"

   year         = V"positiveYear" + V"negativeYear" + P"0000"

   positiveYear = R"19"  * R"09" * R"09" * R"09"
                + P"0"   * R"19" * R"09" * R"09"
                + P"00"  * R"19" * R"09"
                + P"000" * R"19"

   negativeYear =  P"-" * V"positiveYear"

   monthDay     = V"m31"  * P"-" * V"day"
                + V"m30"  * P"-" * (-V"longMonth" * V"day")
                + V"mFeb" * P"-" * (-V"threeDecan" * V"day")

   m31          = (P"01" + P"03" + P"05" + P"07" + "08" + "10" + "12")

   m30          = (P"04" + P"06" + P"09" + P"11")

   mFeb         = P"02"

   yearMonth    = V"year" * P"-" * V"month"

   yearMonthDay = V"year" * P"-" *  V"monthDay"

   month        = V"m31" + V"m30" + V"mFeb"

   day          = (P"0" * R"19")
                + (P"1" + P"2") * R"09"
                + P"30"
                + P"31"

   oneThru12    = (P"0" *  R"19") + P"10" + P"11" + P"12"

   oneThru29    = (P"0" * R"19")
                + (P"1" + P"2") * R"09"

   oneThru30    = P"30" + V"oneThru29"

   oneThru31    = V"longMonth" + V"oneThru30"

   longMonth    = P"31"

   threeDecan   = V"longMonth" + P"30"
```
#### (* 4. Date and Time Extensions *)

```ebnf
(* 4.1.1 Levels *)

(* For the extension features, two levels are defined: level 1 *)
(* and level 2. Each major subsection of section 4 covers a *)
(* general feature; some functions covered by that feature are *)
(* level 1 and some are level 2. These levels are defined for *)
(* the purpose of profiles, which may refer to the levels when *)
(* specifying conformance to the profile. *)

(* 4.2.1 Level 1 - Uncertain and/or Approximate Date *)

uaDate = yearMonthDay, uaSymbol ;

uaSymbol = "?" | "~" | "%" ;

(* Reduced accuracy *)

reducedDate = (year | yearMonth), uaSymbol ;

(* 4.2.2 Level 2 - Uncertain and/or Approximate Date *)

qualifiedDate = [uaSymbol], year, [uaSymbol], "-",
                [uaSymbol], month, [uaSymbol], "-",
                [uaSymbol], day, [uaSymbol] ;

(* 4.3.1 Level 1 - Unspecified Date *)

unspecifiedDate = (yearMonth, "-XX") | (year, "-XX-XX") | "XXXX-XX-XX" ;
```
```lua
   uaDate        = V"yearMonthDay" * V"uaSymbol"

   uaSymbol      = P"?" + P"~" + P"%"

   reducedDate   = (V"year" + V"yearMonth") * V"uaSymbol"

   qualifiedDate = V"uaSymbol"^0 * V"year" * V"uaSymbol"^0 * P"-"
                 * V"uaSymbol"^0 * V"month" * V"uaSymbol"^0 * P"-"
                 * V"uaSymbol"^0 * V"day" * V"uaSymbol"^0

   unspecifiedDate    = (V"yearMonth" * P"-XX")
                      + (V"year" * P"-XX-XX")
                      * P "XXXX-XX-XX"
```
```ebnf
(* Reduced accuracy *)

reduceAccuracyDate = (2 * digit, "XX")
                   | (3 * digit, "X")
                   | ("XXXX", ["-XX"])
                   | (year, "-XX") ;

(* 4.3.2 Level 2 - Unspecified Date *)

replacementDate = 4 * (digit | "X"),
                  ["-", 2 * (digit | "X"),
                  ["-", 2 * (digit | "X")]] ;

(* 4.4.1 Level 1 - Before or After *)

(* This feature is not used in level 1. *)

(* 4.4.2 Level 2 - Before or After *)

beforeAfterDate = ("..", year, ["-", month, ["-", day]])
                | (year, ["-", month, ["-", day]], "..") ;

(* 4.5.1 Level 1 - Enhanced Interval *)

startEndOpenOrUnknown = [yearMonthDay],["*"],"/",["*"],[yearMonthDay] ;

L1Interval = [year | yearMonth | yearMonthDay], [uaSymbol | "*"],
             "/", ["*"], [year | yearMonth | yearMonthDay], [uaSymbol] ;

(* 4.5.2 Level 2 - Enhanced Interval *)

L2Interval = [".."], (qualifiedDate | unspecifiedDate | replacementDate),
             "/", (qualifiedDate | unspecifiedDate | replacementDate ), [..] ;

(* 4.6.1 Level 1 - Year Exceeding Four Digits *)

longYear = "Y", ["-"], positiveDigit 4 * digit, {digit} ;

(* 4.6.2 Level 2 - Year Exceeding Four Digits *)

longYearScientific = "y", ["-"], positiveDigit, digit, "e" {digit}- ;

(* 4.7.1 Level 1 - Significant Digits *)
```

At this point I'm just going to fold some of the EBNF out because this is a
hyperspecified piece of crap designed to please everyone and I am **not**
implementing significant digits **and** approximate dates make up your mind ISO.

```ebnf
(* 5. Repeat Rules for Recurring Time Intervals *)

(* All features in this section are defined at level 1 for the *)
(* purpose of profiles, which may refer to the levels when *)
(* specifying conformance to the profile. *)

recurringIntervalWithRules = recurringInterval, "/", recurringRule ;

recurringInterval = 'R', {integer}, '/', interval ;

interval = intervalExplicit | intervalStart | intervalEnd | duration ;

intervalExplicit = dateAndTime, '/', dateAndTime ;

intervalStart = dateAndTime, '/', duration ;

intervalEnd = duration, '/', dateAndTime ;

duration = 'P', (durationTime | durationDate | durationWeek) ;

durationDate = durationDay, [durationTime] ;

durationTime = 'T', (durationHour | durationMinute | durationSecond) ;

durationHour = hour, 'H', [durationMinute] ;

durationMinute = minute, 'M', [durationSecond] ;

durationSecond = second, 'S' ;

durationDay = day, 'D' ;

durationWeek = week, 'W' ;
```
```lua
end
```
```lua
return Grammar(_date_fn, date_metas, nil, nil)
```
