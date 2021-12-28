

































































































































































local function refineMetas(metas)
  for id, meta in pairs(metas) do
    if id ~= 1 then
      if type(meta) == "table" then
        -- #todo is this actually necessary now?
        -- if all Node children are created with Node:inherit then
        -- it isn't.
        if not meta["__tostring"] then
          meta["__tostring"] = Node.toString
        end
        if not meta.id then
          meta.id = id
        end
      end
    end
  end
  if not metas[1] then
     metas[1] = Node
  end
  return metas
end
















local function _fromString(g_str)
   local maybe_lua, err = loadstring(g_str)
   if maybe_lua then
      return maybe_lua()
   else
      s : halt ("cannot make function:\n" .. err)
   end
end

local function _toFunction(maybe_grammar)
   if type(maybe_grammar) == "string" then
      return _fromString(maybe_grammar)
   elseif type(maybe_grammar) == "table" then
      -- we may as well cast it to string, since it might be
      -- and sometimes is a Phrase class
      return _fromString(tostring(maybe_grammar))
   end
end

local P = assert(L.P)





local function ʤ(inn)

end















local function dji(In, bottle)
   local template, = bottle.template, bottle.metas,
                                     bottle.pre, bottle.post
   local function define(template, metas, pre, post)
   if type(template) ~= "function" then
      -- see if we can coerce it
      template = _toFunction(template)
   end

   local metas = refineMetas(bottle.metas or {}
   local grammar = qoph(In, template, metas)
   local pre, post = bottle.pre, bottle.post

   local function parse(str, start, finish)
      local sub_str, begin = str, 1
      local offset = start and start - 1 or 0
      if start and finish then
         sub_str = sub(str, start, finish)
      end
      if start and not finish then
         begin = start
         offset = 0
      end
      if pre then
         str = pre(str)
         assert(type(str) == "string")
      end

      local match = L.match(grammar, sub_str, begin, str, metas, offset)
      if match == nil then
         return nil
      elseif type(match) == 'number' then
         return sub(sub_str, 1, match)
      end
      if post then
        match = post(match)
      end
      match.complete = match.last == #sub_str + offset
      return match
   end

   return parse, grammar
end
end



return dji

