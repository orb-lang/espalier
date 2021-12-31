# Dji combinator


Because dji not\.

Because Dji said so\.

Be\. cause\.

Jed

Eye

Said so\.

\-@

P\.S\. These are not the djroids you're lookin for\.\.\.


## ι Ο → Υ  → Φ → Ψ

```clu
(def iota [sigma omicron] psi)

(def omicron [heh] phi)

(def heh [gamma mu] sigma)

; (def sigma [phi] psi)
```

\(Γ Μ → Σ\)

  Shall I explain further?

Very well\.  Trivial though it must be stated: we use the point free style\.

Sally Forth\!


### ι aka י aka ʤ

The combinator itself, **dji**, or **iota**, or **yoda**, or **yod**\.

Preferentially spelled `ʤ` in most contexts, iota itself being mercilessly
overloaded, and yod invokes the spirit of bidirectionality, which is too much
mojo for many systems to handle, including, I must red\-facedly confess, the
current iteration of the bridge\.

Thanks to LuaJIT, we can just\.\.\. do that\.


### Ο aka endjinn aka engine aka in\-dji aka omicron, if you simply must

The dji combinator takes two arguments, as a combinator must\.

The first is the *engine*, this is the lambda which takes action on the final
argument \(the *sentence*\), **iff** the sentence passes the mold of the *bottle*,
which is the second argument\.


#### Hey\. Hey\! Not just for horses\! A Kay A ה\!

I did not so much forget as simply not mention until just now\!

So\. Mentioned\.


### Returning Υ aka ן, Rod, or Hook

  This should not be confused with the `y` combinator, Vav \(in the preferred
form\) is the memorizing combinator\.  It learns to take structure and apply it
to the latent form which dji has curried it to with the ingenium\.

This is in turn applied to the **bottle** combinator\.


### Bottle, Φ, fie, fo, fum

The *bottle* is a **grammar**, the syntax of which is metasyntactically defined
in terms of a particular form of grammar, as indeed it must be\.

Because the rigor of the underlying system derives from the separate proofs
we can derive from the basic axioms of combination, we prefer the universe we
find through a left\-favouring deterministic choice principle for the **alt**
combinator, `/`\.

This is of course no requirement, merely a simplifying assumption which we
will use throughout the derivation of this combinator\.  It happens to also be
a requirement of the *djin* underlying this specific implementation, which is
no kind of coincidence\.


###  Which is the Qopf, Dummkopf

Heh\.  Dummkopf was the mild one on the playground, when we really wanted to
get salty we'd bring out the Äselsheiss

It's a weird game a getting raised in the Midwest I tell ya


#### ק\.

Yeah\.  The Qopf\.

Did I stutter\. I did not\.


### Returning Ψ, also known as the Parsel, or ף, or the Peh Load

Hehehe get it\. "Peh" load\.

Do you see what I did there

Do you

No look, closer\.  I insist\.  I simply must insist\.

Don't make this any more hawkward than it is already\. Look\. Closer\.

Payload\. It's a

Yeah\. Psi Phi\. I'm also pretty pleased about it


## ʤ\(inn: Injin\) \-> qoph : Qopf


  There we go\.  Comfy, like my favourite cardigan\.

Which is, no mames, made from a shaved yak\.

Long story there, would be a digression to tell it here, which is a caution\.
A pity, almost\.

In the current year, typing the search string 'cardigan' into your musical
search engine of choice will produce a soundtrack appropriate to the raag\.
Which one might roughly translate as, mood\.


### Implementation

This being a proof of concept, the details of the implementation are somewhat
specific to the task at hand\.  We shall find these to be suitably abstracted
as the programme continues, we fervently wish\.


#### On the Parameters Which, Combined, Are Applied to the Hook

The Ingenium returns the Rod, or Hook, which itself expects a






### refineMetas\(metas\)

Takes metatables, distributing defaults and denormalizations\.

```lua
local function refineMetas(metas)
  for id, meta in pairs(metas) do
    if id ~= 1 then
      if type(meta) == "table" then
        -- #todo is this actually necessary now?
        -- if all Node children are created with Node:inherit then
        -- it isn't.
        if not meta["__tostring"] then
          meta["__tostring"] = Node.toString
        end
        if not meta.id then
          meta.id = id
        end
      end
    end
  end
  if not metas[1] then
     metas[1] = Node
  end
  return metas
end
```

#### \_fromString\(g\_str\), \_toFunction\(maybe\_grammar\)

Currently this is expecting pure Lua code; the structure of the module is
such that we can't call the PEG grammar from `grammar.orb` due to the
circular dependency thereby created\.

\#Todo
the module, since it would happen at run time, not load time\.  This might not
be worthwhile, but it's worth thinking about at least\.

This implies wrapping some porcelain around everything so that we can at least
try to build the declarative form first\.

```lua
local function _fromString(g_str)
   local maybe_lua, err = loadstring(g_str)
   if maybe_lua then
      return maybe_lua()
   else
      s : halt ("cannot make function:\n" .. err)
   end
end

local function _toFunction(maybe_grammar)
   if type(maybe_grammar) == "string" then
      return _fromString(maybe_grammar)
   elseif type(maybe_grammar) == "table" then
      -- we may as well cast it to string, since it might be
      -- and sometimes is a Phrase class
      return _fromString(tostring(maybe_grammar))
   end
end

local P = assert(L.P)
```



```lua
local function ʤ(inn)

end
```


## bottle

  \.\.\.curry the dji recognizer?

yeah ok but how about, a little dash in that curry?\!


### dji\(in, \_bottle\)

qed


#### qoph\(In, template, metas\)

```lua
local function qoph(In, template, metas)
      g = g or {}
   if e == nil then
      e = VER == " 5.1" and getfenv(func) or _G
   end
   local suppressed = {}
   local env = {}
   local env_index = {
      START = function(name) g[1] = name end,
      SUPPRESS = function(...)
         suppressed = {}
         for i = 1, select('#', ...) do
            suppressed[select(i, ... )] = true
         end
      end,
      V = L.V,
      P = L.P }

    setmeta(env_index, { __index = e })
    setmeta(env, {
       __index = env_index,
       __newindex = function( _, name, val )
          if suppressed[ name ] then
             g[ name ] = val
          else
             g[ name ] = Cc(name)
                       * Cp()
                       * Ct(val)
                       * Cp()
                       * arg1_str
                       * arg2_metas
                       * arg3_offset / make_ast_node
          end
       end })

   -- call passed function with custom environment (5.1- and 5.2-style)
   if VER == " 5.1" then
      setfenv(func, env )
   end
   func( env )
   assert( g[ 1 ] and g[ g[ 1 ] ], "no start rule defined" )
   return g

end
```


```lua
local function dji(In, bottle)
   local template, = bottle.template, bottle.metas,
                                     bottle.pre, bottle.post
   local function define(template, metas, pre, post)
   if type(template) ~= "function" then
      -- see if we can coerce it
      template = _toFunction(template)
   end

   local metas = refineMetas(bottle.metas or {}
   local grammar = qoph(In, template, metas)
   local pre, post = bottle.pre, bottle.post

   local function parse(str, start, finish)
      local sub_str, begin = str, 1
      local offset = start and start - 1 or 0
      if start and finish then
         sub_str = sub(str, start, finish)
      end
      if start and not finish then
         begin = start
         offset = 0
      end
      if pre then
         str = pre(str)
         assert(type(str) == "string")
      end

      local match = L.match(grammar, sub_str, begin, str, metas, offset)
      if match == nil then
         return nil
      elseif type(match) == 'number' then
         return sub(sub_str, 1, match)
      end
      if post then
        match = post(match)
      end
      match.complete = match.last == #sub_str + offset
      return match
   end

   return parse, grammar
end
end
```

```lua
return dji
```
