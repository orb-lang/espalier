# Phrase


This is a string builder class.


It is [heritable](httk://), may be concatenated with either a string or itself,
and will eventually implement the full string library as method calls. 


I use a definite string building paradigm for which the Phrase class is a drop-in
replacement. 

```lua
local Phrase = setmetatable({}, {__index = phrase})
Phrase.isPhrase = Phrase
```
## ..

  Concatenation is the frequent operation in working with Nodes.  By default,
all a Node is in a position to do is yield a string.  Phrase allows us to
enhance that with various table-assisted superpowers. 

```lua
local function cat(phrase, tail)
  if type(tail) == 'string' then
    return tail
  end
  phrase[#phrase + 1] = tail
  return phrase
end
Phrase.__concat = cat
```
## __tostring

We want to behave like a string whenever 

```lua
local function toString(phrase)
  local str = ""
  for i,v in ipairs(phrase) do
    str = str .. tostring(v)
  end

  return str
end
```
## Constructor

```lua
local function new(_, str)
  local phrase = setmetatable({}, Phrase)
  if str then
    phrase[1] = str
  end
  return phrase
end

Phrase.__call = new
```
## inherit

```lua
function Phrase.inherit(phrase)
  local Meta = setmetatable({}, phrase)
  Meta.__index = Meta
  Meta.__call  = getmetatable(phrase).__call
  Meta.__concat = getmetatable(phrase).__concat
  local meta = setmetatable({}, Meta)
  meta.__index = meta
  return Meta, meta
end
```
```lua
return setmetatable({}, {__call = new})
```
