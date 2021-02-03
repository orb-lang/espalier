























local Peg = require "espalier:espalier/peg"


local toml_str = [=[

;; Overall Structure

   toml    <-  expression (nl expression)*

`expression` <-  ws keyval ws comment?
             /  ws table  ws comment?
             /  ws comment
             /  ws &nl

;; Whitespace

        `ws`  <-  {\t }*
    `wschar`  <-  {\t }+

;; Newline

        `nl`  <- "\n" / "\r\n"

;; Comment

     comment  <- "#" (!nl 1)*

;; Key-Value pairs

      keyval  <-  key ws "=" ws val
               /  key ws "=" ws Error

         key  <-  dotted-key / simple-key ; / (!"=" 1) &"=" Error

`simple-key`  <-  quoted-key / unquoted-key

unquoted-key  <-  ([A-Z] / [a-z] / [0-9] / "-" / "_")+

  quoted-key  <-  basic-string / literal-string

  dotted-key  <-  simple-key ("." simple-key)+

         val  <-  string / boolean / array / inline-table
                  / date-time / float / integer

;; String

        `string`  <-  ml-basic-string   / basic-string
                  /   ml-literal-string / literal-string

;; Note: this isn't technically TOML, because we'll use Lua string
;; conventions. I have no interest in implementing \u.

    basic-string  <-  '"' ('\\' '"' / (!'"' !"\n" 1))* '"'
                  /   '"' ('\\' '"' / (!'"' !"\n" 1))* &"\n" Error

 ml-basic-string  <- '"""' ('\\' '"' / (!'"""' 1) / &'""""' '"')* '"""'
                  /  '"""' ('\\' '"' / (!'"""' !-2 1))* Error

  literal-string  <-  "'"  (!"'" !"\n" 1)* "'"
                  /   "'"  (!"'" !"\n" 1)* &"\n" Error

ml-literal-string <- "'''" (!"'''" 1 / &"''''" "'")* "'''"
                  /  "'''" (!"'''" !-2 1)* Error

;; Integer

    integer  <-  hexadecimal / octal / binary / decimal

    decimal  <-  sign? dec-int

       sign  <-  "+" / "-"

  `dec-int`  <-  [0-9] / [1-9] ([0-9] / "_" [0-9])+

hexadecimal  <-  "0x" higit (higit / "_" higit)*

    `higit`  <- [A-F] / [a-f] / [0-9]

      octal  <- "0o" [0-7] ([0-7] / "_" [0-7])*

     binary  <- "0b" [0-1] ([0-1] / "_" [0-1])*

;; Float

float <- decimal "." decimal* (("e" / "E") "-"? decimal)?
      /  special-float

special-float = sign? ("inf" / "nan")

;; Boolean

boolean = "true" / "false"

;;; Not in the mood to port dates from 'ortho8600'
;; Date and Time (as defined in RFC 3339)

date-time <- "placeholder@#$%@$#%"

;; Offset Date-Time

offset-date-time <- "placeholder@#$%@$#%"

;; Local Date-Time

local-date-time <- "placeholder@#$%@$#%"

;; Local Date

local-date <- "placeholder@#$%@$#%"

;; Local Time

local-time <- "placeholder@#$%@$#%"

;; Array

        array  <-  "[" array-values? opt-comment "]"

`opt-comment`  <-  (ws comment? nl ws)+ / ws

 array-values  <-  opt-comment val (opt-comment "," opt-comment val)* ","*

;; Table

table  <-  std-table / array-table

;; Standard Table

std-table  <-  "[" ws key ws "]"

;; Inline Table

inline-table <-  "{" ws (keyval (ws "," ws keyval)*)* ws "}"

;; Array Table

array-table <- "[[" ws key ws "]]"

;; Error

Error  <-  1*
]=]


return Peg(toml_str)

