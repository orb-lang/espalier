



















local core, cluster = use("qor:core", "cluster:cluster")

local pegpeg = use "espalier:peg/pegpeg"
local Metis = use "espalier:peg/metis"






local VavPeg = use "espalier:peg" (pegpeg, Metis) . parse






local Grammar = use "espalier:espalier/grammar"






















local new, Vav, Vav_M = cluster.order()

Vav.pegparse = VavPeg


cluster.construct(new,
   function(_new, vav, peh)
     vav.grammar = VavPeg(peh)
     if vav.grammar then
        vav.grammar :hoist()
        vav.synth = vav.grammar :synthesize()
     else
        vav.failedParse = true
     end
     vav.peh = peh
     -- we'll have checks here

      return vav
   end)
















function Vav.constrain(vav)
   return vav.synth:constrain()
end








function Vav.dji(vav)
   if not vav.lpeg_engine then
      vav.lpeg_engine = vav.synth :toLpeg() :string()
   end
   -- we need more than this, notably the metis, but.
   vav.parse, vav.pattern = Grammar(vav.lpeg_engine)
   return vav.parse
end











function Vav.try(vav, rule)
   local synth = vav.synth
   if not synth.calls then
      synth:analyze()
   end

   local anomalous = synth:anomalies()
   if anomalous and anomalous.missing then
      synth:makeDummies()
   elseif not rule then
      return vav:dji()
   end
   if rule then
      local peh = synth:pehFor(rule)
      local ruleVav = new(peh)
      return ruleVav :try(), ruleVav
   end
   vav.peh_dummy = vav.peh .. vav.synth.dummy_rules
   vav.dummy = new(vav.peh_dummy)
   vav.test_engine = vav.dummy.synth :toLpeg() :string()
   vav.test_parse, vav.test_pattern = Grammar(vav.test_engine)
   return vav.test_parse
end



return new

