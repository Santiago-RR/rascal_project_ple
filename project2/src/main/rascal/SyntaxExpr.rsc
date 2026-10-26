module SyntaxExpr

/*
 * Parte B: expresiones, literales y control de flujo.
 * Depende de Lexical (Id, TypeId) y de SyntaxObjects (Type, Block, Instruction).
 */

import Lexical;
import SyntaxObjects;

// Expresiones. Precedencia: de mayor a menor (cada ">" baja un nivel)
syntax Expression
  = literal: Literal
  | variable: Id name !>> "("
  | call: Id name "(" {Expression ","}* args ")"        // llamada libre, ej. print(...)
  | paren: "(" Expression expr ")"
  | newObject: "new" Type objType !>> "(" ObjectBody?
  | newObjectArgs: "new" Type objType NewArgs ctorArgs ObjectBody?
  > left ( memberAccess: Expression target "." MemberName member !>> "("
         | methodCall: Expression target "." MemberName member "(" {Expression ","}* args ")" )
  > neg: "neg" Expression expr
  > right power: Expression lhs "**" Expression rhs
  > left ( mul: Expression lhs "*" Expression rhs
         | div: Expression lhs "/" Expression rhs
         | modulo: Expression lhs "%" Expression rhs )
  > left ( add: Expression lhs "+" Expression rhs
         | sub: Expression lhs "-" Expression rhs )
  > non-assoc ( lt: Expression lhs "\<" Expression rhs
              | gt: Expression lhs "\>" Expression rhs
              | le: Expression lhs "\<=" Expression rhs
              | ge: Expression lhs "\>=" Expression rhs
              | ne: Expression lhs "\<\>" Expression rhs
              | eq: Expression lhs "=" Expression rhs )
  > left andExpr: Expression lhs "and" Expression rhs
  > left orExpr: Expression lhs "or" Expression rhs
  > conditional: "if" Expression cond "then" Expression thenBranch "else" Expression elseBranch
  ;

syntax MemberName
  = lower: Id name
  | upper: TypeId name
  ;

syntax NewArgs = newArgs: "(" {Expression ","}* args ")";

// Literales
syntax Literal
  = intLit: IntLit n
  | trueLit: "true"
  | falseLit: "false"
  | stringLit: StringLiteral s
  ;

lexical IntLit = @category="Constant" [0-9]+ !>> [0-9];

// Cadenas con interpolación: "texto $id texto ${expresión} texto"
// Se parte la cadena en trozos léxicos (pre/mid/post) para que los espacios dentro
// del texto no se traten como layout.
syntax StringLiteral
  = plain: StrPlain text
  | interpolated: StrPre pre Expression expr StrTail tail
  | interpolatedName: StrPreSimple pre Id name StrTailSimple simpleTail
  ;

syntax StrTail
  = mid: StrMid text Expression expr StrTail tail
  | post: StrPost text
  ;

syntax StrTailSimple
  = midSimple: StrMidSimple text Id name StrTailSimple tail
  | postSimple: StrPostSimple text
  ;

lexical StrChar = ![\"$\\] | [\\] [\"$\\nt];
lexical StrPlain = @category="Constant" "\"" StrChar* "\"";
lexical StrPre = @category="Constant" "\"" StrChar* "${";
lexical StrMid = @category="Constant" "}" StrChar* "${";
lexical StrPost = @category="Constant" "}" StrChar* "\"";
lexical StrPreSimple = @category="Constant" "\"" StrChar* "$" !>> "{";
lexical StrMidSimple = @category="Constant" StrChar* "$" !>> "{";
lexical StrPostSimple = @category="Constant" StrChar* "\"";

// Control de flujo: for
syntax Instruction = control: ForLoop;

syntax ForLoop = forLoop: "for" "(" IterationPattern pattern "\<-" Expression source ")" Instruction body;

syntax IterationPattern
  = single: Id name
  | tupleOf: "(" {Id ","}+ names ")"
  ;
