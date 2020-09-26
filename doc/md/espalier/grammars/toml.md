# TOML

  [Tom's Obvious, Minimal Language](https://github.com/toml-lang/toml)\.

A simple configuration language with a clean mapping to Lua semantics\.

The leading candidate for manifest files, which we will use in Orb to specify
metadata about a given project\.

It may be that these will eventually be in Orb format, which is surely rich
enough to do the job\.  But it is better, I think, to have a simpler,
well\-understood format, because any Orb format would be a subset of Orb, and
therefore more of a challenge to write correctly\.

This is a fairly direct translation from the [abnf](https://github.com/toml-lang/toml/blob/master/toml.abnf)\.

```peg

;; Overall Structure

   toml    <-  expression (nl expression)*

expression <-  ws comment?
            /  ws keyval ws comment?
            /  ws table  ws comment?

;; Whitespace

        `ws`  <- {\t }*

;; Newline

        `nl`  <- "\n" / "\r\n"

;; Comment

     comment  <- "#" (!nl 1)*

;; Key-Value pairs

      keyval  <-  key ws "=" ws val
               /  key ws "=" ws Error
         key  <-  dotted-key / simple-key
  simple-key  <-  quoted-key / unquoted-key
unquoted-key  <-  ([A-Z] / [a-z] / [0-9] / "-" / "_")+
  quoted-key  <-  basic-string / literal-string
  dotted-key  <-  simple-key ("." simple-key)+
         val  <-  string / boolean / array / inline-table
                  / date-time / float / integer

;; String

      string  <-    ml-basic-string   / basic-string
                  / ml-literal-string / literal-string

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

integer  <-  decimal / hexadecimal / octal / binary

decimal  <-  sign? dec-int

sign     <-  "+" / "-"

dec-int  <-  [0-9] / [1-9] ([0-9] / "_" [0-9])+

hexadecimal  <-  "0x" hex-dig (hex-dig / "_" hex-dig)*

`hex-dig`    <- [A-F] / [a-f] / [0-9]

octal        <- "0o" [0-7] ([0-7] / "_" [0-7])*

binary       <- "0b" [0-1] ([0-1] / "_" [0-1])*

;; Error

Error  <-  1*
```
