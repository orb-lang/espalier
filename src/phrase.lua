
























local init, new
local s = require "core/status" ()
s.angry = false
local Phrase = setmetatable({}, {__index = Phrase})
Phrase.it = require "core/check"





















local function __concat(head_phrase, tail_phrase)
   if type(head_phrase) == 'string' then
      -- bump the tail phrase accordingly
      local cursor = tail_phrase[1]
      tail_phrase[1] = head_phrase
      for i = 2, #tail_phrase + 1 do
         tail_phrase[i] = cursor
         cursor = tail_phrase[i + 1]
      end
      assert(cursor == nil)
      tail_phrase.len = tail_phrase.len + #head_phrase
      return tail_phrase
   end

   local typica = type(tail_phrase)
   if typica == "string" then
      head_phrase[#head_phrase + 1] = tail_phrase
      head_phrase.len = head_phrase.len + #tail_phrase
      return head_phrase
   elseif typica == "table" and tail_phrase.idEst == new then
      -- check for phraseness here
      local new_phrase = init()
      new_phrase[1] = head_phrase
      new_phrase[2] = tail_phrase
      new_phrase.len = head_phrase.len + tail_phrase.len
      return new_phrase
   end

   return nil, "tail phrase was unsuitable for concatenation"
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
   phrase_seed = phrase_seed or ""
   local phrase = init()
   local typica = type(phrase_seed)
   if typica == "string" then
      phrase[1] = phrase_seed
      phrase.len = #phrase_seed
   else
      s:complain("NYI", "cannot accept phrase seed of type" .. typica)
   end
   return phrase
end




Phrase.idEst = new
return new
