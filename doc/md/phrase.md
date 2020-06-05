# Phrase


This is a string builder class\.

It is [heritable](httk://), may be concatenated with either a string or itself,
and will eventually implement the full string library as method calls\.

I use a definite string building paradigm for which the Phrase class is a drop\-in
replacement\.

The base Phrase class is mutable\.  Concatenating strings will add to the array
portion of the Phrase, while catting another Phrase will combine the two
into a new Phrase\.  This means in normal use, once a Phrase is added to another
Phrase, it will stay put\.

Specifically, Phrases are mutable until they are concatenated to another Phrase\.
At that point they are interned, any attempt to concatenate will spill the
contents into a new Phrase\.

I thought, let's call it 'spill', rather than abbreviate Copy on Concat\.


### Phrase is string\-like

It may be concatenated with strings at any point, and the result will be a Phrase\.

It will render the same string you would expect any time `tostring` is triggered\.


### Phrase is not entirely string\-like

We have a field `phrase.len` that tells you what `#tostring(phrase)` would be\.
`#phrase` is the number of fragments in the array portion of the phrase\.

We use `#Phrase` all the time for iteration, so we don't want to block it\.


## Phrase is contagious

Phrases, by design, subsume strings any time they are concatenated\. This
will tend to cause failure when handed to things like the string library\.

Better to write a Phrase\-native substitute unless it's an endpoint like
`write`\.  The combination of interned immutable strings and pervasing tabling
over concatenation is powerful and fast in Lua\.

It's ok to just call `tostring` and be done\.


## Phrase is \(relatively\) primitive

It provides concatenation, `tostring`, and a length field `len` separate
from `#`\.  It has `it` and `idEst`, the latter particularly useful to
avoid repetitive importing of the class\.

In particular, and on purpose, Phrase makes no effort to balance its binary
structure\.  This way, sensible, ordinary use of Phrase will preserve the
tree structure of the DAG being transduced\.

The typical grammar is of the form ` a : b* EOF / Err, b: c c*`, which will
naturally take a head\-weighted form\.

It is a trivial log\-log operation to bring a Phrase into balance if that
is desireable\.


### Roadmap

I would like to add `Phrase:ffind(str)`, for fast find\.  This only works if
the `str` is a literal fragment somewhere in the phrase\.

More enhancements of that nature should be in an extended class\. Think gsub
with the full power of lpeg instead of the quirky pattern syntax I can never
remember\.

Also, one premise of Phrase is that it's encoding\-unaware\. I'd like to add
to it by calculating the codepoints and adding a "ulen" field, but don't
want to pay the cost for the base class, since Node in particular counts on
grammars to be correct about the bytes they want to consume\.

The language interface of lpeg emphasises text, as it should, but Lua strings
are eight\-bit clean and commonly enough used to intern userdata and query it\.

Phrase can actually be used as\-is to build up rope\-like binary data, if that
ever comes in handy\.  I'd want a different `idEst` to not puke all over
my terminal by accident\.

Speaking of rope\-like, Phrase will have better performance in environments
where it is more 'bushy'\.

```lua
local init, new
local s = require "core/status" ()
s.angry = false
local Phrase = {}
Phrase.it = require "core/check"
```


## \_\_concat

  Concatenation is the frequent operation in working with Nodes\.  By default,
all a Node is in a position to do is yield a string\.  Phrase allows us to
enhance that with various table\-assisted superpowers\.

Also, Lua strings are very cheap once created\. Concatenating them together in
a recursively larger pattern is really expensive by comparison, and that's
the entire paradigm of all these tools right now\.

This and retaining the Docs in\-memory will get the spring back in our step\.

\- parameters
  \-  head\_phrase:  This may be either a primitive string or a Phrase\.
  \-  tail\_phrase:  This may be either primitive or a Phrase\.  If head\_phrase
                   is a string, tail\_phrase is not, or we'd be in the VM\.

```lua
local function spill(phrase)
   local new_phrase = init()
   for k, v in pairs(phrase) do
      new_phrase[k] = v
   end
   new_phrase.intern = nil

   return new_phrase
end


local function __concat(head_phrase, tail_phrase)
   if type(head_phrase) == 'string' then
      -- bump the tail phrase accordingly
      if tail_phrase.intern then
         tail_phrase = spill(tail_phrase)
      end

      table.insert(tail_phrase, 1, head_phrase)
      tail_phrase.len = tail_phrase.len + #head_phrase
      return tail_phrase
   end
   local typica = type(tail_phrase)
   if typica == "string" then
      if head_phrase.intern then
         head_phrase = spill(head_phrase)
      end
      head_phrase[#head_phrase + 1] = tail_phrase
      head_phrase.len = head_phrase.len + #tail_phrase
      return head_phrase
      elseif typica == "table" and tail_phrase.idEst == new then
      local new_phrase = init()
      head_phrase.intern = true -- head_phrase is now in the middle of a string
      tail_phrase.intern = true -- tail_phrase shouldn't be bump-catted
      new_phrase[1] = head_phrase
      new_phrase[2] = tail_phrase
      new_phrase.len = head_phrase.len + tail_phrase.len
      return new_phrase
   end

   return nil, "tail phrase was unsuitable for concatenation"
end
```


## \_\_tostring

Treating Phrase as a string at any point should render it into one\.

```lua
local function __tostring(phrase)
   local str = ""
   for i,v in ipairs(phrase) do
      str = str .. tostring(v)
   end

   return str
end
```

```lua
local PhraseMeta = {__index = Phrase,
                  __concat = __concat,
                  __tostring = __tostring}
```

```lua

init = function()
   return setmetatable ({}, PhraseMeta)
end

new = function(phrase_seed)
   phrase_seed = phrase_seed or ""
   local phrase = init()
   local typica = type(phrase_seed)
   if typica == "string" then
      phrase[1] = phrase_seed
      phrase.len = #phrase_seed
   else
      s:complain("Error in Phrase", "cannot accept phrase seed of type" .. typica,
                 phrase_seed)
   end
   return phrase
end

Phrase.idEst = new
```


### spec

Stick this somewhere better

```lua
local function spec()
   local a = new "Sphinx of " .. "black quartz "
   a: it "phrase-a"
      : passedTo(tostring)
      : gives "Sphinx of black quartz "
      : fin()

   local b = a .. "judge my " .. "vow."
   b: it "phrase-b"
      : passedTo(tostring)
      : gives "Sphinx of black quartz judge my vow."
      : fin()

end

spec()
```


```lua
return new
```





















