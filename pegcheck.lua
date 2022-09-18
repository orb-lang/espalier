L = require "lpeg"
match, P = L.match, L.P

ts = use "repr:repr" . ts_color
core = use "qor:core"
string, table = core.string, core.table

Vav = require "espalier:vav"
sqlish = require "espalier:sqlish"
pgdb = require "espalier:peg/pegdebug"
trial = sqlish:try()
sqlTry = assert(string.slurp "sqlruns.sql")
num = Vav(sqlish.synth :pehFor 'number')

dbgSql = pgdb.trace(sqlish.test_pattern, {["+"] = false, ["/"] = false})

matched = match

print(ts(match(P(dbgSql), sqlTry, 1, sqlTry, {}, 0)))
