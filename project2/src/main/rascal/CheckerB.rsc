module CheckerB

/*
 * ============================================================================
 *  PARTE B — Reglas de tipo de expresiones y control de flujo (TypePal).
 * ============================================================================
 *
 *  Este módulo es responsabilidad del Estudiante B. Contiene únicamente las
 *  reglas de tipo de la parte B (puntos 4 y 5 del enunciado para expresiones):
 *  literales tipados (Integer, Boolean, Char, String), aritmética, comparaciones,
 *  lógica (and/or/neg), concatenación e interpolación de strings, if-then-else,
 *  acceso a miembros y llamadas, el operador de rango y el bucle for.
 *
 *  Decisión de arquitectura (verificada contra TypePal 0.17.3):
 *  TypePal colecciona constraints SOBRE EL ÁRBOL DE SINTAXIS CONCRETA (Tree del
 *  parse), nunca sobre el AST obtenido con implode. Por eso las reglas usan
 *  patrones de sintaxis concreta `(Expression) \`...\`` y no constructores del AST.
 *
 *  Este módulo NO toca el Checker.rsc del Estudiante A. Las reglas de objetos,
 *  genéricos, herencia, declaraciones y métodos pertenecen a A. Donde una regla
 *  de B necesita el modelo de tipos de A (acceso a miembros, llamadas a métodos,
 *  tipos de usuario), se deja una regla mínima que compila y queda marcada con
 *  "INTEGRACIÓN CON A" para fusionarla cuando la parte de A esté lista.
 */

import ParseTree;
import SyntaxExpr;
import SyntaxObjects;
import Lexical;
extend analysis::typepal::TypePal;

// ----------------------------------------------------------------------------
// 1. Tipos de Objectilang relevantes para la parte B
// ----------------------------------------------------------------------------
// Prefijo "b" para no colisionar con el AType que define A en su Checker.rsc.
// aBottom() es un tipo neutral/desconocido: lo usan las construcciones cuyo
// tipo depende del modelo de objetos de A (miembros, llamadas, new, lambda).
// Es comparable con cualquier cosa para no generar errores espurios mientras A
// no esté integrado.
data AType
  = bInt()
  | bBool()
  | bStr()
  | bChar()
  | bVoid()        // resultado de instrucciones como print(...)
  | bUnknown()     // tipo aún no resoluble sin el modelo de A
  ;

str prettyAType(bInt())     = "Integer";
str prettyAType(bBool())    = "Boolean";
str prettyAType(bStr())     = "String";
str prettyAType(bChar())    = "Char";
str prettyAType(bVoid())    = "Void";
str prettyAType(bUnknown()) = "?";

// ----------------------------------------------------------------------------
// 2. Roles de identificador
// ----------------------------------------------------------------------------
data IdRole
  = variableId()
  ;

// ----------------------------------------------------------------------------
// 3. Literales (punto 4: literales tipados)
// ----------------------------------------------------------------------------
void collect(current: (Literal) `<IntLit _>`, Collector c) {
  c.fact(current, bInt());
}
void collect(current: (Literal) `true`, Collector c) {
  c.fact(current, bBool());
}
void collect(current: (Literal) `false`, Collector c) {
  c.fact(current, bBool());
}
void collect(current: (Literal) `<CharLit _>`, Collector c) {
  c.fact(current, bChar());
}
void collect(current: (Literal) `<StringLiteral s>`, Collector c) {
  c.fact(current, bStr());
  collect(s, c);
}

// Una Expression que es solo un Literal copia el tipo del literal.
void collect(current: (Expression) `<Literal l>`, Collector c) {
  c.fact(current, l);
  collect(l, c);
}

// ----------------------------------------------------------------------------
// 4. Mapeo de las anotaciones de tipo primitivo a AType (punto 5)
// ----------------------------------------------------------------------------
// Permite que `val x: Integer = ...` compare la anotación con el tipo de la
// expresión. Los tipos de usuario (UserType) son responsabilidad de A.
void collect(current: (PrimitiveType) `Integer`, Collector c) { c.fact(current, bInt()); }
void collect(current: (PrimitiveType) `Boolean`, Collector c) { c.fact(current, bBool()); }
void collect(current: (PrimitiveType) `String`, Collector c)  { c.fact(current, bStr()); }
void collect(current: (PrimitiveType) `Char`, Collector c)    { c.fact(current, bChar()); }

void collect(current: (Type) `<PrimitiveType p>`, Collector c) {
  c.fact(current, p);
  collect(p, c);
}

// ----------------------------------------------------------------------------
// 5. Variables (punto 5: deben existir)
// ----------------------------------------------------------------------------
void collect(current: (Expression) `<Id name>`, Collector c) {
  c.use(name, {variableId()});
}

// Paréntesis: el tipo es el de la expresión interna.
void collect(current: (Expression) `( <Expression e> )`, Collector c) {
  c.fact(current, e);
  collect(e, c);
}

// ----------------------------------------------------------------------------
// 6. Aritmética: operandos Integer -> Integer
// ----------------------------------------------------------------------------
void collectArith(Tree current, Expression e1, Expression e2, str op, Collector c) {
  c.calculate("aritmética <op>", current, [e1, e2],
    AType(Solver s) {
      s.requireEqual(e1, bInt(), error(e1, "El operador `<op>` requiere Integer, no %t", e1));
      s.requireEqual(e2, bInt(), error(e2, "El operador `<op>` requiere Integer, no %t", e2));
      return bInt();
    });
  collect(e1, e2, c);
}

void collect(current: (Expression) `<Expression e1> + <Expression e2>`, Collector c)  = collectArith(current, e1, e2, "+", c);
void collect(current: (Expression) `<Expression e1> - <Expression e2>`, Collector c)  = collectArith(current, e1, e2, "-", c);
void collect(current: (Expression) `<Expression e1> * <Expression e2>`, Collector c)  = collectArith(current, e1, e2, "*", c);
void collect(current: (Expression) `<Expression e1> / <Expression e2>`, Collector c)  = collectArith(current, e1, e2, "/", c);
void collect(current: (Expression) `<Expression e1> % <Expression e2>`, Collector c)  = collectArith(current, e1, e2, "%", c);
void collect(current: (Expression) `<Expression e1> ** <Expression e2>`, Collector c) = collectArith(current, e1, e2, "**", c);

// ----------------------------------------------------------------------------
// 7. Comparaciones: operandos del mismo tipo -> Boolean
// ----------------------------------------------------------------------------
void collectCompare(Tree current, Expression e1, Expression e2, str op, Collector c) {
  c.calculate("comparación <op>", current, [e1, e2],
    AType(Solver s) {
      s.requireEqual(e1, e2, error(current, "`<op>` requiere operandos del mismo tipo, no %t y %t", e1, e2));
      return bBool();
    });
  collect(e1, e2, c);
}

void collect(current: (Expression) `<Expression e1> \< <Expression e2>`, Collector c)   = collectCompare(current, e1, e2, "\<", c);
void collect(current: (Expression) `<Expression e1> \> <Expression e2>`, Collector c)   = collectCompare(current, e1, e2, "\>", c);
void collect(current: (Expression) `<Expression e1> \<= <Expression e2>`, Collector c)  = collectCompare(current, e1, e2, "\<=", c);
void collect(current: (Expression) `<Expression e1> \>= <Expression e2>`, Collector c)  = collectCompare(current, e1, e2, "\>=", c);
void collect(current: (Expression) `<Expression e1> \<\> <Expression e2>`, Collector c) = collectCompare(current, e1, e2, "\<\>", c);
void collect(current: (Expression) `<Expression e1> = <Expression e2>`, Collector c)    = collectCompare(current, e1, e2, "=", c);

// ----------------------------------------------------------------------------
// 8. Lógica: and / or / neg sobre Boolean -> Boolean
// ----------------------------------------------------------------------------
void collect(current: (Expression) `<Expression e1> and <Expression e2>`, Collector c) {
  c.calculate("and", current, [e1, e2],
    AType(Solver s) {
      s.requireEqual(e1, bBool(), error(e1, "`and` requiere Boolean, no %t", e1));
      s.requireEqual(e2, bBool(), error(e2, "`and` requiere Boolean, no %t", e2));
      return bBool();
    });
  collect(e1, e2, c);
}
void collect(current: (Expression) `<Expression e1> or <Expression e2>`, Collector c) {
  c.calculate("or", current, [e1, e2],
    AType(Solver s) {
      s.requireEqual(e1, bBool(), error(e1, "`or` requiere Boolean, no %t", e1));
      s.requireEqual(e2, bBool(), error(e2, "`or` requiere Boolean, no %t", e2));
      return bBool();
    });
  collect(e1, e2, c);
}
void collect(current: (Expression) `neg <Expression e>`, Collector c) {
  c.calculate("neg", current, [e],
    AType(Solver s) {
      s.requireEqual(e, bBool(), error(e, "`neg` requiere Boolean, no %t", e));
      return bBool();
    });
  collect(e, c);
}

// ----------------------------------------------------------------------------
// 9. if-then-else: condición Boolean, ramas del mismo tipo -> ese tipo
// ----------------------------------------------------------------------------
void collect(current: (Expression) `if <Expression cond> then <Expression e1> else <Expression e2>`, Collector c) {
  c.calculate("if-then-else", current, [cond, e1, e2],
    AType(Solver s) {
      s.requireEqual(cond, bBool(), error(cond, "La condición del `if` debe ser Boolean, no %t", cond));
      s.requireEqual(e1, e2, error(current, "Las ramas del `if` deben tener el mismo tipo, no %t y %t", e1, e2));
      return s.getType(e1);
    });
  collect(cond, e1, e2, c);
}

// ----------------------------------------------------------------------------
// 10. Interpolación y concatenación de strings -> String
// ----------------------------------------------------------------------------
// Toda cadena (plana o interpolada) tiene tipo String. Las subexpresiones
// interpoladas se recolectan para que sus propios usos/tipos se verifiquen.
void collect(current: (StringLiteral) `<StrPlain _>`, Collector c) {
  c.fact(current, bStr());
}
void collect(current: (StringLiteral) `<StrPre _> <Expression e> <StrTail tail>`, Collector c) {
  c.fact(current, bStr());
  collect(e, c);
  collect(tail, c);
}
void collect(current: (StringLiteral) `<StrPreSimple _> <Id name> <StrTailSimple tail>`, Collector c) {
  c.fact(current, bStr());
  c.use(name, {variableId()});
  collect(tail, c);
}
void collect(current: (StrTail) `<StrMid _> <Expression e> <StrTail tail>`, Collector c) {
  collect(e, c);
  collect(tail, c);
}
void collect(current: (StrTail) `<StrPost _>`, Collector c) { }
void collect(current: (StrTailSimple) `<StrMidSimple _> <Id name> <StrTailSimple tail>`, Collector c) {
  c.use(name, {variableId()});
  collect(tail, c);
}
void collect(current: (StrTailSimple) `<StrPostSimple _>`, Collector c) { }

// ----------------------------------------------------------------------------
// 11. Rango "1 -> 10": extremos Integer. Tipo del rango: Integer (tipo del
//     elemento que produce al iterarse). El for lo consume como fuente.
// ----------------------------------------------------------------------------
void collect(current: (Expression) `<Expression e1> -\> <Expression e2>`, Collector c) {
  c.calculate("rango", current, [e1, e2],
    AType(Solver s) {
      s.requireEqual(e1, bInt(), error(e1, "El extremo del rango debe ser Integer, no %t", e1));
      s.requireEqual(e2, bInt(), error(e2, "El extremo del rango debe ser Integer, no %t", e2));
      return bInt();
    });
  collect(e1, e2, c);
}

// ----------------------------------------------------------------------------
// 12. for con <- y con in. El cuerpo es un Block; el patrón define sus
//     variables con el tipo del elemento de la fuente (el tipo de `source`).
// ----------------------------------------------------------------------------
void collectFor(Tree current, IterationPattern pattern, Expression source, Block body, Collector c) {
  c.enterScope(current);
    collect(source, c);
    collectPattern(pattern, source, c);
    collect(body, c);
  c.leaveScope(current);
}
void collect(current: (ForLoop) `for ( <IterationPattern pattern> \<- <Expression source> ) <Block body>`, Collector c)
  = collectFor(current, pattern, source, body, c);
void collect(current: (ForLoop) `for ( <IterationPattern pattern> in <Expression source> ) <Block body>`, Collector c)
  = collectFor(current, pattern, source, body, c);

// El patrón del for define las variables de iteración. Para un patrón simple el
// tipo es el del elemento de la fuente (aproximado al tipo de la fuente, que en
// el caso de un rango es Integer). Para una tupla, el tipo exacto depende del
// modelo de colecciones de A; se definen las variables como bUnknown (no rompe
// el build) y queda marcado para integrar con A.
void collectPattern(IterationPattern pattern, Expression source, Collector c) {
  switch (pattern) {
    case (IterationPattern) `<Id name>`: {
      c.define("<name>", variableId(), name, defType(source));  // INTEGRACIÓN CON A: tipo del elemento
    }
    case (IterationPattern) `( <{Id ","}+ names> )`: {
      for (nm <- names) {
        c.define("<nm>", variableId(), nm, defType(bUnknown()));  // INTEGRACIÓN CON A: tipo de cada componente de la tupla
      }
    }
  }
}

// ----------------------------------------------------------------------------
// 13. Llamadas libres (print, etc.). Se recolectan los argumentos; el tipo del
//     resultado es Void para print/println y bUnknown para el resto.
//     INTEGRACIÓN CON A: resolver la función/método real y su tipo de retorno.
// ----------------------------------------------------------------------------
void collect(current: (Expression) `<Id name> ( <{Expression ","}* args> )`, Collector c) {
  for (a <- args) collect(a, c);
  if ("<name>" in {"print", "println"}) {
    c.fact(current, bVoid());
  } else {
    c.fact(current, bUnknown());
  }
}

// ----------------------------------------------------------------------------
// 14. Acceso a miembros y llamadas a métodos.
//     INTEGRACIÓN CON A: requieren el modelo de objetos (clases, campos,
//     métodos, herencia). Por ahora tipo bUnknown para no romper el build.
// ----------------------------------------------------------------------------
void collect(current: (Expression) `<Expression target> . <MemberName member>`, Collector c) {
  collect(target, c);
  c.fact(current, bUnknown());
}
void collect(current: (Expression) `<Expression target> . <MemberName member> ( <{Expression ","}* args> )`, Collector c) {
  collect(target, c);
  for (a <- args) collect(a, c);
  c.fact(current, bUnknown());
}

// ----------------------------------------------------------------------------
// 15. new y lambda.
//     INTEGRACIÓN CON A: `new` depende del modelo de objetos. `lambda` depende
//     del modelo de transformaciones/colecciones. Tipo bUnknown por ahora.
// ----------------------------------------------------------------------------
void collect(current: (Expression) `new <Type objType> <ObjectBody? _>`, Collector c) {
  collect(objType, c);
  c.fact(current, bUnknown());
}
void collect(current: (Expression) `new <Type objType> <NewArgs ctorArgs> <ObjectBody? _>`, Collector c) {
  collect(objType, c);
  collect(ctorArgs, c);
  c.fact(current, bUnknown());
}
void collect(current: (Expression) `<IterationPattern param> =\> <Expression result>`, Collector c) {
  c.enterScope(current);
    collectPatternUntyped(param, c);
    collect(result, c);
  c.leaveScope(current);
  c.fact(current, bUnknown());
}
void collectPatternUntyped(IterationPattern pattern, Collector c) {
  switch (pattern) {
    case (IterationPattern) `<Id name>`:
      c.define("<name>", variableId(), name, defType(bUnknown()));
    case (IterationPattern) `( <{Id ","}+ names> )`:
      for (nm <- names) c.define("<nm>", variableId(), nm, defType(bUnknown()));
  }
}

// ----------------------------------------------------------------------------
// 16. Declaraciones de variables (val/var) dentro de un Block.
//     Define la variable con su tipo y, si hay anotación de tipo, exige que el
//     tipo de la expresión coincida (punto 5).
//
//     INTEGRACIÓN CON A: la producción `Declaration` es compartida — A la usa
//     también para campos dentro de ObjectBody. Al integrar los dos checkers
//     esta regla debe quedar en UN solo lugar (si A define otra `collect` para
//     `Declaration`, habrá conflicto de sobrecarga que hay que resolver
//     unificando ambas). Se incluye aquí para que el pipeline de B funcione de
//     forma autónoma (val/var + uso de la variable) mientras A no esté integrado.
// ----------------------------------------------------------------------------
void collect(current: (Declaration) `<Binding mode> <Id name> = <Expression expr>`, Collector c) {
  // Declaración sin anotación de tipo: el tipo se infiere de la expresión.
  c.define("<name>", variableId(), name, defType(expr));
  collect(expr, c);
}
void collect(current: (Declaration) `<Binding mode> <Id name> : <Type tp> = <Expression expr>`, Collector c) {
  // Declaración con anotación: la expresión debe tener el tipo anotado.
  c.define("<name>", variableId(), name, defType(tp));
  c.require("tipo de la declaración `<name>`", current, [tp, expr],
    void(Solver s) {
      s.requireEqual(expr, tp, error(expr, "`<name>` se declara como %t pero la expresión es %t", tp, expr));
    });
  collect(tp, c);
  collect(expr, c);
}

// ----------------------------------------------------------------------------
// 17. Arranque del checker de B (para pruebas aisladas de expresiones/for).
//     El checker definitivo del programa completo (Module) integra A y B; estas
//     funciones permiten probar la parte B sin depender de la parte de A.
// ----------------------------------------------------------------------------
TypePalConfig configB() = tconfig();

public TModel checkExpr(Expression e) = collectAndSolve(e, config = configB(), modelName = "Objectilang-B-expr");
public TModel checkInstruction(Instruction i) = collectAndSolve(i, config = configB(), modelName = "Objectilang-B-inst");
public list[Message] messagesOfExpr(Expression e) = checkExpr(e).messages;
public list[Message] messagesOfInstruction(Instruction i) = checkInstruction(i).messages;

// Chequeo del programa completo (árbol concreto). Cubre las reglas de la parte B.
// INTEGRACIÓN CON A: cuando el checker de A esté integrado, este será el checker
// único del Module (reglas de objetos/tipos de A + expresiones/control de B).
public TModel checkModule(start[Module] pt) = collectAndSolve(pt.top, config = configB(), modelName = "Objectilang");
public list[Message] messagesOfModule(start[Module] pt) = checkModule(pt).messages;
