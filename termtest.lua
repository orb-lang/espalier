Lume = require "orb:lume"
Skein = require "orb:skein"
core = require "core:core"
uv = require "luv"
ll = Lume(uv.cwd(), "", true)
sk = Skein("/Users/atman/Dropbox/br/espalier/orb/espalier/grammar.orb", ll)
ll:run()
sk:transform()
