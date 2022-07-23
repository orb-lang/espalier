# JSON In Small Pieces


  A test platform for the [Vav Combinator](https://gitlab.com/special-circumstance/espalier/-/blob/trunk/doc/md/./espalier/vav.md)\.

This will, among other things, parse JSON\.


## Object

  An Object is not the top form in JSON, but it's the most general, the usual
container, so it may as well be\.

The whole 'deal' here is that you have to pick a start rule for a recursive
descent parser, and we're designing a system which lets us delay and compose
that decision\.

So what do we know for sure about an object? This:

```peg
   object <- "{" _ pair _ "}"
```


### Now What

What happens if we feed this to an ordinary PEG engine?

Easy, it chokes as soon as it sees `_`, a rule it doesn't recognize\.

This is, naturally


## Whitespace

Which we define thus:

```peg
  `_` <- { \t\n\r}*
```

Now, that isn't spec compliant, because `\r\r\r\n` is \(I think\!\) not valid
JSON whitespace\. But it's easy to write and easy to read, and we don't
actually care about `\r` because we aren't stuck with that convention\.

This is also a complete grammar: we can compile it and test it against
whitespace, as is\.

If we want to get anywhere with Object, we will need something for


## Pair

So what's the minimum viable pair?

We're taking the shortest path which gets us parsing valid JSON, starting with
an Object\.

So we require strings, for keys, and something for values: we make that
strings as well\.

Something like this:

```peg
pair <- key _ ":" _ value _ ","
key <- string
value <- string
string <- '"' (!'"' 1) '"'
```

Clearly this is not the final form of our parser, in fact, it's probably not
the final form of the code in this Orb file either\.  That trailing comma is,
er, problematic\.

We can in fact define a `pair` which handles commas correctly with lookahead\.

The most natural way to write JSON parser with PEGs doesn't need lookahead at
all, but I expect to find it useful in building out grammar analysis, so we'll
probably just roll with that\.
