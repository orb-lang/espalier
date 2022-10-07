# Maul


  Maul, as in the tool, is our ingester of Treesitter grammars\.

Because a Maul is a Tree\-splitter\.  Glad we got that straight\.


## Ok what

Treesitter is just a couple JSON files and their application\.

These specify a concrete syntax tree for a GLR parser\.  It's considered to be
in good taste for these grammars to be LR\(1\) whenever possible, and LR\(1\) has
been proven to inhabit PEG space\.  To my knowledge GLR has not, but that's
where I would place my bet\.

It may not be possible, and it isn't even necessarily useful, to generate a
valid PEG directly from the Treesitter spec\.  There are differences beyond the
idiomatic between a shift\-reduce and a recursive\-descent view of language
recognition, for that reason to make a **good** PEG, further work past the
translation will be wanted\.

Given that, there's limited advantage in the output being formally correct in
all details\.  Choice is unordered in GLR, I presume that Treesitter's actual
algorithm does something predictable with ambiguous parse forests, whether
that be refusing to compile, or resolving in a specific way \(greed I hope\)\.

There are Treesitter specs for a bunch of languages, and this stands to get
us to feature parity much faster than I had contemplated back when I thought
Treesitter grammars were written in Javascript\.


### Easy Part and Hard Part

The easy part is getting the overall structure of the grammar out, with
shuffling data from where Treesitter expects it to where I want itprecedence, for example\) the longer part of that\.

\(
The hard part is parsing and translating Javascript regular expressions, but
I need to do that anyway\.

```lua
local decode = use "util:json".decode
```


### Mauler

Step one is to compensate for JSON's inferiority by moving the natural array
portion of the data where it belongs\. SMDH\.

```lua
local function mauler(jstring)
   local json = assert(decode(jstring), "invalid json")

   local function make_idiomatic(tab)
      for k, v in pairs(tab) do
         if k == 'members' then
            for i, _v in ipairs(tab.members) do
               if type(_v) == 'table' then
                  make_idiomatic(_v)
               end
               tab[i] = _v
            end
            tab.members = nil
         elseif type(v) == 'table' then
            make_idiomatic(v)
         end
      end
   end
   make_idiomatic(json)

   return json
end
```

```lua
return mauler
```