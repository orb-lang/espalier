



















local core, cluster = use("qor:core", "cluster:cluster")

local pegpeg = use "espalier:peg/pegpeg"
local Metis = use "espalier:peg/metis"






local VavPeg = use "espalier:peg" (pegpeg, Metis) . parse






local Grammar = use "espalier:espalier/grammar"








local new, Vav, Vav_M = cluster.order()

Vav.pegparse = VavPeg


cluster.construct(new,
   function(_new, vav, peh)
     vav.rules = VavPeg(peh)
     if vav.rules then
        vav.rules :hoist()
        vav.synth = vav.rules :synthesize()
     else
        vav.failedParse = true
     end
     vav.peh = peh
     -- we'll have checks here

      return vav
   end)
















function Vav.dji(vav)
   if not vav.lpeg_engine then
      vav.lpeg_engine = vav.synth :toLpeg() :string()
   end
   -- we need more than this, notably the metis, but.
   vav.parse, vav.grammar = Grammar(vav.lpeg_engine)
   return vav.parse
end




return new

