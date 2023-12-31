# Date


A useful subset, eventually all, of ISO 8601, is an interesting candidtate for
a declarative PEG specification\.

Let's give it a trial run\.

```lua
local Peg = require "espalier/peg"
```

```lua
local date_peg = [[
   date  =  yearMonthDayTime
         /  yearMonthDay
         /  yearMonth
         /  year

   `yearMonthDay` = year "-" monthDay
   `yearMonth` = year "-" month

   year = positiveYear / negativeYear / "0000"

   `positiveYear` =  [1-9] [0-9] [0-9] [0-9]
                  /  "0"   [1-9] [0-9] [0-9]
                  /  "00"        [1-9] [0-9]
                  /  "000"             [1-9]
   `negativeYear` = "-" positiveYear

   `monthDay` =  m31 "-" day
              /  m30 "-" (!longMonth day)
              /  mFeb "-" (!threeDecan day)
   m31      =  "01" / "03" / "05" / "07" / "08" / "10" / "12"
   m30      =  "06" / "04" / "09" / "11"
   mFeb     =  "02"

   ; only used in negative lookahead
   longMonth = "31"
   threeDecan = "31" / "30"

   month  =  m31 / m30 / mFeb

   day  =  "0" [1-9]
        /  ("1" / "2") [0-9]
        /  ("30" / "31")

   `yearMonthDayTime` = yearMonthDay separator time
   `separator` = "T" / " " / "::" ; opinionated!


   time = hourMinuteSecond
        / hourMinute
        / hour

   `hourMinuteSecond` = hour ":" minute ":" second fracSecond? timeZone?
   `hourMinute` = hour ":" minute
   hour = [0-1] [1-9] / "2" [0-3]
   minute = sexigesimal
   second = sexigesimal
   fracSecond = "." [0-9] [0-9]? [0-9]?

   timeZone = zulu /  offset
   `offset` = (positive / negative) (hour ":" minute / hour minute / hour)
   positive = "+"
   negative = "-"
   zulu = "Z"
   `sexigesimal` = [0-5] [0-9]
]]
```

```lua
return Peg(date_peg):toGrammar()
```