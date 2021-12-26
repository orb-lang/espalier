














local L = require "lpeg"
local assert = assert
local string = assert(string)
local sub = assert(string.sub)
local remove = assert(table.remove)
local VER = sub(assert(_VERSION), -4)
local _G = assert(_G)
local error = assert(error)
local pairs = assert(pairs)
local next = assert(next)
local type = assert(type)
local tostring = assert(tostring)
local setmeta = assert(setmetatable)
if VER == " 5.1" then
   local setfenv = assert(setfenv)
   local getfenv = assert(getfenv)
end









































return recognizer

