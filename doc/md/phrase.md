# Phrase


This is a string builder class.


It is [heritable](httk://), may be concatenated with either a string or itself,
and will eventually implement the full string library as method calls.


I use a definite string building paradigm for which the Phrase class is a drop-in
replacement.


The base Phrase class is mutable.  Concatenating will add to the array portion of
the Phrase.  This means in normal use, once a Phrase is added to another Phrase,
it will stay put.


The right _sort_ of mutability is copy-on-write.  We're not providing a mutation
interface yet, all we need is for it to behave like a string under ``__tostring``
and ``__concat``.



I intend to extend the class once we get to an editing environment, by making it
persistent rather than immutable.  A distinction I will elucidate when I reach it.


```lua
local init
local s = require "core/status" ()
s.angry = false
local Phrase = setmetatable({}, {__index = Phrase})
Phrase.it = require "core/check"
```
## __concat

  Concatenation is the frequent operation in working with Nodes.  By default,
all a Node is in a position to do is yield a string.  Phrase allows us to
enhance that with various table-assisted superpowers.


Also, Lua strings are very cheap once created. Concatenating them together in
a recursively larger pattern is really expensive by comparison, and that's
the entire paradigm of all these tools right now.


This and retaining the Docs in-memory will get the spring back in our step.


- parameters
  -  head_phrase:  This may be either a primitive string or a Phrase.
  -  tail_phrase:  This may be either primitive or a Phrase.  If head_phrase
                   is a string, tail_phrase is not, or we'd be in the VM.

```lua
local function __concat(head_phrase, tail_phrase)

      if type(head_phrase) == 'string' then
         -- bump the tail phrase accordingly
         local cursor = tail_phrase[1]
         tail_phrase[1] = head_phrase
         for i = 2, #tail_phrase + 1 do
            tail_phrase[i] = cursor
            cursor = tail_phrase[i + 1]
         end
         assert(cursor == nil)
         return tail_phrase
      end
      local typica = type(tail_phrase)
      if typica == "string" then
         head_phrase[#head_phrase + 1] = tail_phrase
      else
         -- check for phraseness here
         local new_phrase = init()
         new_phrase[1] = head_phrase
         new_phrase[2] = tail_phrase
         return new_phrase
      end

      return head_phrase
end
```
## __tostring

Treating Phrase as a string at any point should render it into one.

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
   else
      s:complain("NYI", "cannot accept phrase seed of type" .. typica)
   end
   return phrase
end
```
```lua
Phrase.idEst = new
return new
```
