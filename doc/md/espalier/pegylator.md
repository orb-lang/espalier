# Pegylator


This module takes a declarative grammar specification, and optional affiliated
Orb code, and emits a working Grammar for that specification and code\.

I've written large parts of it\.  There may be bugs\.

Let's dive in and start patching this together\.


## peg\.peg

This is `peg`, a grammar language defined in its own syntax\.

```peg
               rules :  comment* rule+
                rule :  lhs rhs
                 lhs :  _pattern_ (":" / "=" / ":=")
                 rhs :  element elements*
           `pattern` :  symbol / hidden-pattern
      hidden-pattern :  "`" symbol "`"
           `element` :  !lhs _( compound
                              / simple
                              / comment ) ; with a comment
          `elements` :  choice / cat
          `compound` :  group
                      / enclosed
                      / hidden-match
            `simple` :  prefixed
                      / suffixed
                      / atom
              choice :  _"/" element elements *
                 cat :  _ element elements *
               group :  _"("_ rhs_ ")"
          `enclosed` :  literal
                      / set
                      / range
        hidden-match :  _"``"_ rhs_ "``"
             comment : `;` comment-c ; make real
            prefixed :  if-not-this / if-and-this
         if-not-this :  `!` _allowed-prefixed
         if-and-this :  `&` _allowed-prefixed
            suffixed :  optional
                      / more-than-one
                      / maybe
                      / with-suffix
                      / some-number
            optional :  allowed-suffixed_ `*`
       more-than-one :  allowed-suffixed_ `+`
               maybe :  allowed-suffixed_ `?`
         some-number :  allowed-suffixed_ "$" some-num-c
         with-suffix :  some-number (`*`/`+`/`?`)
    allowed-prefixed :  compound
                      / suffixed
                      / atom
    allowed-suffixed :  compound
                      / prefixed
                      / atom
                atom :  symbol / ws
                  ws : "_"
    literal :  `"` ~(string*) `"`
    set     :  `{` set-c+ `}`
    range   :  `[` range-c `]`
    comment-m : -"\n" ANY
    comment-c : `;` ~(comment-m*) `\n`
    `string` : (string-match / '\\"' / "\\")+
    `string-match` : !`"` !`\\` ANY
    letter : [A-Z] / [a-z]
    valid-sym = letter + "-"
    digit = [0-9]
```


Next up:


## Implementation

How far have we gotten?

Pretty far\!