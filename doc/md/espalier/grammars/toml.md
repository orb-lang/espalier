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
         key  <-  dotted-key / simple-key
  simple-key  <-  quoted-key / unquoted-key
unquoted-key  <-  ([A-Z] / [a-z] / [0-9] / "-" / "_")+
  quoted-key  <-  basic-string / literal-string
  dotted-key  <-  simple-key ("." simple-key)+

```
