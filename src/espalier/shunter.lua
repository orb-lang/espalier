



































































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
















local function shunter(precedence, unary, higher, link)

   local function shunt(expr)
      local stack = Stack()
      local out   = Deque()
      for _, elem in ipairs(expr) do
         -- operations have precedence, values and groups don't
         local prec = precedence[elem.id]
         if precedence[elem.id] then
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
         else
            out:push(elem)
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









local function linker(is_operator, unary, Metas)
   local function link(out, expr)
      local stack = Stack()
      for elem in out:popAll() do
         if is_operator[elem.id] then
            local id = elem.id
            local child = setmetatable({ id = id,
                                         str = expr.str }, Metas[id])
            if unary[id] then
               child[1] = stack:pop()
               child.first, child.last = elem.first, child[1].last
               child[1].parent = child
            else
               local right, left = stack:pop(2)
               child[1], child[2] = assert(left),
                                    assert(right)
               right.parent, left.parent = child, child
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

   -- Set up the metatables
   local _Twig = cfg[1]
   local id = cfg[2]
   local Twig, Expr;
   if id then
      Expr = _Twig :inherit(id)
   else
      Expr = _Twig
   end
   if _Twig then
      Twig = _Twig
   else
      Twig = Node
   end

   local Metas = {}
   for id in pairs(precedence) do
      Metas[id] = Twig:inherit(id)
   end

   local higher = comparator(precedence, right_assoc)

   local link = linker(precedence, unary, Metas)
   local shunt = shunter(precedence, unary, higher, link)

   local function Expression(expr)
      -- no need to shunt #expr == 1
      if #expr == 1 then
         return setmetatable(expr, Expr)
      end
      local out = shunt(expr)
      local _expr = { link(out, expr),
                id    = expr.id,
                str   = expr.str,
                first = expr.first,
                last  = expr.last }

      return setmetatable(_expr, Expr)
   end

   return Expression, Metas
end



return new

