# Algebra of Parsing Expression Grammars


Or rather, "some mathematical abstraction over parsing expression grammars"\.


## Principles

Any operation may take \(one, obviously\) string form, which is parsed into Peh
on the spot\.

I will do my level best to make these, if not Abelian, then at least balanced
where possible\.


## Operations


### Rule Concatenation: grammar \.\. grammar | grammar \.\. rule | rule \.\. grammar

Is the same as concatenating the underlying strings together\.

A rule will carry all of its references unless otherwise operated upon, any
naming conflicts will show up as anomalies\.  We'll preserve enough context to
let this be automatically fixed with a `'theirs'|'ours'|'both'` strategy,


### PEG Concatenation: cat\-able \* cat\-able

Cats the left to the right\.

Which tree does it end up on? If one is a rule and the other is not, or one
is literally `cat` and the other isn't, the rule/cat Node is the parent\.

If one is a string, the other is, obviously, the parent\.

Otherwise, one of them must be a root, or this will throw an error\.

A note: these operations have their own PEG precedence, such that e\.g\.
a rule `B` of form `b / c / d` with `a * B` might be expected to yield
` a b / c / d`\.

It doesn't: `a * B` gives `a (b / c / d)`, with automatic grouping\.  We can
of course *select* `b` for concatenation, but that's not the illustrated
operation\.

This is the natural approach from the inside perspective on Nodes, as well as
being the useful semantics of the operator, but might be surprising from the
outer PEG syntax perspective\.


### Choice: chooseable \+ chooseable

Same deal as `*`\.


### rule \- "name", grammar \- \(rule | "name"\)

Removes the pattern from the rule or grammar\.

This must be done in a structure\-preserving way: if the `name` referenced is
in an element, we remove the whole element, if it's part of a compound,
removing it won't change precedence\.

Note that this does not, itself, perform any garbage collection, stranded
rules may end up back in the final structure with subsequent operations\.


### grammar / \(rule\-name | rule\)

Extracts the sub grammar given by the rule name, so carrying off all other
rules needed to match it\.


### grammar % rule

This **replaces** a rule of the same name with the given rule\.

As always, no derived conflicts are solved, they go in the anomalies bin to
be sorted out\.

Note that we can merge *structurally* identical subrules, while ignoring
whitespace, and in the case of `set` we can even merge them if the order of
the set elements is different\.



## Support operations


### patt:group\(first, last\)

We end up with a lot of these I think, but it illustrates the idea of having
detailed control over changing precedence, adding modifiers, and so on\.
