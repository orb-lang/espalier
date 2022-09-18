Vav = use "espalier:vav"
ts = use "repr:repr" . ts_color

sqlish = use "espalier:sqlish"

sqlDji = sqlish:try()

---[[*]] print(sqlish.peh_dummy)
--[[*]] print(sqlish.test_engine)

slurp = use "qor:core" .string.slurp

--[[*]] sqlDji(slurp('sqlruns.sql'))
