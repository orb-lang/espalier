# Working backward toward Qoph

Our grammar generator has been serviceable but isn't general\.

Making it general is what the Qoph combinator is all about, and right now
what we need is a capture pattern and function\.

```lua
local L = use "lpeg"
local core, cluster = use("qor:core", "cluster:cluster")
local table = core.table

local NodeClade = use "espalier:peg/nodeclade"
```

```lua
local NodeQoph = {}
```

This is tricky because it's called at build\-time and the function provides
`name, val`\.  I don't believe lpeg has facilities for deconstructing patterns,
which are opaque, broadly speaking, once composed\.

We're left specifying an array of patterns with placeholders\. Which isn't
so bad\.

```lua
local Cp = L.Cp
local Cc = L.Cc
local Ct = L.Ct
local Carg = L.Carg

NodeQoph.capturePattern = {'name', Cp, 'capture', Cp,
                           {Carg, 1}, {Carg, 2}, {Carg, 3}}
```

This is\.\. usable, broadly speaking\. More complex patterns can be captured by
e\.g\. `{'choice', patt, patt}`, and we can usefully replace the positional
arguments with known quantities for Vav to then pass into `match`
positionally, e\.g\. instead of `{Carg, 1}` we can say `'input'` or `'string'`,
`'metis'` for `Carg(2)` and so on\.

Another possibility, a neater one, is to have one additional argument at the
end of the pattern, provided by Qoph\.  Which can be as simple as just the
string, but can also be a table containing anything Dji builds in\.

We could keep the reified pattern call with arguments thing here, but the
passing of state into the recognition function benefits from a single and
implied API\.

The constructed pattern is applied against an `oncapture` function, like so:

```lua
local compact = assert(table.compact)

function NodeQoph.oncapture(class, first, capture, last, str, metas, offset)
   t.first = first + offset
   t.last  = last + offset - 1
   t.str   = str
   if metas[class] then
      local meta = metas[class]
      if type(meta) == "function" then
        t.class = class
        t = meta(t, offset)
      else
        t = setmeta(t, meta)
      end
      assert(t.class, "no class on Node")
   else
      t.class = class
      setmeta(t, metas[1])
   end

   if not t.parent then
      t.parent = t
   end

   local top, touched = #t, false
   for i = 1, top do
      local cap = t[i]
      if type(cap) ~= "table" or not cap.isNode then
         touched = true
         t[i] = nil
      else
         cap.parent = t
      end
   end
   if touched then
      compact(t, top)
   end
   -- post conditions
   assert(t.isNode, "failed isNode: " .. class)
   assert(t.str, "no string on node")
   assert(t.parent, "no parent on " .. t.class)
   return t
end
```

This is only a slight change from `grammar.orb`, I figure it's always nice to
get consistent results before taking off in a different direction\.

Speaking of which: rather than split attention between modules, let's write
a start on Qoph\.

This being another port of Grammar, with some extras\.

```lua
local ltype = assert(L.type)
local V, P = L.V, L.P

local function makeBuilder(Qoph, engine, ...)
   -- these defaults should result in a 'pure' recognizer
   local capture_patt, oncapture = Qoph.capture_patt or {P(true)},
                                   Qoph.oncapture
   local _env = Qoph.env or {}
   local g = {}
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
      V = V,
      P = P }

    setmetatable(env_index, { __index = _env })

    setmetatable(env, {
       __index = env_index,
       __newindex = function( _, name, capture )
          if suppressed[name] then
             g[name] = capture
             return
          end

          local patt = P ""
          for _, pattern in ipairs(capture_patt) do
             -- special cases
             if pattern == 'name' then
                patt = patt * Cc(name)
             elseif pattern == 'capture' then
                patt = patt * Ct(value)
             elseif type(pattern) == 'function' then
                patt = patt * pattern()
             elseif ltype(pattern) == 'pattern' then
                patt = patt * pattern
             elseif type(pattern) == 'table' then
                patt = patt * pattern[1](unpack(pattern, 2))
             end
             if oncapture then
                g[name] = patt / oncapture
             else
                g[name] = patt
             end
          end
       end })

   return function(func)
      setfenv(func, env )
      func( env )
      assert( g[ 1 ] and g[ g[ 1 ] ], "no start rule defined" )
      return g
   end
end
```

So that looks approximately correct\.


#### Qoph Notes: Node 2

Right now, Vav itself is backed by the original Pegylator\.

`Vav:dji()` just calls Grammar a second time, and that's where we move to the
new framework\.

This should look like:

```lua
function Vav.dji(vav)
   if not vav.lpeg_engine then
      vav.lpeg_engine = vav.synth :toLpeg() :string()
   end
   return Qoph(vav)
end
```

Where Qoph returns Dji\.

This is incorrect in some ways, let's not worry about those\.

```lua
local function Qoph(vav)
   if not vav.mem then
      vav.mem = NodeClade
   end

end
```


```lua
return {NodeQoph = NodeQoph}
```
