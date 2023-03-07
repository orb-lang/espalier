















































































































local pegpeg = [[
           `peg`  ←   grammar / pattern

         grammar  ←  (rule-sep rule)+ (_ -1 / Error)

         pattern  ←  _ rhs (-1 / Error)

            rule  ←  lhs _ rhs

     `rule-sep`   ←   prag-line / _

     `prag-line`  ←  "\n#" pragma rule-sep
          pragma  ←  verb body?
            verb  ←  (!{\t\r\n } 1)+
            body  ←  (!"\n" 1)+

             lhs  ←  (suppressed / rule-name) _ into
             rhs  ←  alt

      suppressed  ←  "`" rule-name "`"
       rule-name  ←  symbol
          `into`  ←  ":=" / "←" / "<-" / "="
        `symbol`  ←  letter (letter / digit /  {-_})*
                  /   "_"

             alt  ←  cat (_ "/" _ cat)*
             cat  ←  element (_ element)*

         element  ←  prefix? part suffix? backref?

        `prefix`  ←  (and / not / to-match) _
        `suffix`  ←  zero-plus / one-plus / optional / repeated
        `part`    ←  name !(_ into)
                  /   literal
                  /   group
                  /   set-capture
                  /   range
                  /   number

             and  ←  "&"
             not  ←  "!"
        to-match  ←  ">>"

       zero-plus  ←  _ "*"
        one-plus  ←  _ "+"
        optional  ←  _ "?"
        repeated  ←  _ "%" _ slice

         backref  ←  "@" _ ( reference
                           / back-refer
                           / eq-refer
                           / gte-refer
                           / gt-refer
                           / lte-refer
                           / lt-refer )

            name  ←  name-space / symbol
      name-space  ←  symbol _ "." _ name

         literal  ←  single-string / double-string
           group  ←  "(" _ alt _ ")"
   `set-capture`  ←  "{" set "}"
             set  ←  (!("}" / "\n") codepoint)*
           range  ←  "[" range-start "-" range-end "]"
          number  ←  EOS / integer

           slice  ←  integer-range / integer
         integer  ←  digit+
         `digit`  ←  [0-9]

      back-refer  ←  "("   reference  ")"
        ; should probably refactor this to "(=" or "(=="
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
      ; every Lua escape except \⏎ and \z
      `escaped`  ←  "\\" ( ( {abfnrtv}
                           / "'"
                           / '"'
                           / "\\" )
                         / digit digit? digit? ; digit%1..3
                         / {Xx} higit higit )
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

