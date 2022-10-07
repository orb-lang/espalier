-- Automatically Generated by Espalier

local L = assert(require "lpeg")
local P, V, S, R = L.P, L.V, L.S, L.R
local C, Cg, Cb, Cmt = L.C, L.Cg, L.Cb, L.Cmt

local function _lua_fn(_ENV)
   START 'lua'

   SUPPRESS ("BOM", "block", "semi", "statement", "comefrom", "last_statement"
            , "expr", "group", "fn_head", "local_assign", "mutable_assign",
            "unop", "binop", "compare", "value", "fn_lead", "fn_segment",
            "index", "seg_next", "var", "var_lead", "var_segment",
            "index_expr", "form_list", "form", "key", "val", "exp_list",
            "variable_list", "single_string", "double_string", "escaped",
            "ls_open", "ls_close", "glyph", "utf8", "symbol", "any_sym",
            "imaginary", "real", "long", "integer", "digit", "hex", "higit",
            "_", "comment", "long_comment", "whitespace", "t")

   _ENV["lua"] = V"BOM"^-1 * V"shebang"^0 * V"_" * V"body" * V"_" * V"Error"^0


   _ENV["BOM"] = P"\xef\xbb\xbf"

   _ENV["shebang"] = P"#" * ( -( P"\n" ) * 1 )^0 * P"\n"

   _ENV["body"] = V"block"

   _ENV["Error"] = 1^1

   _ENV["block"] = V"_" * ( V"statement" * V"_" * V"semi"^-1 )^0 * ( V"_" *
                                                             V"last_statement"
                                                                   * V"_" *
                                                                   V"semi"^-1
                                                                   )^-1

   _ENV["semi"] = P";" * V"_"

   _ENV["statement"] = V"do" + V"while" + V"repeat" + V"if" + V"for" + V"defn"
                       + V"assign" + V"goto" + V"comefrom" + V"action"

   _ENV["do"] = P"do" * V"t" * V"chunk" * P"end" * V"t"

   _ENV["while"] = P"while" * V"t" * V"condition" * P"do" * V"t" *
                   V"when_true" * P"end" * V"t"

   _ENV["repeat"] = P"repeat" * V"t" * V"chunk" * P"until" * V"t" *
                    V"condition"

   _ENV["if"] = P"if" * V"t" * V"condition" * P"then" * V"t" * V"when_true" *
                V"elseif"^0 * V"else"^-1 * P"end" * V"t"

   _ENV["for"] = P"for" * V"t" * V"_" * V"counter" * V"_" * P"=" * V"range" *
                 V"_" * P"do" * V"t" * V"chunk" * P"end" * V"t" + P"for" *
                 V"t" * V"_" * V"lvalue" * V"_" * P"in" * V"t" * V"iterator" *
                 P"do" * V"t" * V"chunk" * P"end" * V"t"

   _ENV["defn"] = V"fn_head" * V"_" * V"closure"

   _ENV["assign"] = V"local_assign" + V"mutable_assign"

   _ENV["goto"] = P"goto" * V"t" * V"_" * V"label"

   _ENV["comefrom"] = P"::" * V"label" * P"::"

   _ENV["action"] = ( V"chain" + V"call" ) * V"_" * -( ( V"index" ) )

   _ENV["last_statement"] = V"return" + V"break"

   _ENV["return"] = P"return" * V"t" * V"_" * ( V"exp_list" )^-1

   _ENV["break"] = P"break" * V"t"

   _ENV["chunk"] = V"block"

   _ENV["condition"] = V"_" * V"expr" * V"_"

   _ENV["elseif"] = P"elseif" * V"t" * V"condition" * P"then" * V"t" *
                    V"when_true"

   _ENV["else"] = P"else" * V"t" * V"when_false"

   _ENV["when_true"] = V"block"

   _ENV["when_false"] = V"block"

   _ENV["counter"] = V"variable"

   _ENV["range"] = V"expression" * P"," * V"expression" * ( P"," *
                                                          V"expression" )^-1

   _ENV["iterator"] = V"expression" * ( P"," * V"expression" )^-1 * ( P"," *
                                                                 V"expression"
                                                                    )^-1

   _ENV["expression"] = V"_" * V"expr" * V"_"

   _ENV["expr"] = V"unop" + V"value" * V"_" * ( V"binop" * V"_" * V"expr" )^0
                  + V"group"

   _ENV["group"] = P"(" * V"_" * V"expression" * V"_" * P")"

   _ENV["fn_head"] = P"function" * V"t" * V"_" * V"function_name" + V"local" *
                     V"_" * P"function" * V"t" * V"_" * V"local_function_name"


   _ENV["function_name"] = V"reference" * V"_" * ( P"." * V"_" * V"field" )^1
                           * V"_" * V"message"^-1 + V"reference" * V"_" *
                           V"message" + V"variable"

   _ENV["local"] = P"local" * V"t"

   _ENV["local_function_name"] = V"variable"

   _ENV["message"] = ( P":" * V"_" * V"field" )

   _ENV["local_assign"] = V"local" * V"_" * V"lvalue" * V"_" * ( P"=" * V"_" *
                                                               V"rvalue" )^-1

   _ENV["mutable_assign"] = V"var_list" * V"_" * P"=" * V"_" * V"rvalue"

   _ENV["lvalue"] = V"variable_list"

   _ENV["rvalue"] = V"exp_list"

   _ENV["var_list"] = V"var" * ( V"_" * P"," * V"_" * V"var" )^0

   _ENV["label"] = V"symbol"

   _ENV["unop"] = ( V"unm" + V"len" + V"not" ) * V"_" * V"expr"

   _ENV["unm"] = P"-"

   _ENV["len"] = P"#"

   _ENV["not"] = P"not" * V"t"

   _ENV["binop"] = V"and" + V"or" + V"add" + V"sub" + V"mul" + V"div" + V"mod"
                   + V"pow" + V"concat" + V"compare"

   _ENV["and"] = P"and" * V"t"

   _ENV["or"] = P"or" * V"t"

   _ENV["add"] = P"+"

   _ENV["sub"] = P"-"

   _ENV["mul"] = P"*"

   _ENV["mod"] = P"%"

   _ENV["div"] = P"/"

   _ENV["pow"] = P"^"

   _ENV["concat"] = P".."

   _ENV["compare"] = V"lte" + V"gte" + V"neq" + V"eq" + V"lt" + V"gt"

   _ENV["lte"] = P"<="

   _ENV["gte"] = P">="

   _ENV["neq"] = P"~="

   _ENV["eq"] = P"=="

   _ENV["lt"] = P"<"

   _ENV["gt"] = P">"

   _ENV["value"] = V"nil" + V"boolean" + V"vararg" + V"number" + V"string" +
                   V"table" + V"function" + V"action" + V"var" + V"group"

   _ENV["nil"] = P"nil" * V"t"

   _ENV["boolean"] = P"true" * V"t" + P"false" * V"t"

   _ENV["vararg"] = P"..."

   _ENV["chain"] = V"fn_lead" * ( V"_" * V"fn_segment" )^1

   _ENV["fn_lead"] = V"call" + V"reference"

   _ENV["fn_segment"] = V"field_call" + V"index" * # ( V"_" * V"seg_next" ) +
                        V"method_call" + V"arguments"

   _ENV["call"] = V"caller" * ( V"_" * V"arguments" )^1 + V"expr_method"

   _ENV["caller"] = V"group" + V"reference"

   _ENV["index"] = P"[" * V"expression" * P"]" + P"." * V"_" * V"field"

   _ENV["field"] = V"symbol"

   _ENV["field_call"] = V"index" * ( V"_" * V"arguments" )^1

   _ENV["method_call"] = P":" * V"_" * V"message" * ( V"_" * V"arguments" )^1

   _ENV["expr_method"] = V"group" * V"_" * V"method_call"

   _ENV["seg_next"] = V"_" * ( S":.{[(" + P"'" + P'"' )

   _ENV["message"] = V"symbol"

   _ENV["var"] = V"var_chain" + V"reference" + V"index_expr"

   _ENV["var_chain"] = V"var_lead" * V"_" * ( V"var_segment" * V"_" )^1

   _ENV["var_lead"] = V"call" + V"reference" + V"index_expr"

   _ENV["var_segment"] = ( V"field_call" + V"method_call" ) + V"index" +
                         V"index_expr"

   _ENV["reference"] = V"symbol"

   _ENV["index_expr"] = V"group" * V"_" * # V"index"

   _ENV["table"] = P"{" * V"_" * V"form_list"^0 * V"_" * P"}"

   _ENV["function"] = P"function" * V"t" * V"_" * V"closure"

   _ENV["form_list"] = V"form" * ( V"_" * ( P"," + P";" ) * V"_" * V"form" )^0
                       * ( P"," + P";" )^-1

   _ENV["form"] = V"pair" + V"expression"

   _ENV["pair"] = V"key" * V"_" * P"=" * V"_" * V"val"

   _ENV["key"] = P"[" * V"expression" * P"]" + V"field"

   _ENV["val"] = V"expression"

   _ENV["arguments"] = P"(" * V"_" * ( V"exp_list" * V"_" )^-1 * P")" +
                       V"string" + V"table"

   _ENV["exp_list"] = V"expression" * ( P"," * V"expression" )^0

   _ENV["closure"] = V"parameters" * V"_" * V"body" * V"_" * P"end" * V"t"

   _ENV["parameters"] = P"(" * V"_" * ( V"variable_list" * ( V"_" * P"," *
                                                           V"_" * V"vararg" )
                                      ^0 )^0 * V"_" * P")" + P"(" * V"_" *
                        V"vararg" * V"_" * P")"

   _ENV["variable_list"] = ( V"variable" * V"_" * ( P"," * V"_" * V"variable"
                                                  * V"_" )^0 )

   _ENV["variable"] = V"symbol"

   _ENV["string"] = V"single_string" + V"double_string" + V"long_string"

   _ENV["single_string"] = P"'" * ( V"escaped" + -( P"'" ) * V"utf8" )^0 *
                           P"'"

   _ENV["double_string"] = P'"' * ( V"escaped" + -( P'"' ) * V"utf8" )^0 *
                           P'"'

   _ENV["escaped"] = P"\\" * ( ( S"abfnrtv" + P"'" + P'"' + P"\\" ) + V"digit"
                             * V"digit"^-1 * V"digit"^-1 + P"x" * V"higit" *
                             V"higit" + P"\n" )

   _ENV["long_string"] = V"ls_open" * ( -( V"ls_close" ) * 1 )^0 * V"ls_close"


   _ENV["ls_open"] = P"[" * P"="^0 * P"[" * P"\n"^-1

   _ENV["ls_close"] = P"]" * P"="^0 * P"]"

   _ENV["glyph"] = S"!@#$%^&*()-+={[]\\|:;\"'<,>.?/~`" + P"}"

   _ENV["utf8"] = R"\x00\x7f" + R"\xc2\xdf" * R"\x80\xbf" + R"\xe0\xef" *
                  R"\x80\xbf" * R"\x80\xbf" + R"\xf0\xf4" * R"\x80\xbf" *
                  R"\x80\xbf" * R"\x80\xbf"

   _ENV["symbol"] = -( V"keyword" ) * V"any_sym"

   _ENV["any_sym"] = ( -( ( V"glyph" + S" \t\n\r" + V"digit" ) ) * V"utf8" * (
                                                                             -
                                                                             (
                                                                             (

                                                                      V"glyph"
                                                                             +

                                                                    S" \t\n\r"
                                                                             )
                                                                             )
                                                                             *

                                                                       V"utf8"
                                                                             )
                     ^0 )

   _ENV["number"] = V"imaginary" + V"real" + V"long" + V"hex" + V"integer"

   _ENV["imaginary"] = ( V"real" + V"integer" ) * S"Ii"

   _ENV["real"] = V"integer" * P"." * V"integer"^0 * ( ( P"e" + P"E" ) * P"-"
                                                     ^-1 * V"integer" )^-1

   _ENV["long"] = ( V"integer" + V"hex" ) * S"Uu"^-1 * S"Ll"

   _ENV["integer"] = V"digit"^1

   _ENV["digit"] = R"09"

   _ENV["hex"] = P"0" * S"Xx" * V"higit"^1 * ( P"." * V"higit"^0 )^-1 * ( (
                                                                          P"p"
                                                                          +
                                                                          P"P"
                                                                          ) *
                                                                        P"-"
                                                                        ^-1 *
                                                                      V"higit"
                                                                        ^1 )
                 ^-1

   _ENV["higit"] = V"digit" + R"af" + R"AF"

   _ENV["_"] = V"comment"^1 + V"whitespace"

   _ENV["comment"] = V"whitespace" * V"long_comment" * V"whitespace" +
                     V"whitespace" * P"--" * ( -( P"\n" ) * 1 )^0 *
                     V"whitespace"

   _ENV["long_comment"] = P"--" * V"long_string"

   _ENV["whitespace"] = S" \t\n\r"^0

   _ENV["keyword"] = ( P"and" + P"break" + P"do" + P"elseif" + P"else" +
                     P"end" + P"false" + P"for" + P"function" + P"goto" +
                     P"if" + P"in" + P"local" + P"nil" + P"not" + P"or" +
                     P"repeat" + P"return" + P"then" + P"true" + P"until" +
                     P"while" ) * V"t"

   _ENV["t"] = # ( V"glyph" + S" \t\n\r" + -1 )

   end

return _lua_fn
