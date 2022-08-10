



















local core, cluster = use("qor:core", "cluster:cluster")

local pegpeg = require "espalier:peg/pegpeg"
local Metis = require "espalier:peg/metis"






local VavPeg = require "espalier:peg" (pegpeg, Metis) . parse








local new, Vav, Vav_M = cluster.order()

Vav.pegparse = VavPeg


cluster.construct(new,
   function(_new, vav, peh)
     vav.rules = VavPeg(peh)
     vav.peh = peh
     -- we'll have checks here
     vav.synth = vav.rules :synthesize()

      return vav
   end)




return new

