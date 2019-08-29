






local Node = require "espalier/node"
local core = require "singletons/core"
local inherit = assert(core.inherit)
local insert, remove, concat = assert(table.insert),
                               assert(table.remove),
                               assert(table.concat)






local Peg, peg = Node : inherit()
Peg.id = "peg"






local function _toSexpr(peg)
   local sexpr_line = {"("} -- Phrase?
   local name = peg.name or peg.id
   insert(sexpr_line, name)
   insert(sexpr_line, " ")
   for _, sub_peg in ipairs(peg) do
      insert(sexpr_line, _toSexpr(sub_peg))
      insert(sexpr_line, " ")
   end
   remove(sexpr_line)
   insert(sexpr_line, ")\n")

   return concat(sexpr_line)
end

Peg.toSexpr = _toSexpr






local PegMetas = Peg : inherit()
PegMetas.id = "pegMetas"

local Rules = PegMetas : inherit()
Rules.id = "rules"

local Rule = PegMetas : inherit()
Rule.id = "rule"



return { rules = Rules,
         rule  = Rule }
