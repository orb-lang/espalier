# Bozo


This is an experiment where we pass the bozo bit\.

Meant to exercise the Vector system in Clades, and figure out how the
propagation business is supposed to work\.


```lua
local V, bozo = {}, {}
V.bozo = bozo
```

```lua
local function Bozo(node)
   local the_bozo = true
   for i, child in ipairs(node) do
      the_bozo = the_bozo and child:bozo()
   end
   return the_bozo
end
```

```lua
function bozo.grammar(grammar)
   local bozz = true
   for _, child in ipairs(grammar) do
      bozz = bozz and child:bozo()
   end
   if bozz then
      grammar.the_bozo = "bozo!"
   end
end
```

```lua
bozo[1] = Bozo
```


### ok\. what's the real bozo

It's all about rules and names\.

So the real bozo:


-  The rule bozo: tries to get the bozo off all rules\.
    if not, it sets up an `await` and yields\.

    When complete, if it has the bozo, sends the bozo to all references\.


-  The name bozo:

    if the rule has the bozo, pass the bozo to the reference\.


-  =bozoUpdate=: propagates the bozo to the parent\.ºk


### Hmmm

I should actually write useful code here, not bozology\.



```lua
return V
```
