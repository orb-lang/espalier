
























local pegpeg = require "espalier:peg/pegpeg"









local Metis = require "espalier:peg/metis"






local VavPeg = require "espalier:peg" (pegpeg, Metis) . parse






local function Vav(peg_string)
   local rules = VavPeg(peg_string)
   -- we'll have checks here

   return rules :synthesize()
end



return Vav

