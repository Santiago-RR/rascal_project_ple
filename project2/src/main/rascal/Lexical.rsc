module Lexical

layout Layout = WhitespaceAndComment* !>> [\ \t\n\r#];

lexical WhitespaceAndComment = 
    [\ \t\n\r] 
  | @category="Comment" "#" ![\n]* $;

lexical Id = 
[a-z] [a-zA-Z0-9]* !>> [a-zA-Z0-9];

lexical TypeId = 
[A-Z] [a-zA-Z0-9]* !>> [a-zA-Z0-9];

// Palabras reservadas del lenguaje
keyword Keywords = "object" | "method" | "main" | 
"extends" | "override" | "val" | "var" | "if" | "else" |
"for" | "in" | "new" | "true" | "false" | "String" | "Integer" | 
"Boolean" | "and" | "or" | "neg";