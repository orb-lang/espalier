











local Phrase = setmetatable({}, {__index = phrase})
Phrase.isPhrase = Phrase

















local function cat(phrase, tail)
  if type(tail) == 'string' then
    return tail
  end
  --[[
  if type(tail) == 'string' then
    if type(phrase) == 'string' then
      return phrase .. tail
    else
      phrase[#phrase + 1] = tail
    end
  elseif type(phrase) == "string" then
    if type(tail) == "table" then
      return phrase .. tostring(tail)
    end
  else
  --]]
  phrase[#phrase + 1] = tail

  return phrase
end
Phrase.__concat = cat








local function toString(phrase)
  local str = ""
  for i,v in ipairs(phrase) do
    str = str .. tostring(v)
  end

  return str
end






local function new(_, str)
  local phrase = setmetatable({}, Phrase)
  if str then
    phrase[1] = str
  end
  return phrase
end

Phrase.__call = new






function Phrase.inherit(phrase)
  local Meta = setmetatable({}, phrase)
  Meta.__index = Meta
  Meta.__call  = getmetatable(phrase).__call
  Meta.__concat = getmetatable(phrase).__concat
  local meta = setmetatable({}, Meta)
  meta.__index = meta
  return Meta, meta
end



return setmetatable({}, {__call = new})
