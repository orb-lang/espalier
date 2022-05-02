















local Node = require "espalier:espalier/node"
local Grammar = require "espalier:espalier/grammar"
local Seer   = require "espalier:espalier/recognize"
local Phrase = require "singletons/phrase"
local core = require "qor:core" -- #todo another qor
local Set = core.set
local insert, remove, concat = assert(table.insert),
                               assert(table.remove),
                               assert(table.concat)
local s = require "status:status" ()








local Q = {}
























local Twig = Node :inherit()




local function __index(metabuild, key)
   metabuild[key] = Twig :inherit(key)
   return metabuild[key]
end



local M = setmetatable({}, {__index = __index})

