# Extended LPEG Patterns


  A module which extends `lpeg`, as a drop\-in replacement with a superset of
the existing semantics\.


#### imports

```lua
local lpeg = require "lpeg"
local C, Cmt, Ct = assert(lpeg.C),
                   assert(lpeg.Ct),
                   assert(lpeg.Ct)
local P, R, S, V = assert(lpeg.P),
                   assert(lpeg.R),
                   assert(lpeg.S),
                   assert(lpeg.V)
```

We start by copying over everything from lpeg\.

```lua
local elpatt = {}
for k, v in pairs(lpeg) do
   elpatt[k] = v
end
```


## Custom pattern constructions

  These are functions similar to the builtin `P`, `R`, `S` etc, and return
patterns that can be further composed\.

Some of these are also taken from the `lpeg` tutorial\.


#### anywhere\(patt\)

Converts a pattern so it will match anywhere in a string\.

Captures the matched portion and the position at which it starts and ends
in the subject string\.

Taken from the lpeg tutorial, adapted to capture the matched portion as well\.

```lua
local I = lpeg.Cp()

function elpatt.anywhere(p)
     return P{ I * C(p) * I + 1 * V(1) }
end
```


#### rep\(patt, n\[, m\]\) : Bounded repetition

Matches `patt` repeated between `n` and `m` times, inclusive\.

If `m` is omitted, matches exactly `n` repetitions \(This is more useful than`n`\-or\-more", since there is already the syntax `patt ^ n` for that\)\.

"
`n == 0` results in degenerate cases, which are equivalent to existing
`lpeg` constructs\. We support this anyway for completeness' sake when
constructing grammars dynamically\.


-  `m == nil` or `m == 0`\-> `-patt`


-  `m ~= nil` \-> `patt ^ -m`

```lua
local function rep(patt, n, m)
   patt = P(patt)
   assert(n, "missing argument #2 to 'rep' (n is required)")
   assert(n >= 0, "bad argument #2 to 'rep' (n cannot be negative)")
   assert(not m or m >= n, "bad argument #3 to 'rep' (m must be >= n)")
   -- m == n is equivalent to omitting m altogether, easiest to
   -- take care of this up front
   if m == n then
      m = nil
   end
   if n == 0 then
      if m then
         return patt ^ -m
      else
         return -patt
      end
   else
      local answer = patt
      for i = 1, n - 1 do
         answer = answer * patt
      end
      if m then
         answer = answer * patt^(n - m)
      end
      return answer
   end
end

elpatt.rep = rep
```


#### elpatt\.M\(tab\) : Capture map

  Creates a pattern matching any of the keys of a provided table, and
producing as a capture the corresponding value\.

The order in which the keys are matched is the enumeration order of the table,
i\.e\. undefined, so they should be mutually exclusive\.

The keys must be simple strings, and are matched exactly\.  We could allow them
to be arbitrary patterns, but it is unclear what the semantics of this should
be, so it seems better to keep this function simple\.

```lua
function elpatt.M(tab)
   local rule
   for k in pairs(tab) do
      assert(type(k) == 'string', "Keys passed to M() must be strings")
      rule = rule and rule + P(k) or P(k)
   end
   return rule / tab
end
```


#### elpatt\.Cnc\(name, value\) : Capture named constant

  Captures a constant value as a named group, adding `name = value` to an
enclosing table capture\. Always succeeds\. Useful in a structure like:

```lua
Ct(
  ... * (
    foo_patt * Cnc("type", "foo") +
    bar_pat * Cnc("type", "bar")
  )
)
```

```lua
local Cc, Cg = assert(lpeg.Cc), assert(lpeg.Cg)
function elpatt.Cnc(name, value)
  return Cg(Cc(value), name)
end
```


### Unicode\-aware components

  `lpeg`, like Lua, is by default is not Unicode\-aware\.  `R` and `S` in
particular have undesirable behavior if their arguments contain Unicode
characters, so we wrap them to check for Unicode and use a different
implementation in that case\.

In all cases, invalid UTF\-8 in the arguments is an immediate error\.  Invalid
UTF\-8 encountered in the subject string is simply not matched\.


#### Patterns for Unicode codepoints and strings

  We pre\-declare a pattern that matches a single UTF\-8 codepoint \(including an
ASCII character\), and one that matches an entire \(valid\) string\.

We also declare one that detects an ASCII\-only string, for determining when
to fall back to the original `lpeg` function below\. Note that we can't use
built\-in Lua patterns, as they seem to choke on NULs\.

```lua
local utf8_cont = R"\x80\xbf"
local utf8_char = R"\x00\x7f" +
                  R"\xc2\xdf" * utf8_cont +
                  R"\xe0\xef" * rep(utf8_cont, 2) +
                  R"\xf0\xf4" * rep(utf8_cont, 3)
local utf8_str  = Ct(C(utf8_char)^0) * -1
local ascii_str = R"\x00\x7f"^0 * -1
```


#### elpatt\.R\(ranges\.\.\.\)

UTF\-8 compatible version of the range pattern\.

```lua
local codepoint = assert(require "lua-utf8" . codepoint)
local inbounds = assert(require "core:math" . inbounds)
local insert = assert(table.insert)
local assertfmt = assert(require "core:fn" . assertfmt)

local function R_unicode(...)
   local args = pack(...)
   local ascii_ranges, utf_ranges = {}, {}
   for i, range in ipairs(args) do
      if ascii_str:match(range) then
         -- Throw this error here while we still know which argument this was
         assertfmt(#range == 2,
            "bad argument #%d to 'R' (range must have two characters)", i)
         insert(ascii_ranges, range)
      else
         range = utf8_str:match(range)
         assertfmt(range, "bad argument #%d to 'R' (invalid utf-8)", i)
         assertfmt(#range == 2,
            "bad argument #%d to 'R' (range must have two characters)", i)
         insert(utf_ranges, { codepoint(range[1]), codepoint(range[2]) })
      end
   end
   local answer;
   if #ascii_ranges > 0 then
      answer = R(unpack(ascii_ranges))
   end
   if #utf_ranges ~= 0 then
      local utf_answer =  P(function(subject, pos)
           local char = C(utf8_char):match(subject, pos)
           if not char then return false end
           local code = codepoint(char)
           for _, range in ipairs(utf_ranges) do
              if inbounds(code, range[1], range[2]) then
                 return pos + #char
              end
           end
           return false
        end)
      answer = answer and answer + utf_answer or utf_answer
   end
   return answer
end

elpatt.R = R_unicode
```


#### elpatt\.S\(chars\)

UTF\-8 compatible version of the set pattern\.

```lua
local concat, insert = assert(table.concat), assert(table.insert)

local function S_unicode(chars)
   -- We *could* skip this early-out and we'd still return an identical
   -- pattern, since we separate out the ASCII characters below,
   -- but let's keep the degenerate case clear and fast
   if ascii_str:match(chars) then
      return S(chars)
   end
   chars = utf8_str:match(chars)
   assert(chars, "bad argument #1 to 'S' (invalid utf-8)")
   local patt;
   local ascii_chars = {}
   for _, char in ipairs(chars) do
      if #char == 1 then
         insert(ascii_chars, char)
      else
         patt = patt and P(char) + patt or P(char)
      end
   end
   if #ascii_chars > 0 then
      patt = patt and S(concat(ascii_chars)) + patt or S(concat(ascii_chars))
   end
   return patt
end

elpatt.S = S_unicode
```


#### elpatt\.U\(\[n\[, m\]\]\)

Matches `n` to `m` valid Unicode codepoints \(`n` and `m` have the same meaning
as with `rep`, except that `n` defaults to 1\)\-\-effectively a Unicode\-aware
P\(n\), but kept separate since \(a\) we want to preserve the option to match
a particular number of bytes with `P(n)` and \(b\) `P` is used internally,
e\.g\. how `1 - patt` is equivalent to `P(1) - patt`, and since we
can't replace it we want to keep behavior consistent\.

```lua
function elpatt.U(n, m)
   n = n or 1
   return rep(utf8_char, n, m)
end
```


## Utility functions

Functions which operate on entire patterns and/or strings, similar to `match`\.


#### split\(str, sep\)

Splits a string on occurences of `sep`, discarding the separators
and returning an array table of the intervening elements\.

Taken from the lpeg tutorial\.

```lua
function elpatt.split(str, sep)
  sep = P(sep)
  local elem = C((1 - sep)^0)
  local patt = Ct(elem * (sep * elem)^0)   -- make a table capture
  return patt:match(str)
end
```


#### gsub\(str, patt, repl\)

Analogous to `string.gsub`, but using an Lpeg pattern for the search\.
If no replacement string is provided, it is assumed that the pattern
already contains the replacements \(by using `M`, =/\-, etc\. internally\)\.

Inspired by an example in the Lpeg tutorial, with the added flexibility
of making the replacement string optional\.

```lua
local Cs = assert(lpeg.Cs)
function elpatt.gsub(str, patt, repl)
   patt = P(patt)
   if repl then
      patt = patt / repl
   end
   patt = Cs((patt + 1)^0)
   return patt:match(str)
end
```


```lua
return elpatt
```
