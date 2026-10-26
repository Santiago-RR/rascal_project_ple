module Lexical

layout Layout = WhitespaceAndComment* !>> [\ \t\n\r#];

lexical WhitespaceAndComment =
    [\ \t\n\r]
  | @category="Comment" "#" ![\n]* $;

// Identificador: minúscula inicial, luego letras, dígitos o guiones bajos; no puede ser reservada
lexical Id = @category="Variable" ([a-z] [a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Keywords;

// Nombres de objetos, tipos y parámetros genéricos: mayúscula inicial
lexical TypeId = @category="Type" ([A-Z] [a-zA-Z0-9_]* !>> [a-zA-Z0-9_]) \ Keywords;

keyword Keywords = "object" | "method" | "main" |
"extends" | "override" | "val" | "var" | "if" | "then" | "else" |
"for" | "in" | "new" | "true" | "false" | "String" | "Integer" |
"Boolean" | "and" | "or" | "neg";
