



































































local Node = require "espalier:espalier/node"
local Set = require "qor:core/set"
local Deque = require "deque:deque"


















local function comparator(precedence, right_assoc)
   local function higher(op1, op2)
      local id1, id2 = op1.id, op2.id
      if (precedence[id1] > precedence[id2])
         or (precedence[id1] == precedence[id2]
             and not right_assoc[id2]) then
         return true
      else
         return false
      end
   end

   return higher
end











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









local function linker(is_operator, unary, Twig)
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











local function new(cfg)
   local precedence = assert(cfg.precedence)
   local right_assoc = Set(assert(cfg.right_assoc))
   local unary = Set(assert(cfg.unary))
   local grouped = Set(assert(cfg.grouped))
   -- Set up the metatable
   local _Twig = cfg[1]
   local id = cfg[2]
   local Twig;
   if _Twig and id then
      Twig = _Twig :inherit(id)
   elseif _Twig then
      Twig = Twig
   else
      Twig = Node
   end

   local higher = comparator(precedence, right_assoc)

   local link = linker(precedence, unary, Twig)
   local shunt = shunter(precedence, unary, grouped, higher, link)

   local function Expression(expr)
      local out = shunt(expr)
      local new = link(out, expr)
      return setmetatable({ new,
                            id  = id or expr.id,
                            str = expr.str,
                            first = expr.first,
                            last = expr.last }, Twig)
   end

   return Expression
end



return new

