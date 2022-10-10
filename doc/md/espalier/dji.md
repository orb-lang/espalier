# Dji combinator


Dji takes Vav and Qoph, returning Dji, or yod\.

Vav is the grammar in the broad sense, Qoph is the engine the grammar is
applied to, `Dji(Vav, Yod)` is the resulting software system\.

In idiomatic Lua, we have no need to write this as a combinator, any more
than we express PEGs as combinators\.

The Dji module is probably a constructor, called as a method from Vav\.

A Mem is normally particular to a given Peh, or grammar, while Qoph is
frequently generic, although this genericity can't be complete, in that the
Qoph is responsible for the actions taken on recognition, where the canonical
example is to call a builder from Mem\.

We will concentrate on the specific Qoph which produces our new ASTs for the
time being\.

Mem itself is finally taking shape, literally, as being a clade in cluster\.

As I write this, I don't have another application in mind for clades\.  It's
interesting nonetheless that the relationships embodied in clades are
expressed in purely structural terms\.  There's no semantic leak from the idea
of an AST to the form and structure of clades\.


