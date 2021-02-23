









local lpeg = require "lpeg"
local C, Cmt, Ct = assert(lpeg.C),
                   assert(lpeg.Ct),
                   assert(lpeg.Ct)
local P, R, S, V = assert(lpeg.P),
                   assert(lpeg.R),
                   assert(lpeg.S),
                   assert(lpeg.V)





local elpatt = {}
for k, v in pairs(lpeg) do
   elpatt[k] = v
end





















local I = lpeg.Cp()

function elpatt.anywhere(p)
     return P{ I * C(p) * I + 1 * V(1) }
end



















local function rep(patt, n, m)
   patt = P(patt)
   assert(n, "missing argument #2 to 'rep' (n is required)")
   assert(n >= 0, "bad argument #2 to 'rep' (n cannot be negative)")
   assert(not m or m >= n, "bad argument #3 to 'rep' (m must be >= n)")
   -- m == n is equivalent to omitting m altogether, easiest to
   -- take care of this up front
   if m == n then
      m = nil
   end
   if n == 0 then
      if m then
         return patt ^ -m
      else
         return -patt
      end
   else
      local answer = patt
      for i = 1, n - 1 do
         answer = answer * patt
      end
      if m then
         answer = answer * patt^(n - m)
      end
      return answer
   end
end

elpatt.rep = rep
















function elpatt.M(tab)
   local rule
   for k in pairs(tab) do
      assert(type(k) == 'string', "Keys passed to M() must be strings")
      rule = rule and rule + P(k) or P(k)
   end
   return rule / tab
end
























local utf8_cont = R"\x80\xbf"
local utf8_char = R"\x00\x7f" +
                  R"\xc2\xdf" * utf8_cont +
                  R"\xe0\xef" * rep(utf8_cont, 2) +
                  R"\xf0\xf4" * rep(utf8_cont, 3)
local utf8_str  = Ct(C(utf8_char)^0) * -1
local ascii_str = R"\x00\x7f"^0 * -1








local codepoint = assert(require "lua-utf8" . codepoint)
local inbounds = assert(require "core:math" . inbounds)
local insert = assert(table.insert)
local assertfmt = assert(require "core:fn" . assertfmt)

local function R_unicode(...)
   local args = pack(...)
   local ascii_ranges, utf_ranges = {}, {}
   for i, range in ipairs(args) do
      if ascii_str:match(range) then
         -- Throw this error here while we still know which argument this was
         assertfmt(#range == 2,
            "bad argument #%d to 'R' (range must have two characters)", i)
         insert(ascii_ranges, range)
      else
         range = utf8_str:match(range)
         assertfmt(range, "bad argument #%d to 'R' (invalid utf-8)", i)
         assertfmt(#range == 2,
            "bad argument #%d to 'R' (range must have two characters)", i)
         insert(utf_ranges, { codepoint(range[1]), codepoint(range[2]) })
      end
   end
   local answer;
   if #ascii_ranges > 0 then
      answer = R(unpack(ascii_ranges))
   end
   if #utf_ranges ~= 0 then
      local utf_answer =  P(function(subject, pos)
           local char = C(utf8_char):match(subject, pos)
           if not char then return false end
           local code = codepoint(char)
           for _, range in ipairs(utf_ranges) do
              if inbounds(code, range[1], range[2]) then
                 return pos + #char
              end
           end
           return false
        end)
      answer = answer and answer + utf_answer or utf_answer
   end
   return answer
end

elpatt.R = R_unicode








local concat, insert = assert(table.concat), assert(table.insert)

local function S_unicode(chars)
   -- We *could* skip this early-out and we'd still return an identical
   -- pattern, since we separate out the ASCII characters below,
   -- but let's keep the degenerate case clear and fast
   if ascii_str:match(chars) then
      return S(chars)
   end
   chars = utf8_str:match(chars)
   assert(chars, "bad argument #1 to 'S' (invalid utf-8)")
   local patt;
   local ascii_chars = {}
   for _, char in ipairs(chars) do
      if #char == 1 then
         insert(ascii_chars, char)
      else
         patt = patt and P(char) + patt or P(char)
      end
   end
   if #ascii_chars > 0 then
      patt = patt and S(concat(ascii_chars)) + patt or S(concat(ascii_chars))
   end
   return patt
end

elpatt.S = S_unicode













function elpatt.U(n, m)
   n = n or 1
   return rep(utf8_char, n, m)
end
















function elpatt.split(str, sep)
  sep = P(sep)
  local elem = C((1 - sep)^0)
  local patt = Ct(elem * (sep * elem)^0)   -- make a table capture
  return patt:match(str)
end













local Cs = assert(lpeg.Cs)
function elpatt.gsub(str, patt, repl)
   patt = P(patt)
   if repl then
      patt = patt / repl
   end
   patt = Cs((patt + 1)^0)
   return patt:match(str)
end




return elpatt

