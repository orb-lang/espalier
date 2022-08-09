












local pegpeg = [[
           `peg`  ←  rules / anon

           rules  ←  _ rule+ (-1 / Error)
            anon  ←  _ rhs (-1 / Error)

            rule  ←  lhs rhs

             lhs  ←  (suppressed / rule-name) _ into _
             rhs  ←  alt

      suppressed  ←  "`" rule-name "`"
       rule-name  ←  symbol
          `into`  ←  ":=" / "←" / "<-" / "="''
        `symbol`  ←  letter (letter / digit /  {-_})*
                  /  "_"

             alt  ←  cat ("/" _ cat)*
             cat  ←  element element*

         element  ←  prefix? part suffix? match-suffix?

        `prefix`  ←  and / not
        `suffix`  ←  zero-plus / one-plus / optional / repeat
        `part`    ←  name _ !into
                  /  literal _
                  /  group _
                  /  set _
                  /  range _
                  /  number _

             and  ←  "&" _
             not  ←  "!" _

       zero-plus  ←  "*" _
        one-plus  ←  "+" _
        optional  ←  "?" _
          repeat  ←  "%" _ slice

  `match-suffix`  ←  "@" _ ( reference
                           / back-refer
                           / eq-refer
                           / gte-refer
                           / gt-refer
                           / lte-refer
                           / lt-refer )

            name  ←  symbol
         literal  ←  single-string / double-string
         `group`  ←  "(" _ alt ")"
             set  ←  "{" (!("}" / "\n") codepoint)* "}"
           range  ←  "[" range-start "-" range-end "]"
          number  ←  EOS / integer

           slice  ←  integer-range / integer
         integer  ←  digit+
         `digit`  ←  [0-9]

      back-refer  ←  "("   reference  ")"
        eq-refer  ←  "(#"  reference  ")"
       gte-refer  ←  "(>=" reference  ")"
        gt-refer  ←  "(>"  reference  ")"
       lte-refer  ←  "(<=" reference  ")"
        lt-refer  ←  "(<"  reference  ")"
       reference  ←  symbol

 `single-string`  ←  "'" (escaped / !"'" utf8)* "'"
 `double-string`  ←  '"' (escaped / !'"' utf8)* '"'


       codepoint  ←   utf8
     range-start  ←  escaped / codepoint
       range-end  ←  escaped / codepoint
 `integer-range`  ←  integer ".." integer

        `letter`  ←  [A-Z] / [a-z]
      ; every Lua escape except \⏎
      `escaped`  ←  "\\" ( ( {abfnrtv}
                           / "'"
                           / '"'
                           / "\\" )
                         / digit digit? digit? ; digit%1..3
                         / "x" higit higit )

    `hex-escape`  ←  "\\" {Xx} higit higit
         `higit`  ←  digit / [A-F] / [a-f]

             EOS  ←  "-1"

             `_`  ←  (comment / dent / WS)*
       `comment`  ←  ";" (!"\n" utf8)*
          `dent`  ←  "\n" { \t}*
            `WS`  ←  { \t\r}

          `utf8`  ←  [\x00-\x7f]
                  /  [\xc2-\xdf] [\x80-\xbf]
                  /  [\xe0-\xef] [\x80-\xbf] [\x80-\xbf]
                  /  [\xf0-\xf4] [\x80-\xbf] [\x80-\xbf] [\x80-\xbf]

           Error  ←  1+
]]


return pegpeg

