





local pegpeg = [[
rules  <-  _ rule+ (-1 / Error)

rule  <-  lhs rhs

lhs  <-  (suppressed / rule-name) _ into _
rhs  <-  form _


suppressed  <-  "`" rule-name "`"
 rule-name  <-  symbol
    `into`  <-  ":=" / "<-" / "←" / "="

    `form`  <-  element _ elements*
 `element`  <-  !lhs (simple / compound)
`elements`  <-  (choice / cat) _

choice  <- "/" _ form
   cat  <- _ form

`compound` <- group / enclosed
`simple` <-  repeated
         /  matched
         /  prefixed
         /  suffixed
         /  name
         /  number

`group` <- "(" _ form _ ")"
`enclosed` <-  literal / set / range

`repeated`  <-  allow-repeat _ "%" slice
 `matched`  <-  allow-repeat _ match-suffix
`prefixed`  <-  not / and
`suffixed`  <-  zero-or-more / one-or-more / optional
      name  <-  symbol
    number  <-  EOS / integer

       literal  <-  single-string / double-string
           set  <-  "{" (!("}" / "\n") 1)* "}"
         range  <-  "[" range-start "-" range-end "]"

`single-string`  ←  "'" ("\\" "'" / "\\" 1 / (!"'" !"\n" 1))* "'"
`double-string`  ←  '"' ('\\' '"' / "\\" 1 / (!'"' !"\n" 1))* '"'

range-start  <-  codepoint
  range-end  <-  codepoint
  codepoint  ←  [\x00-\x7f]
             /  [\xc2-\xdf] [\x80-\xbf]
             /  [\xe0-\xef] [\x80-\xbf] [\x80-\xbf]
             /  [\xf0-\xf4] [\x80-\xbf] [\x80-\xbf] [\x80-\xbf]


       slice  <-  integer-range / integer
match-suffix  <-  "@" ; whitespace is not allowed. should it be?
                  ( reference
                  / back-refer
                  / eq-refer
                  / gte-refer
                  / gt-refer
                  / lte-refer
                  / lt-refer )

         not  <-  "!" _ allow-prefix
         and  <-  "&" _ allow-prefix
zero-or-more  <-  allow-suffix _ "*"
 one-or-more  <-  allow-suffix _ "+"
    optional  <-  allow-suffix _ "?"

`allow-repeat`  <-  prefixed / suffixed / jawn
`allow-prefix`  <-  suffixed / jawn
`allow-suffix`  <-  prefixed / jawn
        `jawn`  <-  compound / name / number

`symbol`  <-  (([A-Z] / [a-z]) ([A-Z]/[a-z] / {-_})+) / "_"

          EOS  <-  "-1"
integer-range  <-  integer ".." integer
      integer  <-  [0-9]+

back-refer  <-  "(" reference ")"
eq-refer  <-  "(#" reference ")"
gte-refer  <-  "(>=" reference ")"
gt-refer  <-  "(>" reference ")"
lte-refer  <-  "(<=" reference ")"
lt-refer  <-  "(<" reference ")"
reference  <-  symbol


      `_`  <-  (comment / dent / { \t\r})*
`comment`  <-  ";" (!"\n" 1)
   `dent`  <-  "\n" { \t}*


Error  <-  1+
]]


return pegpeg

