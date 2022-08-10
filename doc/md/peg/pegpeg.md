# Parsing Expression Grammar for Parsing Parsing Expression Grammar Grammars


  Yo dawg\.

I heard you like parsing\.

So I wrote a Parsing Expression Grammar in Parsing Expression Grammar, for
parsing Parsing Expression Grammmars into expressive grammars, so I can parse
a grammar into a grammar parser, so you can use the parser parser from the
grammar grammar to parse your parser while you express your grammar\.

```peg
           `peg`  ←  rules / anon

           rules  ←  _ rule+ (-1 / Error)
            anon  ←  _ rhs (-1 / Error)

                             ; this is the only trailing whitespace left
                             ; there are other things to do but this iteration
                             ; should support adding optional pragma lines
                             ; before rules.
            rule  ←  lhs rhs rule-sep

      `rule-sep`  ←   _

             lhs  ←  (suppressed / rule-name) _ into _
             rhs  ←  alt

      suppressed  ←  "`" rule-name "`"
       rule-name  ←  symbol
          `into`  ←  ":=" / "←" / "<-" / "="''
        `symbol`  ←  letter (letter / digit /  {-_})*
                  /  "_"

             alt  ←  cat (_ "/" _ cat)*
             cat  ←  element (_ element)*

         element  ←  prefix? part suffix? backref?

        `prefix`  ←  (and / not) _
        `suffix`  ←  zero-plus / one-plus / optional / repeat
        `part`    ←  name !(_ into)
                  /  literal
                  /  group
                  /  set-capture
                  /  range
                  /  number

             and  ←  "&"
             not  ←  "!"

       zero-plus  ←  _ "*"
        one-plus  ←  _ "+"
        optional  ←  _ "?"
          repeat  ←  _ "%" _ slice

         backref  ←  "@" _ ( reference
                           / back-refer
                           / eq-refer
                           / gte-refer
                           / gt-refer
                           / lte-refer
                           / lt-refer )

            name  ←  symbol
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
```

```lua
return pegpeg
```
