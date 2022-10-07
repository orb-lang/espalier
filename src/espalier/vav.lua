






































local core, cluster = use("qor:core", "cluster:cluster")

local pegpeg = use "espalier:peg/pegpeg"
local Metis = use "espalier:peg/metis"






local VavPeg = use "espalier:peg" (pegpeg, Metis)
local Vpeg = VavPeg.parse






local Grammar = use "espalier:espalier/grammar"






















local new, Vav, Vav_M = cluster.order()

Vav.pegparse = VavPeg

local _reconcile;

cluster.construct(new,
   function(_new, vav, peh, mem, tav)
      vav.peh = peh
      vav.grammar = VavPeg(peh)
      if vav.grammar then
         vav.grammar :hoist()
         vav.synth = vav.grammar :synthesize()
         -- signature is slightly odd here b/c :analyze returns anomalies
         -- so a nil means that all is well
         if (not vav.synth:analyze()) then
            if (mem or tav)  then
               _reconcile(vav, mem, tav)
            end
         end
      else
         vav.failedParse = true
      end
      -- we'll have checks here

      return vav
   end)





















function _reconcile(vav, mem, tav)
   tav = tav or {}
   local ruleMap = assert(vav.synth.ruleMap)
   local traits = {}
   for name, meta in pairs(mem) do
      if not ruleMap[name] then
         -- rethink all of this with clades!
         error("Grammar has no '" .. name .. "' rule.")
      end
   end
   -- extend the clade for remaining rules
   local _;
   for name in pairs(ruleMap) do
      -- statement-oriented languages amirites
      _ = mem[name]
   end
   -- decorate with tavs
   for trait, members in pairs(tav) do
      for elem in pairs(members) do
         if not ruleMap[elem] then
            error("Trait '" .. trait
                  .. "' has unknown member '" .. elem .. "'.")
         end
         mem[elem].trait = true
      end
   end
end




















function Vav.constrain(vav)
   return vav.synth:constrain()
end






function Vav.anomalies(vav)
   return vav.synth:anomalies()
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

