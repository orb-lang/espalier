










































local decode = use "util:json".decode









local function mauler(jstring)
   local json = assert(decode(jstring), "invalid json")

   local function make_idiomatic(tab)
      for k, v in pairs(tab) do
         if k == 'members' then
            for i, _v in ipairs(tab.members) do
               if type(_v) == 'table' then
                  make_idiomatic(_v)
               end
               tab[i] = _v
            end
            tab.members = nil
         elseif type(v) == 'table' then
            make_idiomatic(v)
         end
      end
   end
   make_idiomatic(json)

   return json
end



return mauler

