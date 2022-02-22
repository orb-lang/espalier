# PEG groups\(??\)


  I don't actually care, at all, if this is a group or not\.  Yet\.  It, might
be\.  anyway

Point being we just got some rule extractions working such that you get a
complete subparser in the bargain and I'm entirely rethinking how I assemble
complex grammars, Orb in particular, from components\.

I've been doing this with strings, which kinda only works because if a rule
is double\-defined the Grammar module does not care\.

What follows is a fairly raw brain dump\.  Caveat lector\.


## Subparser Extraction

This relies on a simple equivalence: a PEG must have a start rule, and that
rule must visit all subrules for those subrules to be counted as part of the
grammar\.

So if we take a single rule, and visit every rule mentioned by that rule's
construction, and so on, skipping cycles, then concatenate the rules, we have
a PEG which recognizes this rule\.


### Proof

That's where ACL2 comes in\!

I'm not sure what the strategy is, but it should involve proving that
walking a subtree created from a given rule tree visits identical nodes as
walking the original PEG tree starting from that rule\.

With a ParseIR reader, that's just list traversal and structural equivalence,
and without structural list equivalence no symbolic Lisp mathematical engine
can function\.


## Rule Equality

We want to be able to say that two rules are the same if they parse the same
inputs, but we can't, and it turns out that desire is harmful\.

What we *actually* want is to be able to say that two rules are the same if
they parse the same inputs into the same *structure*, and we almost can\.

We can definitely say that two rules are the same if they recognize the same
set of primitive rules in the same graph, and that is something we can
determine with static analysis, and while we're there, we'll get power level
analysis for free\.


### Partial Rule Equality

A rule is as a rule composed of some mix of primitive and named components\.

We do call the names atoms which is awkward, mildly, but\.

Point being a rule can be partially equal to another rule, pending evaluation
of the rules pointed to by the atoms\.

This sounds like a partial, right? so we can provide a partial with some
superstructure to identify the rule it needs to be applied against in
potentially two candidate grammars:

```lun
fn(rule_a)
   -> fn(rule_b)
         -> rule_a == rule b
      end,
      rule_b:name()
end

-- applied as
fn(rule_map[name]) -- returns predicate
```

The recursion is just dupe checking again, but we have to remember that hidden
patterns get expanded into their matches so they do *not* count towards rule
equality, which is same string same structure\.


## Equality, Inequality, Maybe<Eq, Neq>

So we're working on a pattern for incremental parser generation here, and part
of the game is to be able to pull out arbitrary subrules, along with the rules
necessary to turn them into a grammar, then graft them onto other rulesets and
have the rules and metatables land in the correct spot\.

It's also the case that I often say "blah blah placeholder" when it's time to
write some rules and I don't want to, say, add dates to TOML\.

lpeg won't let you write an incomplete grammar, but we don't have to, we can
just provide all missing rules as a generic pattern which generates useful
metadata and then returns `false`\.  This can even be decorated with passing
and/or failing inputs, but more importantly, the grammar compiles without
them, they note when they get tried, and if we're adding grammars together,
we replace dummy rules with real ones\.

There's an analogy here which might prove algorithmically useful between a
suspended decision about rule equality, and a suspended decision about
whether an absent rule can parse a string or not\.  To get back to TOML and
the date parser again, a date isn't an otherwise valid TOML enitiy, and we'd
see that the date category was tried and failed against it, but if \(for the
sake of argument\) we had a rule defining the `[` and `]` in arrays, but not
the interior, this would not be triggered by the presence of a date in the
TOML\.  So we could manually add that date as an example of something a `date`
rule should be expected to parse\.

This is something we can do on the way into the `:toLpeg` method, to generate
a postscript containing the missing rules\.


#### Coroutine\-suspended partials

  A Grammar generated with missing rules can be a wrapped coroutine, in which
the suspended rule is a match\-time capture yielding a closure\.  That closure,
provided with a pattern, Peg, Grammar, or other such contrivance, will
attempt to apply it against the part of the string which encountered that
rule, returning `nil` or the match, which will be appropriately shaped if it's
a Grammar and can be coerced into shape if it is instead a pattern of the
usual sort\.  Patterns are too general to make guarantees\.

In the usual course of events it would be an additional Grammar's worth of
rule which would be applied to the suspended parse, in the hope of continuing
it further\.


#### Application: parsing within Orb codeblocks

This one is almost on easy mode\.

I'll stick to Lua, but the same applies to many languages: the basic compiling
unit is a chunk, and most codeblocks will be a valid chunk\.

Some won't be, if, for my most common example, I cut up a long function and
intersperse commentary\.

So I can have a chunk\-first parsing strategy, which falls back on the full
Lua parser, but one which can suspend parsing on EOL: a stream parser\.

This will have the happy side effect of grouping the blocks composing a single
function \(perhaps with front and back matter\) logically, which will come in
handy when it's time to start hashing, parsing,transcluding, &c\.



### Power Level Analysis

This step is what lets us truly shine with automated error recovery\.

The error recovery algorithm I want to emulate comes from Terrence Parr, but
ANTLR uses a tokenizer, which is allowable as a preprocessing step to the PEG
algorithm but which isn't a native concept to this style of grammar\.

Fortunately, two\-step lexing and parsing is just equivalent to recognizing
a regular language followed by a context\-free one\.  We can do the same basic
sort of algorithm by identifying the conditions which apply to a given rule\.



### Alternate Lead Rule Exclusion

Rules which are of the form ` a <- b / c / d `, where `b`, `c`, and `d` all
have leading rules which terminate in either disjoint literals, or proveably
disjoint regulars, may be presumed to all fail, provided one of the rules
has been entered\.

Consequentially, if `a` itself must succeed for the parse to succeed, an entry
into e\.g\. `c` which fails to reach its terminal is itself a failure of the
parse, but one which we have detected while context is still preserved\.

Put plainly: if we're parsing Lua and encounter an `if` keyword, we know we
will find a `then` and an `end`, and if we don't, we have a failing `if`
statement, which means we have a failing parse\.

[relevant link](https://news.ycombinator.com/item?id=20503245)



### Equivalence Folding

There are a few cases where we can prove that a couple of rules are identical
even if they're expressed differently\. One of these is a set vs\. a series of
literal choices, the other is where two literals are adjacent \(which can
happen because of rule expansion\), and our analyser will already read through
situations where two intermediate rules resolve to the same base rule: a
practical example is my Lua parser, which has a function call statement which
is identical to a function call reached from an expression, except that other
expressions aren't allowed in statement position\.

