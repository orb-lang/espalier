# SQL\(ite\) PEG


We start [here](https://www.sqlite.org/draft/tokenreq.html)\.


## Case Insensitive Keywords

No one would call this pretty, but it is correct and legible\.

```peg
`A` <- {Aa}
`B` <- {Bb}
`C` <- {Cc}
`D` <- {Dd}
`E` <- {Ee}
`F` <- {Ff}
`G` <- {Gg}
`H` <- {Hh}
`I` <- {Ii}
`J` <- {Ji}
`K` <- {Kk}
`L` <- {Ll}
`M` <- {Mm}
`N` <- {Nn}
`O` <- {Oo}
`P` <- {Pp}
`Q` <- {Qq}
`R` <- {Rr}
`S` <- {Ss}
`T` <- {Tt}
`U` <- {Uu}
`V` <- {Vv}
`W` <- {Ww}
`X` <- {Xx}
`Y` <- {Yy}
`Z` <- {Zz}
```

### Token Categories


#### Whitespace

```peg
; we do the usual optional and not-optional
`_` <- ws*
`ws` <- (comment / dent / WS)+

; tracking indentation can be useful
`dent` <- "\n" (!"\n" WS)*

; we want a one-byte whitespace-only
; why \f and not \v? don't know!
`WS` <- {\x09\x0a\x0c\x0d\x20} ; {\t\n\f\r }

`comment` <- line-comment / block-comment
`line-comment` <- "--" (!"\n" 1)*
`block-comment` <- "/*" (!"*/" 1)* ("*/" / -1)
```


#### terminal class

The class of bytes which terminates a keyword, allowing `not` to be
distinguished from `note`\.

```peg
`t` <- &(glyph / WS)
```


#### Keywords

We'll give them all Capital letters\.

But I'm not going to generate this by hand\. That would be tedious\.

We need all the keywords, which I can mechanically munge out of the draft spec
like so\.

```lua
local kwset = {"ABORT", "ADD", "AFTER", "ALL", "ALTER", "ANALYZE", "AND",
"AS", "ASC", "ATTACH", "AUTOINCREMENT", "BEFORE", "BEGIN", "BETWEEN", "BY",
"CASCADE","CASE","CAST","CHECK","COLLATE","COLUMN","COMMIT","CONFLICT",
"CONSTRAINT","CREATE","CROSS","CURRENT_DATE","CURRENT_TIME",
"CURRENT_TIMESTAMP","DATABASE","DEFAULT","DEFERRED","DEFERRABLE",
"DELETE","DESC","DETACH","DISTINCT","DROP","END","EACH","ELSE","ESCAPE",
"EXCEPT","EXCLUSIVE","EXISTS","EXPLAIN","FAIL","FOR","FOREIGN","FROM",
"FULL","GLOB","GROUP","HAVING","IF","IGNORE","IMMEDIATE","IN","INDEX",
"INITIALLY","INNER","INSERT","INSTEAD","INTERSECT","INTO","IS",
"ISNULL","JOIN","KEY","LEFT","LIKE","LIMIT","MATCH","NATURAL","NOT",
"NOTNULL","NULL","OF","OFFSET","ON","OR","ORDER","OUTER","PLAN","PRAGMA",
"PRIMARY","QUERY","RAISE","REFERENCES","REGEXP","REINDEX","RENAME","REPLACE",
"RESTRICT","RIGHT","ROLLBACK","ROW","SELECT","SET","TABLE","TEMP","TEMPORARY",
"THEN","TO","TRANSACTION","TRIGGER","UNION","UNIQUE","UPDATE","USING",
"VACUUM","VALUES","VIEW","VIRTUAL","WHEN","WHERE"}
```

To make the keywords, we need to turn e\.g\. `AND` into `AND <- A N D t`, which
is dead easy\.

I insist on justifying the arrows, so we make padding:

```lua
local longest = 0
for _, kw in ipairs(kwset) do
   longest = #kw > longest and #kw or longest
end
```

```lua
local char, byte = assert(string.char), assert(string.byte)
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
   insert(rule, "t")
   poggers[i] = concat(rule)
end
```

```lua
print(concat(poggers, "\n"))
```

Let's see the rule\!

```peg
               ABORT  ←  A B O R T t
                 ADD  ←  A D D t
               AFTER  ←  A F T E R t
                 ALL  ←  A L L t
               ALTER  ←  A L T E R t
             ANALYZE  ←  A N A L Y Z E t
                 AND  ←  A N D t
                  AS  ←  A S t
                 ASC  ←  A S C t
              ATTACH  ←  A T T A C H t
       AUTOINCREMENT  ←  A U T O I N C R E M E N T t
              BEFORE  ←  B E F O R E t
               BEGIN  ←  B E G I N t
             BETWEEN  ←  B E T W E E N t
                  BY  ←  B Y t
             CASCADE  ←  C A S C A D E t
                CASE  ←  C A S E t
                CAST  ←  C A S T t
               CHECK  ←  C H E C K t
             COLLATE  ←  C O L L A T E t
              COLUMN  ←  C O L U M N t
              COMMIT  ←  C O M M I T t
            CONFLICT  ←  C O N F L I C T t
          CONSTRAINT  ←  C O N S T R A I N T t
              CREATE  ←  C R E A T E t
               CROSS  ←  C R O S S t
        CURRENT_DATE  ←  C U R R E N T _ D A T E t
        CURRENT_TIME  ←  C U R R E N T _ T I M E t
   CURRENT_TIMESTAMP  ←  C U R R E N T _ T I M E S T A M P t
            DATABASE  ←  D A T A B A S E t
             DEFAULT  ←  D E F A U L T t
            DEFERRED  ←  D E F E R R E D t
          DEFERRABLE  ←  D E F E R R A B L E t
              DELETE  ←  D E L E T E t
                DESC  ←  D E S C t
              DETACH  ←  D E T A C H t
            DISTINCT  ←  D I S T I N C T t
                DROP  ←  D R O P t
                 END  ←  E N D t
                EACH  ←  E A C H t
                ELSE  ←  E L S E t
              ESCAPE  ←  E S C A P E t
              EXCEPT  ←  E X C E P T t
           EXCLUSIVE  ←  E X C L U S I V E t
              EXISTS  ←  E X I S T S t
             EXPLAIN  ←  E X P L A I N t
                FAIL  ←  F A I L t
                 FOR  ←  F O R t
             FOREIGN  ←  F O R E I G N t
                FROM  ←  F R O M t
                FULL  ←  F U L L t
                GLOB  ←  G L O B t
               GROUP  ←  G R O U P t
              HAVING  ←  H A V I N G t
                  IF  ←  I F t
              IGNORE  ←  I G N O R E t
           IMMEDIATE  ←  I M M E D I A T E t
                  IN  ←  I N t
               INDEX  ←  I N D E X t
           INITIALLY  ←  I N I T I A L L Y t
               INNER  ←  I N N E R t
              INSERT  ←  I N S E R T t
             INSTEAD  ←  I N S T E A D t
           INTERSECT  ←  I N T E R S E C T t
                INTO  ←  I N T O t
                  IS  ←  I S t
              ISNULL  ←  I S N U L L t
                JOIN  ←  J O I N t
                 KEY  ←  K E Y t
                LEFT  ←  L E F T t
                LIKE  ←  L I K E t
               LIMIT  ←  L I M I T t
               MATCH  ←  M A T C H t
             NATURAL  ←  N A T U R A L t
                 NOT  ←  N O T t
             NOTNULL  ←  N O T N U L L t
                NULL  ←  N U L L t
                  OF  ←  O F t
              OFFSET  ←  O F F S E T t
                  ON  ←  O N t
                  OR  ←  O R t
               ORDER  ←  O R D E R t
               OUTER  ←  O U T E R t
                PLAN  ←  P L A N t
              PRAGMA  ←  P R A G M A t
             PRIMARY  ←  P R I M A R Y t
               QUERY  ←  Q U E R Y t
               RAISE  ←  R A I S E t
          REFERENCES  ←  R E F E R E N C E S t
              REGEXP  ←  R E G E X P t
             REINDEX  ←  R E I N D E X t
              RENAME  ←  R E N A M E t
             REPLACE  ←  R E P L A C E t
            RESTRICT  ←  R E S T R I C T t
               RIGHT  ←  R I G H T t
            ROLLBACK  ←  R O L L B A C K t
                 ROW  ←  R O W t
              SELECT  ←  S E L E C T t
                 SET  ←  S E T t
               TABLE  ←  T A B L E t
                TEMP  ←  T E M P t
           TEMPORARY  ←  T E M P O R A R Y t
                THEN  ←  T H E N t
                  TO  ←  T O t
         TRANSACTION  ←  T R A N S A C T I O N t
             TRIGGER  ←  T R I G G E R t
               UNION  ←  U N I O N t
              UNIQUE  ←  U N I Q U E t
              UPDATE  ←  U P D A T E t
               USING  ←  U S I N G t
              VACUUM  ←  V A C U U M t
              VALUES  ←  V A L U E S t
                VIEW  ←  V I E W t
             VIRTUAL  ←  V I R T U A L t
                WHEN  ←  W H E N t
               WHERE  ←  W H E R E t
```
