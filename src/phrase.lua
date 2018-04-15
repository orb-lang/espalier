
























local new, init
local s = require "core/status" ()
s.angry = false
local Phrase = setmetatable({}, {__index = Phrase})
Phrase.it = require "core/check"





















local function __concat(head_phrase, tail_phrase)

      if type(head_phrase) == 'string' then
         s:complain("NYI", "`string .. Phrase` is not yet possible")
         return "~~~NYI~~~"
      end
      local typica = type(tail_phrase)
      if typica == "string" then
         head_phrase[#head_phrase + 1] = tail_phrase
      else
         -- check for phraseness here
         local new_phrase = init()
         new_phrase[1] = head_phrase
         new_phrase[2] = tail_phrase
         return new_phrase
      end

      return head_phrase
end








local function __tostring(phrase)
  local str = ""
  for i,v in ipairs(phrase) do
    str = str .. tostring(v)
  end

  return str
end



local PhraseMeta = {__index = Phrase,
                  __concat = __concat,
                  __tostring = __tostring}




init = function()
   return setmetatable ({}, PhraseMeta)
end

new = function(phrase_seed)
   local phrase = init()
   local typica = type(phrase_seed)
   if typica == "string" then
      phrase[1] = phrase_seed
   else
      s:complain("NYI", "cannot accept phrase seed of type" .. typica)
   end
   return phrase
end




Phrase.idEst = new
return new
