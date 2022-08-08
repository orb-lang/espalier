











local sql_statement = [[
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
]]















local create_table = [[
create-table  ←  CREATE (TEMP / TEMPORARY)? TABLE
                 (IF NOT EXISTS)? (schema-name _ "." _)? table-name _
                 ( AS select /
                    "(" _ column-def
                    ("," _ column-def)*
                    ("," _ column-constraint+ )* ")" _
                    table-options* )

  schema-name  ←  name
   table-name  ←  name
table-options  ←  t-opt ("," _  t-opt)*
      `t-opt`  ←  (WITHOUT ROWID / STRICT)
]]







local column_def = [[
 column-def  ←  column-name _ (type-name)? (column-constraint _)*
column-name  ←  name

  type-name  ←  (affinity _) fluff?

    `affinity`  ←  blob-column
                /  integer-column
                /  text-column
                /  real-column
                /  numeric-column

   blob-column  ←  B L O B !follow-char

integer-column  ←  (!integer-word id _)* integer-word (_ id)*
`integer-word`  ←  (!int-affin lead-char)?
                   (!int-affin follow-char)*
                   int-affin follow-char*
   `int-affin`  ←  I N T

   text-column  ←  (!text-word id _)* text-word (_ id)*
   `text-word`  ←  (!text-affin lead-char)?
                   (!text-affin follow-char)*
                   text-affin follow-char*
  `text-affin`  ←  C H A R / C L O B / T E X T

   real-column  ←  (!real-word id _)* real-word (_ id)*
   `real-word`  ←  (!real-affin lead-char)?
                   (!real-affin follow-char)*
                   real-affin follow-char*
  `real-affin`  ←  R E A L / F L O A / D O U B

numeric-column  ←  name

; these have no actual semantic value in SQLite
`fluff`  ←  "("_ signed-number _")"_
         /  "("_ signed-number _","_ signed-number _")"_
]]




local column_table_constraints = [[
column-constraint  ←  CONSTRAINT name _
                   /  PRIMARY KEY (ASC / DESC)? conflict-clause AUTOINCREMENT?
                   /  NOT NULL conflict-clause
                   /  UNIQUE conflict-clause
                   /  CHECK group-expr
                   /  DEFAULT (group-expr / literal-value _ / signed-number _)
                   /  COLLATE collation-name
                   /  foreign-key-clause
                   /  (GENERATED ALWAYS)? AS group-expr (STORED / VIRTUAL)?

 table-constraint  ←  CONSTRAINT name _
                   /  ( PRIMARY KEY
                      / UNIQUE ) "("_ indexed-columns ")"_ conflict-clause
                   /  CHECK group-expr
                   /  FOREIGN KEY "("_ column-names ")"_ foreign-key-clause

`conflict-clause`  ←  ON CONFLICT (ROLLBACK / ABORT / FAIL / IGNORE / REPLACE)

   `column-names`  ←  column-name _ (","_ column-name _)*
`indexed-columns`  ←  indexed-column (","_ indexed-column)*

indexed-column  ←  (column-name / expr) _ (COLLATE name _)? (ASC / DESC)?

    group-expr  ←  "("_ expr _ ")"_ ; probably mute this one
]]




local foreign_key_clause = [[
foreign-key-clause  ←  REFERENCES table-name ("("_ column-names ")"_)?
                       fk-on-clause*
                       (NOT? DEFERRABLE (INITIALLY (DEFERRED / IMMEDIATE))?)?

    `fk-on-clause`  ←  (ON (DELETE / UPDATE)
                           ( SET (NULL / DEFAULT)
                           / CASCADE
                           / RESTRICT
                           / NO ACTION ))
                    /  MATCH name _
]]
























local expression = [[
 ;; expr-compound comes first but written after basic viability is demostrated
expr  ←  expr-atom
`expr-atom`  ←  literal-value
             / bind-parameter
             /  CAST "("_ expr AS type-name _")"
             /  NOT EXISTS "("_ select ")"
             ; / CASE is complex
             / function-expr
             / raise-function

function-expr  ←  function-name "("_ ("*" / (DISTINCT? expr-list)) _")"_
                  filter-clause? over-clause?

; lists are usually lifted, so this one most likely shall be as well
expr-list  ←  expr (_","_ expr)*
]]























local name_rules = [[
         name  ←  quoted / id

     `quoted`  ←  '"' quote-name '"'
               /  "[" quote-name "]"
               /  "`" quote-name "`"
            ;  /  "'" quote-name "'"
         `id`  ←  (!keyword bare-name)

  `bare-name`  ←  lead-char follow-char*
  `lead-char`  ←  [\x80-\xff] / [A-Z] / [a-z] / "_"
`follow-char`  ←  lead-char / [0-9]  / "$" ; deprecated-dollar
   quote-name  ←  (!'"' 1)+

; deprecated-dollar  ← "$"
]]





local literal_rules = [[
literal-value  ←  number / string / blob / NULL / TRUE / FALSE
                  / CURRENT_TIMESTAMP / CURRENT_TIME / CURRENT_DATE
signed-number  ←  {+-}? number

       number  ←  real /  hex / integer

       `real`  ←  (integer ("." integer)*) / ("." integer)
                  (("e" / "E") "-"? integer)?
        `hex`  ←  "0" {Xx} higit+ ("." higit*)?
    `integer`  ←  digit+

      `digit`  ←  [0-9]
      `higit`  ←  digit / [a-f] / [A-F]

       string  ←  "'" ((!"'" 1) / "''") "'"
         blob  ←  {xX} "'" higit* "'"
]]






local whitespace_rules = [[
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
]]






local terminal_rule = [[
`t`  ←  !follow-char
]]












local keyword_rules = [[
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
]]








local keyword_rule = [[
keyword  ←   B (E (T W E E N / F O R E / G I N ) )
             / J O I N
             / D (I S T I N C T / R O P / A T A B A S E / E (T A C H / F (A
             U L T / E (R (R (A B L E / E D ) ) ) ) / L E T E / S C ) )
             / L (I (K E / M I T ) / E F T )
             / E (X (I S T S / C (L U S I V E / E P T ) / P L A I N ) / S
             C A P E / N D / L S E / A C H )
             / T (R (I G G E R / A N S A C T I O N / U E ) / H E N / A B L E
             / E (M (P O R A R Y ) ) )
             / M A T C H
             / N (O (T N U L L ) / A T U R A L / U L L )
             / G (R O U P / L O B / E N E R A T E D )
             / O (R D E R / F F S E T / U T E R )
             / W (I T H O U T / H (E (R E ) ) )
             / K E Y
             / H A V I N G
             / A (B O R T / S C / D D / L (T E R / W A Y S ) / T T A C H / F
             T E R / N (A L Y Z E ) / C T I O N / U T O I N C R E M E N T )
             / P (L A N / R (A G M A / I M A R Y ) )
             / I (G N O R E / M M E D I A T E / S N U L L / N (I T I A L L Y
             / S (T E A D / E R T ) / N E R / D E X / T (E R S E C T ) ) )
             / F (R O M / O (R E I G N ) / A (I L / L S E ) / U L L )
             / Q U E R Y
             / U (P D A T E / S I N G / N (I (Q U E / O N ) ) )
             / S (T (R I C T / O R E D ) / E (L E C T ) )
             / V (A (C U U M / L U E S ) / I (R T U A L / E W ) )
             / C (O (M M I T / L (L A T E / U M N ) / N (S T R A I N T / F
             L I C T ) ) / U (R (R (E (N (T (_ (D A T E / T (I (M (E
             S T A M P ) ) ) ) ) ) ) ) ) ) / R (E A T E / O S S ) / H E C K
             / A (S (C A D E ) ) )
             / R (I G H T / O (L L B A C K / W I D ) / A I S E / E (I
             N D E X / F E R E N C E S / S T R I C T / N A M E / G E X P / P
             L A C E ) ) t
]]









local caseless_letters = [[
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
]]









local sqlite_blocks = {
   sql_statement,
   create_table,
   column_def,
   column_table_constraints,
   foreign_key_clause,
   --expression,
   -- the 'lexer' rules
   literal_rules,
   name_rules,
   keyword_rules,
   keyword_rule,
   caseless_letters,
   whitespace_rules,
   terminal_rule,
}























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
local push = table.insert

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

 print(require "repr:repr" .ts_color(trie))

-- this done, we must print the beast aesthetically.
-- otherwise what is to be gained?

-- but first we must print it /correctly/

local head     =   " keyword  ←   "
local div_pad  = "\n             /  "
local div = " / "
local sub_div = "/ ( "
local WID = 78

local wide = #head

local treezus = {head}

local pad = "\n             "

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

local nkeys = table.nkeys

local function rulify(trie, outer)
   local slash = false
   for letter, tail in pairs(trie) do
      if slash then
         if outer then
            WID = 1 -- ugly!
         end
         addTok("/ ")
         WID = 78
      else
         slash = true
      end
      if type(tail) == 'string' then
         addTok(letter, " ", stretch(tail))
      else
         addTok(letter, " ")
         local split = nkeys(tail) > 1
         if split then
            addTok("(")
         end
         rulify(tail)
         if split then
            addTok(") ")
         else
            addTok(" ")
         end
      end
   end
end

rulify(trie, true)

print(concat(treezus))

local champ = {head}
local footer = " ))\n"

local no_div = true
-- awful hack to work around bad original parser!
local count = 0
for i, kw in ipairs(kwset) do
   count = count + 1
   local div = div
   if count == 20 then
      div = ") / ("
      count = 1
   end
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
-- print(concat(poggers, "\n"))
--print(concat(champ))
--print(concat(kw_pr))






return {table.concat(sqlite_blocks, "\n\n"), blocks = sqlite_blocks}

