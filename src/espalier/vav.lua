





















local core, cluster = use("qor:core", "cluster:cluster")

local pegpeg = use "espalier:peg/pegpeg"
local Metis = use "espalier:peg/metis"
local NodeClade = use "espalier:peg/nodeclade"

local Qoph = use "espalier:peg/bootstrap"






local VavPeg = use "espalier:peg" (pegpeg, Metis)
local Vpeg = VavPeg.parse






local Grammar = use "espalier:espalier/grammar"























local new, Vav, Vav_M = cluster.order()

Vav.pegparse = VavPeg

local _reconcile;

cluster.construct(new,
   function(_new, vav, peh, mem)
      vav.peh = peh
      vav.grammar = VavPeg(peh)
      if vav.grammar then
         vav.grammar :hoist()
         vav.synth = vav.grammar :synthesize()
         -- signature is slightly odd here b/c :analyze returns anomalies
         -- so a nil means that all is well
         if (not vav.synth:analyze()) then
            if mem then
               -- first example of using a method off the seed
               _new.Mem(vav, mem)
            end
         end
      else
         vav.failedParse = true
      end
      -- we'll have checks here

      return vav
   end)










--- WARNING!!!
--  This mutates NodeClade, which is intended as an 'abstract' base genre.
--  Specialization of Clades should be added ASAP.

function Vav.Mem(vav, mem)
   if not mem then
      mem = NodeClade
   end
   local ruleMap = assert(vav.synth.ruleMap)
   local tape = assert(mem.tape, "mem is missing the tape, bad clade?")
   -- first we make sure no keys on the tape are missing a rule
   for tag in pairs(tape) do
      if type(tag) ~= 'string' then
         goto continue
      end
      if not ruleMap[tag] then
         local name = vav.synth[1][1][1].token -- absurd thing to do
         error("Mem has a phyle named " .. tag
               .. ", no such rule in Peh("
                .. name .. ").")
      end
      ::continue::
   end
   -- next we fill out the clade with any rules without genre
   local _;
   for rule in pairs(ruleMap) do
      _ = tape[rule]
   end
   -- last, coalesce the clade, which might make a clone of mem
   vav.mem = assert(mem:coalesce())

   return vav
end



















function Vav.complete(vav)
   -- obvious stub
   return true
end











function Vav.constrain(vav)
   return vav.synth:constrain()
end






function Vav.anomalies(vav)
   return vav.synth:anomalies()
end








function Vav.Dji(vav)
   if not vav.mem then
      vav:Mem()
   end
   vav.dji = Qoph(vav)
   return vav.dji
end






function Vav.toLpeg(vav)
   if vav.lpeg_engine then
      return vav.lpeg_engine
   end
   vav.lpeg_engine = vav.synth :toLpeg() :string()
   if not vav.lpeg_engine then
      error "Lpeg function was not created"
   end

   return vav.lpeg_engine
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

