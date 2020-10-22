






local Peg = require "espalier/peg"
local input = ""
while true do
   local newline = io.stdin:read()
   if newline == nil or string.byte(newline) == 17 then
      os.exit(0)
   end
   input = input .. newline .. "\n"
   local res, err = loadstring(input)
   if res then
      res_tab = res()
      if type(res_tab) == table and res_tab.grammar and res_tab.input then
         local ok, peg = pcall(Peg, res_tab.grammar)
         if ok then
            local output = {grammar = peg:toString()}
            local parse = peg:toGrammar()
            local tree
            ok, tree = pcall(parse, res_tab.input)
            if ok then
               output.tree = tree:toString()
            end
            io.stdout:write(output.grammar .. "\n\n")
            if output.tree then
               io.stdout:write(output.tree)
            end
         end
      else
         io.stdout:write "must return a table with grammar and input fields"
      end
      input = ""
   end
end

