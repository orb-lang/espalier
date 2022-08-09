




local regex = {}


regex.xs_pattern = [[
regex <- branch ("|" branch)*
branch <- piece+

piece <- suffixed / atom
`suffixed` <- optional / zero-plus / one-plus / repeat
atom <- char / char-class / "(" regex ")"

optional <- atom "?"
zero-plus <- atom "*"
one-plus <- atom "+"
repeat <- atom "{" quantity "}"

 char <- !{[]^.\?*+()} 1
 char-class <- class-esc ; etc: / class-expr / wildcard-esc

`quantity` <- quant-range / quant-min / quant-exact
quant-range <- quant-exact "," quant-exact
quant-min <- quant-exact ","
quant-exact <- [0-9]+


`class-esc` <- single-esc ; etc: / multi-esc / catEst / complEsc
 single-esc <- "\\" ({nrt\\|.?*+()[]^} / "{" / "}")
]]
