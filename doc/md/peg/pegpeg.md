# Parsing Expression Grammar for Parsing Parsing Expression Grammar Grammars


  Yo dawg\.

I heard you like parsing\.

So I wrote a Parsing Expression Grammar in Parsing Expression Grammar, for
parsing Parsing Expression Grammmars into expressive grammars, so I can parse
a grammar into a grammar parser, so you can use the parser parser from the
grammar grammar to parse your parser while you express your grammar\.


### PEGPEG

  This is a straightforward representation of Brian Ford's PEG syntax with a
few quirks and extensions:

  -  The end of input is presented as `-1`\.

      This pattern is used frequently in the existing codebase, but it's too
      Lua/Wirth for my taste, since it implies \(and this is why I excluded
      such rules\) that `-2` means *one byte* left, which is distasteful\.

      This convention is as tolerable as any other string manipulation in Lua,
      that is to say, the lack of ordination unified with measure is at least
      pervasive\.  Here it is the only place where the worse convention leaks
      into the specification, and I'd rather it didn't\.

      The semantic should be that `0` is End of String, with `-1` meaning one
      character remaining, and so on\. It's worth making this change while I
      still can\.

  -  Neither `true`, nor `false`, nor any variation, are reserved rule names\.
      The rule which always succeds is the empty literal `""`, which may be
      negated with `!""` to get the rule which always fails\.

  -  Supports a limited form of reference capture and back\-reference
      comparison, enough to support a number of common language patterns such
      as long strings in Lua\.

      The major limitation is that the references do not survive rule capture\.
      This makes them an efficient mechanism with negligible effect on
      performance, but require the paired references to either be a part of the
      same rule, or part of a subrule with is suppressed ```thus``` in its
      definition; these rules perform no captures of their own, returning all
      captures

      This will pose some difficulty in parsing languages, Python in
      particular, which rely heavily on semantic indentation\.  PEGPEG is
      capable of recognizing these rules, but may need some combination of
      post\-parse tree reconciliation, and/or the use of subgrammars, to resolve
      the details into the correct parse tree\.

```peg
           `peg`  ←   grammar / pattern

           grammar  ←  (rule_sep rule)+ (_ -1 / Error)

         pattern  ←  _ rhs (-1 / Error)

            rule  ←  lhs rhs

       rule-sep   ←   _ ; pragma lines go here

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
