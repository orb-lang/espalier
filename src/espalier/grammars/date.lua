








local date_peg = [[
   ;comment
   ;second comment
   date = yearMonthDay / yearMonth / year
   `yearMonthDay` = year "-" monthDay
   `yearMonth` = year "-" month

   year = positiveYear / negativeYear / "0000"

   `positiveYear` =  [1-9] [0-9] [0-9] [0-9]
                  /  "0"   [1-9] [0-9] [0-9]
                  /  "00"        [1-9] [0-9]
                  / "000"             [1-9]
   `negativeYear` = "-" positiveYear

   `monthDay` =  m31 "-" day
              /  m30 "-" (!longMonth day)
              /  mFeb "-" (!threeDecan day)
   m31      =  "01" / "03" / "05" / "07" / "08" / "10" / "12"
   m30      =  "06" / "04" / "09" / "11"
   mFeb     =  "02"

   longMonth = "31"
   threeDecan = "31" / "30"

   month  =  m31 / m30 / mFeb

   day  =  "0" [1-9]
        /  ("1" / "2") [0-9]
        /  ("30" / "31")


]]



return date_peg
