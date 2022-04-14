# Shunting Yard Metafunction


  Enchance a Parsing Expression Grammar with a declarative operator\-precedence
parser\.


## Rationale

  Parsing Expression Grammars are a powerful and general abstraction for
implementing parsers on structured data\.  They are able to recognize an
operator syntax easily, with a short rule of this nature:

```peg
expression  ←  _ expr _

`expr`  ←  unop
        /  value _ (binop  _ expr)*
        /  group

group  ←  "(" _ expr _ ")"
```

In fact we don't need the outer rule `expression`, which is there so we can
apply this algorithm to the results\.

The issue with this sort of rule is that it ignores precedence and
associativity\.  Those are qualities of the parse tree rather than the stream\.

It's certainly possible to build a PEG which results in the parse tree which
the user requires, but this complicates the grammar considerably, due to
limitations on left recursion\.

There are a number of strategies to approach this, but let me make a different
argument: there is *nothing wrong whatsoever* with the rule given above, it
is practically speaking ideal in terms of saying what it means\.


## Implementation

  This module takes a collection of facts about rules, and returns a function
to be used in metatable assignment by a grammar implementing those rules\.

In this case, we would assign that metatable to the rule `expression`, and the
algorithm given here will rearrange the Nodes according to arity, precedence,
and associativity, assigning appropriate metatables, and returning an
expression with the correct tree structure\.

It does this using the Shunting Yard Algorithm, hence the name\.


#### imports

```lua
local Node = require "espalier:espalier/node"
local Set = require "qor:core/set"
```


### Shunter

We are given `precedence`, `unary`, and `right_assoc`\.  The latter two are
Sets, the first returns a number, and all are keyed on the `.id` field of the
Node\.

We need precedence and associativity to decide when to shunt, which we will
close over in generating the shunter\.


#### comparator\(precedence: \{ string = number \}, r\_assoc: Set\): \(Node, Node\): boolean

Generates our comparison function\.

```lua
local function comparator(precedence, right_assoc)
   local function higher(op1, op2)
      local id1, id2 = op1.id, op2.id
      if (prec[id1] > prec[id2])
         or (prec[id1] == prec[id2] and not r_assoc[id2]) then
         return true
      else
         return false
      end
   end

   return higher
end
```


### Minimum Viable Stack

  While we have a full\-featured Deque, there is no equivalent Stack
abstraction yet\.

This is a viable standin in the meantime\.

```lua
local insert, remove = assert(table.insert), assert(table.remove)

local Stack_idx = {}

function Stack_idx.push(stack, val)
   insert(stack, val)
end

function Stack_idx.pop(stack, num)
   if num then
      local values = {}
      for i = 1, num do
         values[i] =  remove(stack)
      end
      return unpack(values)
   else
      return remove(stack)
   end
end

local Stack_M = { __index = Stack_idx }

local function Stack()
   return setmetatable({}, Stack_M)
end
```


#### shunter\(precedence, unary, grouped, higher, link\): \(Node\) \-> Deque\[Node\]

The shunter generator doesn't need to close over associativity, which is
already covered by `higher`\.

It does need to close over everything else\.


### shunt\(expr: Node\): Deque\[Node\]

A textbook Page from The Book\.

```lua
local function shunter(precedence, unary, grouped, higher, link)

   local function shunt(expr)
      local stack = Stack()
      local out   = Deque()
      for i, elem in ipairs(expr) do
         -- operations have precedence, values and groups don't
         local prec = precedence[elem.id]
         if not prec then
            if grouped[elem.id] then
               -- recurse
               local _out = shunt(elem)
               local top = #elem
               elem[1] = link(_out, elem)
               for i = 2, top do
                  elem[i] = nil
               end
               out:push(elem)
            else
               out:push(elem)
            end
         else
            local shunting = true
            while shunting do
               if #stack == 0 or unary[elem.id] then
                  stack:push(elem)
                  shunting = false
               else
                  local top = stack[#stack]
                  if higher(top, elem) then
                     out:push(stack:pop())
                  else
                     stack:push(elem)
                     shunting = false
                  end
               end
            end
         end
      end
      while #stack > 0 do
         out:push(stack:pop())
      end
      local phrase = {}
      for elem in out:peekAll() do
         insert(phrase, elem:span())
      end
      expr.RPN = table.concat(phrase, " ")
      return out
   end

   return shunt
end
```


#### linker\(is\_operator\): \(out, expr\): Node

  The upvalue for this generator is just `precedence` again, but here being
used to test for operators\.

```lua
local function linker(is_operator, Twig)
   local function link(out, expr)
      local stack = Stack()
      for elem in out:popAll() do
         if is_operator[elem.id] then
            local child = setmetatable({ id = elem.id, str = expr.str }, Twig)
            if unary[elem.id] then
               child[1] = stack:pop()
               child.first, child.last = elem.first, child[1].last
            else
               local right, left = stack:pop(2)
               child[1], child[2] = assert(left),
                                    assert(right)
               child.first, child.last = left.first, right.last
            end
            stack:push(child)
         else
            stack:push(elem)
         end
      end
      if #stack ~= 1 then
         expr.RPN = expr.RPN .. "bad stack (" .. #stack .. ")"
         return expr
      end
      local result = stack:pop()
      result.RPN = expr.RPN
      return result
   end

   return link
end
```


### new\(cfg\)

This is a case where a literal table is going to be the most legible way to
write the constructor\.

We'll circle back and make more metatables later\.

```lua
local function new(cfg)
   local precedence = assert(cfg.precedence)
   local right_assoc = assert(cfg.right_assoc)
   local unary = assert(cfg.unary)
   local grouped = assert(cfg.grouped)
   local higher = comparator(precedence, right_assoc)
   local Twig = cfg[1] or Node
   local link = linker(precedence, Twig)
   local shunt = shunter(precedence, unary, grouped, higher, link)

   local function Expression(expr)
      local out = shunt(expr)
      local new = link(out, expr)
      return setmetatable({ new,
                            str = expr.str,
                            first = expr.first,
                            last = expr.last }, Twig)
   end

   return Expression
end
```

```lua
return new
```
