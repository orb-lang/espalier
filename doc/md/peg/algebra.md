# Algebra of Parsing Expression Grammars


Or rather, "some mathematical abstraction over parsing expression grammars"\.


##### concerning precedence

These symbols are being chosen for mnemonic clarity, not so much so that they
compose well given the baked\-in precedences\.


## Addition: grammar \+ grammar

Adds the rule iff it's referenced but not defined, if it's referenced, the
rule becomes an ordered choice after the existing rule, so `a <- b / c` is
turned into `a <- (b / c) / right-a`\.

We'll talk about the rule resolution algorithm later\.


## Subtraction grammar \- rule\-name

Removes the rule, and anything else which is only referred to by that rule\.


## Multiplication: grammar \* grammar

As with addition, but concatenation? hmm\.

### grammar / rule\-name

extracts the sub grammar given by the rule name\.