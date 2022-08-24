# SQL\(ite\) PEG


  A Parsing Expression Grammar for the SQLite dialect of Structured Query
Language\.


### SQLite start rule

  A collection of one or more SQL statements, separated by a semicolon\.  The
end of the file is considered a valid semicolon\.

```peg
          sql  ←  _ (statement _ semi _)+

`statement`  ←  explain? ( alter-table
                         / analyze
                         / attach
                         / begin
                         / commit
                         / create-index
                         / create-table
                         / create-trigger
                         / create-view
                         / create-virtual-table
                         / delete
                         / detach
                         / drop
                         / insert
                         / pragma
                         / reindex
                         / release
                         / rollback
                         / savepoint
                         / select
                         / update
                         / vacuum )
       `semi`  ←  ";" / -1

explain  ←  EXPLAIN (QUERY PLAN)?
```

These are listed in the same order as the SQLite diagram, which may not be the
optimal choice order for a PEG, but SQL statements as a whole are trivially
disjoint in these categories, and besides, we have to write them all \(at least
the first terminal\!\) before we can order them\.

As add ordering logic to the post\-constraint phase, but the pieces are in
place for that\.

The statement list starts with `A`, we can start where a database starts:
creating tables\.


### create\-table

I found dropping the `-state`, `-stmt`, `-statement` clarifying in the Lua
grammar, so we do likewise here\.

Espalier PEGs are emphatically case sensitive\.

Another [straightfoward translation](https://www.sqlite.org/syntax/create-table-stmt.html) from the docs\.

```peg
create-table  ←  CREATE (TEMP / TEMPORARY)? TABLE
                 (IF NOT EXISTS)? (schema-name _ "." _)? table-name _
                 ( AS select /
                    "(" _ column-def
                    (_ "," _ column-def)*
                    (_ "," (_ table-constraint)+)? _ ")" _
                    table-options* )

  schema-name  ←  name-val
   table-name  ←  name-val
table-options  ←  t-opt ("," _  t-opt)*
      `t-opt`  ←  (WITHOUT ROWID / STRICT)
```

### create\-index

```peg
create-index  ←  CREATE UNIQUE? INDEX (IF NOT EXISTS)? (schema-name _ "." _)?
                 index-name _ ON table-name _ indexed-columns (WHERE expr)?
  index-name  ←  name-val
```


#### column\_def

  [We continue](https://www.sqlite.org/syntax/column-constraint.html) with a
fun one, getting the affinities out at parse\-time can't hurt, yeah?

```peg
 column-def  ←  column-name _ (type-name)? (_ column-constraint)*
column-name  ←  name-val

`type-name`  ←  (affinity _) column-width?

; these have no actual semantic value in SQLite
column-width  ←  "("_ signed-number _")"_
              /  "("_ signed-number _","_ signed-number _")"_
```

With a not\-excessive amount of looking around, we type columns thus\.

```peg
    `affinity`  ←  blob-column
                /  integer-column
                /  text-column
                /  real-column
                /  numeric-column

   blob-column  ←  B L O B !follow-char

integer-column  ←  (no-affinity _)* integer-word (_ name-val)*
`integer-word`  ←  &((!int-affin !t 1)* int-affin) name-val

   text-column  ←  (no-affinity _)* text-word (_ name-val)*
   `text-word`  ←  &((!text-affin !t 1)* text-affin) id

   real-column  ←  (no-affinity _)* real-word (_ name-val)*
   `real-word`  ←  &((!text-affin !t 1)* text-affin) id

 `no-affinity`  ←  &((!affine !t 1)+) name

      `affine`  ←  int-affin / text-affin / real-affin

   `int-affin`  ←  I N T

  `text-affin`  ←  C H A R / C L O B / T E X T

  `real-affin`  ←  R E A L / F L O A / D O U B

numeric-column  ←  name-val (_ name-val)*
```


#### Column and Table Constraints

```peg
column-constraint  ←  CONSTRAINT name

                   /  NOT NULL  ; conflict-clause?
                   /  PRIMARY KEY (ASC / DESC)? conflict-clause? AUTOINCREMENT?
                   /  UNIQUE conflict-clause?
                   /  CHECK expr ;group-expr
                   /  DEFAULT (literal-value / group-expr / signed-number)
                   /  COLLATE collation-name
                   /  foreign-key-clause
                   /  (GENERATED ALWAYS)? AS group-expr (STORED / VIRTUAL)?



 table-constraint  ←  CONSTRAINT name _
                   /  FOREIGN KEY column-names foreign-key-clause
                   /  ( PRIMARY KEY
                      / UNIQUE ) indexed-columns conflict-clause?
                   /  CHECK group-expr

`conflict-clause`  ←  ON CONFLICT (ROLLBACK / ABORT / FAIL / IGNORE / REPLACE)

   `column-names`  ←  "(" _ column-name _ (","_ column-name _)* ")"_
`indexed-columns`  ←  "(" _ indexed-column (","_ indexed-column)* _ ")" _

   indexed-column  ←  (column-name / expr) _ (COLLATE name _)? (ASC / DESC)?

       group-expr  ←  "("_ expr _ ")"
```


#### Foreign Key Clause

```peg
foreign-key-clause  ←  REFERENCES table-name _ column-names?
                       fk-on-clause*
                       (NOT? DEFERRABLE (INITIALLY (DEFERRED / IMMEDIATE))?)?

    `fk-on-clause`  ←  (ON (DELETE / UPDATE)
                           ( SET (NULL / DEFAULT)
                           / CASCADE
                           / RESTRICT
                           / NO ACTION ))
                    /  MATCH name _
```


### Expressions

As with the Lua parser, and any other complex\-precedence parser, we concern
ourselves in the grammar with recognition\.  The correct tree shape is built
by the usual suspects\.


#### Angle of Attack

  The railroad diagram which is our [source of truth](https://www.sqlite.org/lang_expr.html) is heavily left\-
recursive, which we can't do\.  It should flow nicely once we separate out the
cursor\-advancing rules from the recursive case\.

It is almost inordinately complex and has no hope of being correct, outside of
the favored cases, without a test corpus\.

A brief and somewhat cross\-eyed perusal of the test directory of SQLite
suggests some hope of merely generating, rather than generating and excecuting,
some subset of the queries\.

Without the Stay Winning Engine, it's tough to do this without any
backtracking\.

The choices are to backtrack for a term or backtrack for a compound\.  I'm
using a `!binop` predicate to do the latter, because this completes without
backtracking, and the alternative always backtracks once, since every chain of
binary statements ends with an atom\.


```peg
           expr  ←  expr-term !binop
                 /  expr-term _ expr-rest

    `expr-term`  ←  unop _ expr
                 /  literal-value
                 /  bind-parameter
                 /  function-expr
                 /  raise-function
                 /  schema-name _"."_ table-name _"."_ column-name
                 /  table-name  _"."_ column-name
                 /  column-name
                 /  group-expr
                 /  CAST "("_ expr AS type-name _")"
                 /  NOT EXISTS "("_ select ")"
                 /  CASE (expr _)*
                        (WHEN expr _ THEN expr _)+
                        (ELSE expr _)?
                    END

        ; these rules are purely predicate
        `binop`  ←   _ ( binop-glyph
                       / COLLATE
                       / NOTNULL
                       / NOT
                       / AND
                       / OR
                       / ISNULL
                       / IS
                       / EXISTS
                       / LIKE
                       / GLOB
                       / REGEXP
                       / MATCH )
  `binop-glyph`  ←  "||" / "->>" / "->" / "<<" / ">>"
                 /  "<=" / "=>"  / "!=" / "<>" / "=="
                 /  {*/+-%<>=&|}

         `unop`  ←  uplus / uminus / bit-not


          uplus  ←  "+"
         uminus  ←  "-"
        bit-not  ←  "~"

    `expr-rest`  ←  operator _ expr
                 /  (AND / OR) expr
                 /  COLLATE name
                 /  like-op expr (_ ESCAPE exexpr)?
                 /  match-op expr
                 /  ISNULL
                 /  NOT NULL
                 /  NOTNULL
                 /  is-op expr
                 /  between-expr
                 /  in-select-expr

             like-op  ←   NOT? LIKE
            match-op  ←   NOT? (GLOB / REGEXP / MATCH)
               is-op  ←   IS NOT? (DISTINCT FROM)?
        between-expr  ←   NOT? BETWEEN expr AND expr
      ; in-select-expr

      `operator`  ←  concat / extract / neq / gte / lte / lshift / rshift
                  /  eq /  lt / gt / add / sub / mul / div / mod
                  /  bit-and / bit-or

                concat  ←  "||"
               extract  ←  "->>" / "->"
                   neq  ←  "<>" / "!="
                   gte  ←  ">="
                   lte  ←  "<="
                lshift  ←  "<<"
                rshift  ←  ">>"

                    eq  ←  "==" / "="
                    lt  ←  "<"
                    gt  ←  ">"
                   add  ←  "+"
                   sub  ←  "-"
                   mul  ←  "*"
                   div  ←  "/"
                   mod  ←  "%"
               bit-and  ←  "&"
                bit-or  ←  "|"



function-expr  ←  function-name "("_ ("*" / (DISTINCT? expr-list)) _")"_
                  filter-clause? over-clause?

function-name  ←  name-val
    expr-list  ←  expr (_","_ expr)*
```



### Tokens

  The specification is designed around a separate lexing pass, as is
nigh\-universal\.

It should be tractable to order the rules in this section such that a lexer is
the result, if that should prove useful for whatever reason\.


#### name

  The rules for what is actually a valid identifier are cunningle reverse\-
engineered here, with a bit of help from stack and the source code\.

Sources\[\{\*\}\]\[\{\*\*\}\]:

\{\*\}: https://stackoverflow\.com/questions/3373234/what\-sqlite\-column\-name\-can\-be\-cannot\-be

\{\*\*\}: https://sqlite\.org/src/file?name=src/tokenize\.c&ci=trunk

```peg
               name  ←  name-val quoted / id
         `name-val`  ←   quoted / id
           `quoted`  ←  '"' quote-name '"'
                     /  deprecated-quote
   deprecated-quote  ←  "[" quote-name "]"
                     /  "`" quote-name "`"
                     /  "'" quote-name "'"
               `id`  ←  !keyword bare-name
   allowed-keyword  ←  bare-name

  `bare-name`  ←  lead-char follow-char*
  `lead-char`  ←  [\x80-\xff] / [A-Z] / [a-z] / "_"
`follow-char`  ←  lead-char / [0-9]  / "$"
   quote-name  ←  (!'"' 1)+
```



### literals

```peg
`literal-value`  ←  (number / string / blob / NULL / TRUE / FALSE
                    / CURRENT_TIMESTAMP / CURRENT_TIME / CURRENT_DATE)
signed-number  ←  {+-} number

       number  ←  real / hex / integer

       real  ←  ((integer ("." fraction)) / ("." fraction))
                  (("e" / "E") "-"? exponent)?
        hex  ←  "0" {Xx} higit+ ("." higit*)?
    integer  ←  digit+

   fraction  ←  digit+
   exponent  ←  digit+

      `digit`  ←  [0-9]
      `higit`  ←  digit / [a-f] / [A-F]

       string  ←  "'" ((!"'" 1) / "''")* "'"
         blob  ←  {xX} "'" higit* "'"
```


### Whitespace

Adding a `dent` rule costs nothing and helps when it helps\.

```peg
  `_`  ←  ws*
 `ws`  ←  (comment / dent / WS)+

; tracking indentation can be useful
`dent`  ←  "\n" (!"\n" WS)*

; whitespace token rule, defined in hex as in the documentation
; why \f and not \v? don't know!
`WS`  ←  {\x09\x0a\x0c\x0d\x20} ; {\t\n\f\r }

`comment`  ←  line-comment / block-comment
`line-comment`  ←  "--" (!"\n" 1)*
`block-comment`  ←  "/*" (!"*/" 1)* ("*/" / -1)
```


### terminal rule

This lets us distinguish the keyword `create` from the identifier `creative`\.

```peg
`t`  ←  !follow-char
```
peg


### Keywords

We get to do a whole small song\-and\-dance to make case\-insensitive keywords\.

This is generated programmatically from a block at the bottom of the document\.

We include trailing whitespace in keywords since the meaning is printed on the
label, and it avoids dribbling `_` all over the grammar\.

```peg
               ABORT  ←  A B O R T t _
              ACTION  ←  A C T I O N t _
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
               FALSE  ←  F A L S E t _
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
                  NO  ←  N O t _
                NULL  ←  N U L L t _
              OFFSET  ←  O F F S E T t _
                  OF  ←  O F t _
                  ON  ←  O N t _
               ORDER  ←  O R D E R t _
                  OR  ←  O R t _
               OUTER  ←  O U T E R t _
                PLAN  ←  P L A N t _
              PRAGMA  ←  P R A G M A t _
             PRIMARY  ←  P R I M A R Y t _
               QUERY  ←  Q U E R Y t _
          REFERENCES  ←  R E F E R E N C E S t _
               RAISE  ←  R A I S E t _
              REGEXP  ←  R E G E X P t _
             REINDEX  ←  R E I N D E X t _
              RENAME  ←  R E N A M E t _
             REPLACE  ←  R E P L A C E t _
            RESTRICT  ←  R E S T R I C T t _
               RIGHT  ←  R I G H T t _
            ROLLBACK  ←  R O L L B A C K t _
               ROWID  ←  R O W I D t _
                 ROW  ←  R O W t _
              SELECT  ←  S E L E C T t _
                 SET  ←  S E T t _
              STORED  ←  S T O R E D t _
              STRICT  ←  S T R I C T t _
               TABLE  ←  T A B L E t _
           TEMPORARY  ←  T E M P O R A R Y t _
                TEMP  ←  T E M P t _
                THEN  ←  T H E N t _
                  TO  ←  T O t _
         TRANSACTION  ←  T R A N S A C T I O N t _
             TRIGGER  ←  T R I G G E R t _
                TRUE  ←  T R U E t _
               UNION  ←  U N I O N t _
              UNIQUE  ←  U N I Q U E t _
              UPDATE  ←  U P D A T E t _
               USING  ←  U S I N G t _
              VACUUM  ←  V A C U U M t _
              VALUES  ←  V A L U E S t _
                VIEW  ←  V I E W t _
             VIRTUAL  ←  V I R T U A L t _
                WHEN  ←  W H E N t _
               WHERE  ←  W H E R E t _
             WITHOUT  ←  W I T H O U T t _
```


#### Keyword Rule

With these powers combined, we have a keyword rule\.

There's a printer to make this a trie, but it breaks the parse and doesn't
get us much\.

```peg
 `keyword`  ←  (  ABORT / ACTION / ADD / AFTER / ALL / ALTER / ALWAYS
               /  ANALYZE / AND / ASC / AS / ATTACH / AUTOINCREMENT / BEFORE
               /  BEGIN / BETWEEN / BY / CASCADE / CASE / CAST / CHECK
               /  COLLATE / COLUMN / COMMIT / CONFLICT / CONSTRAINT / CREATE
               /  CROSS / CURRENT_DATE / CURRENT_TIMESTAMP / CURRENT_TIME
               /  DATABASE / DEFAULT / DEFERRABLE / DEFERRED / DELETE / DESC
               /  DETACH / DISTINCT / DROP / EACH / ELSE / END / ESCAPE
               /  EXCEPT / EXCLUSIVE / EXISTS / EXPLAIN / FAIL / FALSE
               /  FOREIGN / FOR / FROM / FULL / GENERATED / GLOB / GROUP
               /  HAVING / IF / IGNORE / IMMEDIATE / INDEX / INITIALLY
               /  INNER / INSERT / INSTEAD / INTERSECT / INTO / IN / ISNULL
               /  IS / JOIN / KEY / LEFT / LIKE / LIMIT / MATCH / NATURAL
               /  NOTNULL / NOT / NO / NULL / OFFSET / OF / ON / ORDER / OR
               /  OUTER / PLAN / PRAGMA / PRIMARY / QUERY / REFERENCES
               /  RAISE / REGEXP / REINDEX / RENAME / REPLACE / RESTRICT
               /  RIGHT / ROLLBACK / ROWID / ROW / SELECT / SET / STORED
               /  STRICT / TABLE / TEMPORARY / TEMP / THEN / TO / TRANSACTION
               /  TRIGGER / TRUE / UNION / UNIQUE / UPDATE / USING / VACUUM
               /  VALUES / VIEW / VIRTUAL / WHEN / WHERE / WITHOUT )
```


#### Case Insensitive Letters

SQL bEiNg WhAt It iS, we need a rule `A` etc which matches both ASCII forms\.

The result: Every uppercase letter is a rule matching either the upper\- or
lower\-case form\.

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


## Cat & Hand off to Vav

  I'm writing this one in chunks for legibility, and on the off chance that
some subset of the blocks might be useful to test before Vav gets
sophisticated enough that it doesn't matter\.

```lua
local column_affinity = column_affinity or ""

local sqlite_blocks = {
   sql_statement,
   create_table,
   column_def,
   column_table_constraints,
   column_affinity,
   foreign_key_clause,
   create_index,
   expression,
   -- the 'lexer' rules
   literal_rules,
   name_rules,
   keyword_rules,
   keyword_rule,
   caseless_letters,
   whitespace_rules,
   terminal_rule,
}
```

But before we return this, there's a chunk of code for making all those
keywords up top\.


#### Codegen Block For Keywords

The letter rules were easy to write with multiple cursors, the keywords are
generated programmatically\.

We even sort them so that "ROWID" will match before "ROW"\.

In our algorithm, hitting CURRENT\_TIME will produce a brief cache miss, as the
terminal rule `t` is checked and fails, which immediately raises the
production CURRENT\_TIMESTAMP

To make the keywords, we need to turn e\.g\. `AND` into `AND  ←  A N D t`, which
we do like so\. We can reuse them, as is,

The \#noKnit tag is the poor man's ifdef\!

```lua
local core, cluster = use("qor:core", "cluster:cluster")
local table, string = core.table, core.string

-- first thing we do is sort these and print that

local kwset = {"ABORT","ACTION","ADD","AFTER","ALL","ALTER","ALWAYS",
   "ANALYZE","AND","ASC","AS","ATTACH","BEFORE","AUTOINCREMENT","BEGIN",
   "BETWEEN","BY","CASCADE","CASE","CAST","COLLATE","CHECK","COLUMN","COMMIT",
   "CONFLICT","CONSTRAINT","CREATE","CROSS","CURRENT_DATE",
   "CURRENT_TIMESTAMP","CURRENT_TIME","DATABASE","DEFAULT","DEFERRABLE",
   "DEFERRED","DELETE","DESC","DETACH","DISTINCT","DROP","EACH","ELSE","END",
   "EXCEPT","ESCAPE","EXCLUSIVE","EXISTS","EXPLAIN","FAIL","FALSE","FOREIGN",
   "FOR","FROM","FULL","GENERATED","GLOB","GROUP","HAVING","IF","IGNORE",
   "IMMEDIATE","INDEX","INITIALLY","INSERT","INNER","INSTEAD","INTERSECT",
   "INTO","IN","ISNULL","IS","JOIN","KEY","LEFT","LIKE","LIMIT","MATCH",
   "NATURAL","NOTNULL","NOT","NO","NULL","OFFSET","ON","OF","ORDER","OR",
   "OUTER","PLAN","QUERY","PRAGMA","PRIMARY","RAISE","REFERENCES","REGEXP",
   "REINDEX","RENAME","REPLACE","RESTRICT","RIGHT","ROLLBACK","ROWID","ROW",
   "SELECT","SET","STORED","TABLE","STRICT","TEMPORARY","TEMP","THEN","TO",
   "TRIGGER","TRANSACTION","TRUE","UNION","UNIQUE","UPDATE","USING","VACUUM",
   "VALUES","VIEW","VIRTUAL","WHEN","WHERE","WITHOUT",}

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

local function stretch(keyword)
   local stretched = {}
   for i = 1, #keyword do
      local chomp = char(byte(keyword,i))
      if chomp == "_" then
         -- wrap this one as a literal
         insert(stretched, '"_"')
      else
         insert(stretched, chomp)
      end
      insert(stretched, " ")
   end
   return concat(stretched)
end

for i, keyword in ipairs(kwset) do
   local pad = (" "):rep(longest - #keyword + 3)
   local rule = {pad, keyword, "  ←  "}
   insert(rule, stretch(keyword))
   insert(rule, "t _")
   poggers[i] = concat(rule)
end

-- now the keyword rule
-- we're going to build the optimal search structure: a trie.
local push, pop = table.insert, table.remove

local function makeTrie(kw_set)
   local trie, suffix = {}, {}
   for i, keyword in ipairs(kw_set) do
      if keyword ~= "" then
         local head, tail= sub(keyword, 1, 1), sub(keyword, 2)
         if tail ~= "" then
            suffix[head] = suffix[head] or {}
            push(suffix[head], tail)
         end
      end
   end
   for head, tails in pairs(suffix) do
      assert(type(tails) ==  'table', tostring(tails))
      if #tails > 1 then
         trie[head] = makeTrie(tails)
      elseif #tails == 1 then
         trie[head] = tails[1]
      end
   end
   return trie
end

local trie = makeTrie(kwset)

--print(require "repr:repr" .ts_color(trie))

-- this done, we must print the beast aesthetically.
-- otherwise what is to be gained?

-- but first we must print it /correctly/

local head     =   " `keyword`  ←  ( "
local WID = 78

local wide = #head - 2

local treezus = {head}

local tab_stop = {#head - 5}

local nkeys = table.nkeys

local function newLine()
   push(treezus, "\n")
   local stops = tab_stop[#tab_stop]
   push(treezus, (" "):rep(stops))
   wide = stops
end

local function addTok(...)
    for i = 1, select('#', ...) do
       local token = select(i, ...)
       local len = wide + #token
       if len >= WID then
          push(treezus, pad)
          push(treezus, token)
          wide = #pad + #token - 1
       else
          push(treezus, token)
          wide = len
       end
    end
 end

local sortedpairs = assert(table.sortedpairs)

local function rulify(trie, outer)
   local slash = false
   for letter, tail in sortedpairs(trie) do
      if letter == "_" then
         letter = '"_"'
      end
      if slash then
         newLine()
         addTok("/ ")
      else
         slash = true
      end
      if type(tail) == 'string' then
         addTok(letter, " ", stretch(tail))
      else
         addTok(letter, " ")
         local split = nkeys(tail) > 1
         if split then
            addTok(" ( ")
            push(tab_stop, wide - 2)
         end
         rulify(tail)
         if split then
            addTok(") ")
            pop(tab_stop)
         end
      end
   end
end

rulify(trie, true)
insert(treezus, ") t _ ")

print(concat(treezus))


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

-- now the keyword rule, old school

local head     =   " `keyword`  ←  (  "
local div_pad  = "\n               /  "
local div = " / "
local WID = 77

local wide = #head

local champ = {head}
local footer = " )\n"

local no_div = true
for i, kw in ipairs(kwset) do
   local div = div
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




-- print the rules
-- print(concat(poggers, "\n"))
print(concat(champ))
--print(concat(kw_pr))
```


#### Off we go

```lua
return {table.concat(sqlite_blocks, "\n\n"), blocks = sqlite_blocks}
```

