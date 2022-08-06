# SQL\(ite\) PEG


We start [here](https://www.sqlite.org/draft/tokenreq.html)\.

This is the first time I've written the lexer first in a PEG\.  I'm suspecting
that I'll like it\.

oh hey https://github\.com/AlecStrong/sqlite\-bnf/blob/grammar\-kit/sqlite\.bnf


## Case Insensitive Letters

SQL bEiNg WhAt It iS, we need a rule `A` etc which matches both ASCII forms\.

No one would call this pretty, but it is correct and legible\.

```peg
`A`  ←  {Aa}
`B`  ←  {Bb}
`C`  ←  {Cc}
`D`  ←  {Dd}
`E`  ←  {Ee}
`F`  ←  {Ff}
`G`  ←  {Gg}
`H`  ←  {Hh}
`I`  ←  {Ii}
`J`  ←  {Ji}
`K`  ←  {Kk}
`L`  ←  {Ll}
`M`  ←  {Mm}
`N`  ←  {Nn}
`O`  ←  {Oo}
`P`  ←  {Pp}
`Q`  ←  {Qq}
`R`  ←  {Rr}
`S`  ←  {Ss}
`T`  ←  {Tt}
`U`  ←  {Uu}
`V`  ←  {Vv}
`W`  ←  {Ww}
`X`  ←  {Xx}
`Y`  ←  {Yy}
`Z`  ←  {Zz}
```


## Token Categories

Incomplete but serviceable\.


### Whitespace

Adding a `dent` rule costs nothing and helps when it helps\.

```peg
; we do the usual optional and not-optional
`_`  ←  ws*
`ws`  ←  (comment / dent / WS)+

; tracking indentation can be useful
`dent`  ←  "\n" (!"\n" WS)*

; we want a one-byte whitespace-only
; why \f and not \v? don't know!
`WS`  ←  {\x09\x0a\x0c\x0d\x20} ; {\t\n\f\r }

`comment`  ←  line-comment / block-comment
`line-comment`  ←  "--" (!"\n" 1)*
`block-comment`  ←  "/*" (!"*/" 1)* ("*/" / -1)
```


### terminal class

The class of bytes which terminates a keyword, allowing `not` to be
distinguished from `note`\.

```peg
`t`  ←  &(glyph / WS)
```


### Keywords

We'll give them all Capital letters\.

But I'm not going to generate this by hand\. That would be tedious\.

We need all the keywords, which I can mechanically munge out of the draft spec
like so\.


#### But first, a bit of codegen\.

The letter rules were easy to write with multiple cursors, the keywords we
will generate programmatically\.

We even sort them so that "ROWID" will match before "ROW"\.

In our algorithm, hitting CURRENT\_TIME will produce a brief cache miss, as the
terminal rule `t` is checked and fails, which immediately raises the
production CURRENT\_TIMESTAMP

To make the keywords, we need to turn e\.g\. `AND` into `AND  ←  A N D t`, which
we do like so\. We can reuse them, as is,

The \#noKnit tag is the poor man's ifdef\!

```lua
-- first thing we do is sort these and print that

local kwset = {"ABORT","ADD","AFTER","ALL","ALTER","ALWAYS","ANALYZE","AND",
   "ASC","AS","ATTACH","AUTOINCREMENT","BEFORE","BEGIN","BETWEEN","BY",
   "CASCADE","CASE","CAST","CHECK","COLLATE","COLUMN","COMMIT","CONFLICT",
   "CONSTRAINT","CREATE","CROSS","CURRENT_DATE","CURRENT_TIMESTAMP",
   "CURRENT_TIME","DATABASE","DEFAULT","DEFERRABLE","DEFERRED","DELETE",
   "DESC","DETACH","DISTINCT","DROP","EACH","ELSE","END","ESCAPE","EXCEPT",
   "EXCLUSIVE","EXISTS","EXPLAIN","FAIL","FOREIGN","FOR","FROM","FULL",
   "GENERATED","GLOB","GROUP","HAVING","IF","IGNORE","IMMEDIATE","INDEX",
   "INITIALLY","INNER","INSERT","INSTEAD","INTERSECT","INTO","IN","ISNULL",
   "IS","JOIN","KEY","LEFT","LIKE","LIMIT","MATCH","NATURAL","NOTNULL","NOT",
   "NULL","OF","OFFSET","ON","ORDER","OR","OUTER","PLAN","PRAGMA","PRIMARY",
   "QUERY","RAISE","REFERENCES","REGEXP","REINDEX","RENAME","RIGHT","REPLACE",
   "RESTRICT","ROLLBACK","ROWID","ROW","SET","SELECT","STORED","STRICT",
   "TABLE","TEMPORARY","TEMP","THEN","TO","TRANSACTION","TRIGGER","UNION",
   "UNIQUE","UPDATE","USING","VACUUM","VALUES","VIEW","VIRTUAL","WHEN",
   "WITHOUT","WHERE",}

-- sort function being:
local char, byte, sub = assert(string.char),
                        assert(string.byte),
                        assert(string.sub)

local function pegsort(left, right)
   local a, b = byte(left, 1), byte(right, 1)
   if a < b then return true
   elseif a > b then return false
   else
      local longer, shorter;
      if #left > #right then
         longer, shorter = left, right
      else
         longer, shorter = right, left
      end
      local sublong = sub(longer, 1, #shorter)
      if sublong == shorter then
         return longer == left
      else
         return left < right
      end
   end
end

table.sort(kwset, pegsort)


-- I insist on justifying the arrows, so we make padding:
local longest = 0
for _, kw in ipairs(kwset) do
   longest = #kw > longest and #kw or longest
end

-- make the rules
local insert, concat = assert(table.insert), assert(table.concat)

local poggers = {}

for i, keyword in ipairs(kwset) do
   local pad = (" "):rep(longest - #keyword + 3)
   local rule = {pad, keyword, "  ←  "}
   for i = 1, #keyword do
      local chomp = char(byte(keyword,i))
      if chomp == "_" then
         -- wrap this one as a literal
         insert(rule, '"_"')
      else
         insert(rule, chomp)
      end
      insert(rule, " ")
   end
   insert(rule, "t _")
   poggers[i] = concat(rule)
end

-- now the keyword rule

local head     =   " keyword  ←  (  "
local div_pad  = "\n             /  "
local div = " / "
local WID = 78

local wide = #head

local champ = {head}
local footer = " ) _ t\n"

local no_div = true
for i, kw in ipairs(kwset) do
   local next_w = #kw + #div + wide + ((i == #kwset) and #footer - 1 or 0)
   if next_w <= WID then
      if no_div then
         no_div = false
      else
        insert(champ, div)
        wide = wide + #div
      end
   else
      insert(champ, div_pad)
      wide = #div_pad - 1 -- because the newline isn't width
   end
   insert(champ, kw)
   wide = wide + #kw
end

insert(champ, footer)


-- last but not least! let's pretty print kwargs:

local kw_pr = {"local kwset = {"}
local wide = #kw_pr[1]
for i, kw in ipairs(kwset) do
    local tok = '"' .. kw .. '",'
    local next_w = wide + #tok
    if next_w <= WID then
      insert(kw_pr, tok)
      wide = next_w
   else
      insert(kw_pr, "\n   ")
      insert(kw_pr, tok)
      wide = #tok + 3
   end
end
insert(kw_pr, "}\n\n")


-- print the rules
print(concat(poggers, "\n"))
print(concat(champ))
print(concat(kw_pr))
```

Which we can run anytime we want, to generate the following:

```peg
               ABORT  ←  A B O R T t _
                 ADD  ←  A D D t _
               AFTER  ←  A F T E R t _
                 ALL  ←  A L L t _
               ALTER  ←  A L T E R t _
              ALWAYS  ←  A L W A Y S t _
             ANALYZE  ←  A N A L Y Z E t _
                 AND  ←  A N D t _
                 ASC  ←  A S C t _
                  AS  ←  A S t _
              ATTACH  ←  A T T A C H t _
       AUTOINCREMENT  ←  A U T O I N C R E M E N T t _
              BEFORE  ←  B E F O R E t _
               BEGIN  ←  B E G I N t _
             BETWEEN  ←  B E T W E E N t _
                  BY  ←  B Y t _
             CASCADE  ←  C A S C A D E t _
                CASE  ←  C A S E t _
                CAST  ←  C A S T t _
               CHECK  ←  C H E C K t _
             COLLATE  ←  C O L L A T E t _
              COLUMN  ←  C O L U M N t _
              COMMIT  ←  C O M M I T t _
            CONFLICT  ←  C O N F L I C T t _
          CONSTRAINT  ←  C O N S T R A I N T t _
              CREATE  ←  C R E A T E t _
               CROSS  ←  C R O S S t _
        CURRENT_DATE  ←  C U R R E N T "_" D A T E t _
   CURRENT_TIMESTAMP  ←  C U R R E N T "_" T I M E S T A M P t _
        CURRENT_TIME  ←  C U R R E N T "_" T I M E t _
            DATABASE  ←  D A T A B A S E t _
             DEFAULT  ←  D E F A U L T t _
          DEFERRABLE  ←  D E F E R R A B L E t _
            DEFERRED  ←  D E F E R R E D t _
              DELETE  ←  D E L E T E t _
                DESC  ←  D E S C t _
              DETACH  ←  D E T A C H t _
            DISTINCT  ←  D I S T I N C T t _
                DROP  ←  D R O P t _
                EACH  ←  E A C H t _
                ELSE  ←  E L S E t _
                 END  ←  E N D t _
              ESCAPE  ←  E S C A P E t _
              EXCEPT  ←  E X C E P T t _
           EXCLUSIVE  ←  E X C L U S I V E t _
              EXISTS  ←  E X I S T S t _
             EXPLAIN  ←  E X P L A I N t _
                FAIL  ←  F A I L t _
             FOREIGN  ←  F O R E I G N t _
                 FOR  ←  F O R t _
                FROM  ←  F R O M t _
                FULL  ←  F U L L t _
           GENERATED  ←  G E N E R A T E D t _
                GLOB  ←  G L O B t _
               GROUP  ←  G R O U P t _
              HAVING  ←  H A V I N G t _
                  IF  ←  I F t _
              IGNORE  ←  I G N O R E t _
           IMMEDIATE  ←  I M M E D I A T E t _
               INDEX  ←  I N D E X t _
           INITIALLY  ←  I N I T I A L L Y t _
               INNER  ←  I N N E R t _
              INSERT  ←  I N S E R T t _
             INSTEAD  ←  I N S T E A D t _
           INTERSECT  ←  I N T E R S E C T t _
                INTO  ←  I N T O t _
                  IN  ←  I N t _
              ISNULL  ←  I S N U L L t _
                  IS  ←  I S t _
                JOIN  ←  J O I N t _
                 KEY  ←  K E Y t _
                LEFT  ←  L E F T t _
                LIKE  ←  L I K E t _
               LIMIT  ←  L I M I T t _
               MATCH  ←  M A T C H t _
             NATURAL  ←  N A T U R A L t _
             NOTNULL  ←  N O T N U L L t _
                 NOT  ←  N O T t _
                NULL  ←  N U L L t _
                  OF  ←  O F t _
              OFFSET  ←  O F F S E T t _
                  ON  ←  O N t _
               ORDER  ←  O R D E R t _
                  OR  ←  O R t _
               OUTER  ←  O U T E R t _
                PLAN  ←  P L A N t _
              PRAGMA  ←  P R A G M A t _
             PRIMARY  ←  P R I M A R Y t _
               QUERY  ←  Q U E R Y t _
               RAISE  ←  R A I S E t _
          REFERENCES  ←  R E F E R E N C E S t _
              REGEXP  ←  R E G E X P t _
             REINDEX  ←  R E I N D E X t _
              RENAME  ←  R E N A M E t _
               RIGHT  ←  R I G H T t _
             REPLACE  ←  R E P L A C E t _
            RESTRICT  ←  R E S T R I C T t _
            ROLLBACK  ←  R O L L B A C K t _
               ROWID  ←  R O W I D t _
                 ROW  ←  R O W t _
                 SET  ←  S E T t _
              SELECT  ←  S E L E C T t _
              STORED  ←  S T O R E D t _
              STRICT  ←  S T R I C T t _
               TABLE  ←  T A B L E t _
           TEMPORARY  ←  T E M P O R A R Y t _
                TEMP  ←  T E M P t _
                THEN  ←  T H E N t _
                  TO  ←  T O t _
         TRANSACTION  ←  T R A N S A C T I O N t _
             TRIGGER  ←  T R I G G E R t _
               UNION  ←  U N I O N t _
              UNIQUE  ←  U N I Q U E t _
              UPDATE  ←  U P D A T E t _
               USING  ←  U S I N G t _
              VACUUM  ←  V A C U U M t _
              VALUES  ←  V A L U E S t _
                VIEW  ←  V I E W t _
             VIRTUAL  ←  V I R T U A L t _
                WHEN  ←  W H E N t _
             WITHOUT  ←  W I T H O U T t _
               WHERE  ←  W H E R E t _
```

With these powers combined:

```peg
 keyword  ←  (  ABORT / ADD / AFTER / ALL / ALTER / ALWAYS / ANALYZE / AND
             /  ASC / AS / ATTACH / AUTOINCREMENT / BEFORE / BEGIN / BETWEEN
             /  BY / CASCADE / CASE / CAST / CHECK / COLLATE / COLUMN / COMMIT
             /  CONFLICT / CONSTRAINT / CREATE / CROSS / CURRENT_DATE
             /  CURRENT_TIMESTAMP / CURRENT_TIME / DATABASE / DEFAULT
             /  DEFERRABLE / DEFERRED / DELETE / DESC / DETACH / DISTINCT
             /  DROP / EACH / ELSE / END / ESCAPE / EXCEPT / EXCLUSIVE
             /  EXISTS / EXPLAIN / FAIL / FOREIGN / FOR / FROM / FULL
             /  GENERATED / GLOB / GROUP / HAVING / IF / IGNORE / IMMEDIATE
             /  INDEX / INITIALLY / INNER / INSERT / INSTEAD / INTERSECT
             /  INTO / IN / ISNULL / IS / JOIN / KEY / LEFT / LIKE / LIMIT
             /  MATCH / NATURAL / NOTNULL / NOT / NULL / OF / OFFSET / ON
             /  ORDER / OR / OUTER / PLAN / PRAGMA / PRIMARY / QUERY / RAISE
             /  REFERENCES / REGEXP / REINDEX / RENAME / RIGHT / REPLACE
             /  RESTRICT / ROLLBACK / ROWID / ROW / SET / SELECT / STORED
             /  STRICT / TABLE / TEMPORARY / TEMP / THEN / TO / TRANSACTION
             /  TRIGGER / UNION / UNIQUE / UPDATE / USING / VACUUM / VALUES
             /  VIEW / VIRTUAL / WHEN / WITHOUT / WHERE ) _ t
```

Which lets us refer to these without trailing whitespace\. The keyword token
carries around that whitespace but the span is the `.id` so we will never care
about that\.

Now, Orb is supposed to do this sort of routine codegen task for us, without
the print statement\.

Squad goals\.


### create\-table

I found dropping the `-state`, `-stmt`, `-statement` clarifying in the Lua
grammar, so we do likewise here\.

Espalier PEGs are emphatically case sensitive\.

Another [straightfoward translation](https://www.sqlite.org/syntax/create-table-stmt.html) from the docs\.

```peg
create-table  ←  CREATE (TEMP / TEMPORARY)? TABLE
                (IF NOT EXISTS)? (schema-name _ "." _)? table-name _
                ; add AS select... later!
                "(" _ column-def _ ("," _ column-def _)* _
                table-options*

schema-name  ←  identifier
table-name  ←  identifier
```

Because our definition of keywords ends in `t`, we can follow the spec for
keyword order\.  Though I'll confess, I write so many PEGs that looking at it
makes me nervous\!

Maybe lexers are Good, Actually?


#### column\_def

[We continue](https://www.sqlite.org/syntax/column-constraint.html)

```peg
column-def  ←  column-name _ (type-name _)? (column-constraint _)*

type-name <- (affinity _)+ fluff?

affinity <- name ; we can capture the same affinities SQLite uses here

; it's not fluff obviously but wtf even is this? it's a compatibility thing
`fluff` <- "("_ signed-number _")"_
        / "("_ signed-number _","_ signed-number _")"_


column-constraint  ←  CONSTRAINT name _
                   /  PRIMARY KEY (ASC / DESC)? conflict-clause AUTOINCREMENT?
                   /  NOT NULL conflict-clause
                   /  UNIQUE conflict-clause
                   /  CHECK group-expr
                   /  DEFAULT (group-expr / literal-value _ / signed-number _)
                   /  COLLATE
                   /  foreign-key-clause
                   /  (GENERATED ALWAYS)? AS group-expr (STORED / VIRTUAL)?

group-expr <- "(" _ expr _ ")" _ ; probably mute this one
```


#### table\_options

```peg
table-options <- (WITHOUT ROWID / STRICT) _","_
```


### SQLite start rule

We're handing this off to Vav but it does need to have a leading start rule,
so let's sketch that real quick:

```peg
sql <- (sql-statement _";"_)+

; this is a long one which we fill in systematically
sql-statement <- explain? ( create-table
                          / alter-table )
explain <- EXPLAIN (QUERY PLAN)?
```


## OK now what

Now to hand it to vav\!

I'm exporting this as an array, like so\.

```lua
local sqlite_blocks = {
   sql_statement,
   caseless_letters,
   whitespace_rules,
   terminal_rule,
   keyword_rules,
   create_table,
   column_def,
   table_options,
}
```

```lua
return {table.concat(sqlite_blocks, "\n\n"), blocks = sqlite_blocks}
```

