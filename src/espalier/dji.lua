































local function dji(In, _bottle)
   -- aka peh, the 'peh' load. heh. payload
   return function(str)
      return In(_bottle(str))
   end
end



return dji

