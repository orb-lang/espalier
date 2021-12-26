
























local function dji(In, bottle)
   return function(str)
      return In(bottle(str))
   end
end



return dji

