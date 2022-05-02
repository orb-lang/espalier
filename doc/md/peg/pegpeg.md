# Parsing Expression Grammar of Parsing Expression Grammar


  Rather than try to massage pegylator, we're going to translate the extant
PEG engine, which we will after all be using\.

```peg
rules  <-  _ rule+ (-1 / Error)

rule  <-  lhs rhs

lhs  <-  pattern _ into _
rhs  <-  form _

    `form`  <-  element _ elements*
 `element`  <-  !lhs (simple / compound)
`elements`  <-  (choice / cat) _

choice  <- "/" _ form
   cat  <- _ form

`compound` <- group / enclosed
`simple <-  repeated
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

       slice  <-  integer-range / integer
match-suffix  <-  "@" ; whitespace is not allowed. should it be?
                  ( named-match
                  / back-refer
                  / eq-refer
                  / gte-refer
                  / gt-refer
                  / lfe-refer
                  / lt-refer )

         not  <-  "!" _ allow-prefix
         and  <-  "&" _ allow-prefix
zero-or-more  <-  allow-sufix _ "*"
 one-or-more  <-  allow-suffix _ "+"
    optional  <-  allow-suffix _ "?"

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


      `_`  <-  (comment / dent / { \t\r})*
`comment`  <-  ";" (!"\n" 1)
   `dent`  <-  "\n" { \t}*


Error  <-  1+
```

```lua
return pegpeg
```
