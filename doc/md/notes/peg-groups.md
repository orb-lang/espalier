# PEG groups\(??\)


I don't actually care, at all, if this is a group or not\. It, might be\. anyway


Point being we just got some rule extractions working such that you get a
complete subparser in the bargain and I'm entirely rethinking how I assemble
complex grammars, Orb in particular, from components\.

I've been doing this with strings, which kinda only works because if a rule
is double\-defined the Grammar module does not care\.


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
