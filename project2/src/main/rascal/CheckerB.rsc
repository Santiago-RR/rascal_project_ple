module CheckerB

// Parte B: reglas de tipo de expresiones y control de flujo (TypePal), sobre el
// árbol de sintaxis concreta. No modifica el Checker.rsc de la parte A.

import ParseTree;
import SyntaxExpr;
import SyntaxObjects;
import Lexical;
extend analysis::typepal::TypePal;

// Prefijo "b" para no colisionar con el AType de A. bUnknown: tipo neutral de lo
// que depende del modelo de objetos de A (miembros, llamadas, new, lambda).
data AType
  = bInt()
  | bBool()
  | bStr()
  | bChar()
  | bVoid()
  | bUnknown()
  ;

str prettyAType(bInt())     = "Integer";
str prettyAType(bBool())    = "Boolean";
str prettyAType(bStr())     = "String";
str prettyAType(bChar())    = "Char";
str prettyAType(bVoid())    = "Void";
str prettyAType(bUnknown()) = "?";

data IdRole
  = variableId()
  ;

// Literales
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

void collect(current: (Expression) `<Literal l>`, Collector c) {
  c.fact(current, l);
  collect(l, c);
}

// Anotaciones de tipo primitivo
void collect(current: (PrimitiveType) `Integer`, Collector c) { c.fact(current, bInt()); }
void collect(current: (PrimitiveType) `Boolean`, Collector c) { c.fact(current, bBool()); }
void collect(current: (PrimitiveType) `String`, Collector c)  { c.fact(current, bStr()); }
void collect(current: (PrimitiveType) `Char`, Collector c)    { c.fact(current, bChar()); }

void collect(current: (Type) `<PrimitiveType p>`, Collector c) {
  c.fact(current, p);
  collect(p, c);
}

void collect(current: (Block) `{ <Instruction* insts> }`, Collector c) {
  c.enterScope(current);
    collect(insts, c);
  c.leaveScope(current);
}

void collect(current: (Expression) `<Id name>`, Collector c) {
  c.use(name, {variableId()});
}

void collect(current: (Expression) `( <Expression e> )`, Collector c) {
  c.fact(current, e);
  collect(e, c);
}

// Aritmética: operandos Integer -> Integer.
// La lógica va en línea: una regla de sintaxis concreta que delegue su cuerpo en
// un auxiliar con `Tree current` no se registra en TypePal y falla con CallFailed.
void collect(current: (Expression) `<Expression e1> + <Expression e2>`, Collector c) {
  c.calculate("aritmética +", current, [e1, e2], AType(Solver s) {
    s.requireEqual(e1, bInt(), error(e1, "El operador `+` requiere Integer, no %t", e1));
    s.requireEqual(e2, bInt(), error(e2, "El operador `+` requiere Integer, no %t", e2));
    return bInt();
  });
  collect(e1, c); collect(e2, c);
}
void collect(current: (Expression) `<Expression e1> - <Expression e2>`, Collector c) {
  c.calculate("aritmética -", current, [e1, e2], AType(Solver s) {
    s.requireEqual(e1, bInt(), error(e1, "El operador `-` requiere Integer, no %t", e1));
    s.requireEqual(e2, bInt(), error(e2, "El operador `-` requiere Integer, no %t", e2));
    return bInt();
  });
  collect(e1, c); collect(e2, c);
}
void collect(current: (Expression) `<Expression e1> * <Expression e2>`, Collector c) {
  c.calculate("aritmética *", current, [e1, e2], AType(Solver s) {
    s.requireEqual(e1, bInt(), error(e1, "El operador `*` requiere Integer, no %t", e1));
    s.requireEqual(e2, bInt(), error(e2, "El operador `*` requiere Integer, no %t", e2));
    return bInt();
  });
  collect(e1, c); collect(e2, c);
}
void collect(current: (Expression) `<Expression e1> / <Expression e2>`, Collector c) {
  c.calculate("aritmética /", current, [e1, e2], AType(Solver s) {
    s.requireEqual(e1, bInt(), error(e1, "El operador `/` requiere Integer, no %t", e1));
    s.requireEqual(e2, bInt(), error(e2, "El operador `/` requiere Integer, no %t", e2));
    return bInt();
  });
  collect(e1, c); collect(e2, c);
}
void collect(current: (Expression) `<Expression e1> % <Expression e2>`, Collector c) {
  c.calculate("aritmética %", current, [e1, e2], AType(Solver s) {
    s.requireEqual(e1, bInt(), error(e1, "El operador `%` requiere Integer, no %t", e1));
    s.requireEqual(e2, bInt(), error(e2, "El operador `%` requiere Integer, no %t", e2));
    return bInt();
  });
  collect(e1, c); collect(e2, c);
}
void collect(current: (Expression) `<Expression e1> ** <Expression e2>`, Collector c) {
  c.calculate("aritmética **", current, [e1, e2], AType(Solver s) {
    s.requireEqual(e1, bInt(), error(e1, "El operador `**` requiere Integer, no %t", e1));
    s.requireEqual(e2, bInt(), error(e2, "El operador `**` requiere Integer, no %t", e2));
    return bInt();
  });
  collect(e1, c); collect(e2, c);
}

// Comparaciones: operandos del mismo tipo -> Boolean
void collect(current: (Expression) `<Expression e1> \< <Expression e2>`, Collector c) {
  c.calculate("comparación \<", current, [e1, e2], AType(Solver s) {
    s.requireEqual(e1, e2, error(current, "`\<` requiere operandos del mismo tipo, no %t y %t", e1, e2));
    return bBool();
  });
  collect(e1, c); collect(e2, c);
}
void collect(current: (Expression) `<Expression e1> \> <Expression e2>`, Collector c) {
  c.calculate("comparación \>", current, [e1, e2], AType(Solver s) {
    s.requireEqual(e1, e2, error(current, "`\>` requiere operandos del mismo tipo, no %t y %t", e1, e2));
    return bBool();
  });
  collect(e1, c); collect(e2, c);
}
void collect(current: (Expression) `<Expression e1> \<= <Expression e2>`, Collector c) {
  c.calculate("comparación \<=", current, [e1, e2], AType(Solver s) {
    s.requireEqual(e1, e2, error(current, "`\<=` requiere operandos del mismo tipo, no %t y %t", e1, e2));
    return bBool();
  });
  collect(e1, c); collect(e2, c);
}
void collect(current: (Expression) `<Expression e1> \>= <Expression e2>`, Collector c) {
  c.calculate("comparación \>=", current, [e1, e2], AType(Solver s) {
    s.requireEqual(e1, e2, error(current, "`\>=` requiere operandos del mismo tipo, no %t y %t", e1, e2));
    return bBool();
  });
  collect(e1, c); collect(e2, c);
}
void collect(current: (Expression) `<Expression e1> \<\> <Expression e2>`, Collector c) {
  c.calculate("comparación \<\>", current, [e1, e2], AType(Solver s) {
    s.requireEqual(e1, e2, error(current, "`\<\>` requiere operandos del mismo tipo, no %t y %t", e1, e2));
    return bBool();
  });
  collect(e1, c); collect(e2, c);
}
void collect(current: (Expression) `<Expression e1> = <Expression e2>`, Collector c) {
  c.calculate("comparación =", current, [e1, e2], AType(Solver s) {
    s.requireEqual(e1, e2, error(current, "`=` requiere operandos del mismo tipo, no %t y %t", e1, e2));
    return bBool();
  });
  collect(e1, c); collect(e2, c);
}

// Lógica: and / or / neg sobre Boolean -> Boolean
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

// if-then-else: condición Boolean, ramas del mismo tipo -> ese tipo
void collect(current: (Expression) `if <Expression cond> then <Expression e1> else <Expression e2>`, Collector c) {
  c.calculate("if-then-else", current, [cond, e1, e2],
    AType(Solver s) {
      s.requireEqual(cond, bBool(), error(cond, "La condición del `if` debe ser Boolean, no %t", cond));
      s.requireEqual(e1, e2, error(current, "Las ramas del `if` deben tener el mismo tipo, no %t y %t", e1, e2));
      return s.getType(e1);
    });
  collect(cond, e1, e2, c);
}

// Interpolación y concatenación de strings -> String
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

// Rango "1 -> 10": extremos Integer
void collect(current: (Expression) `<Expression e1> -\> <Expression e2>`, Collector c) {
  c.calculate("rango", current, [e1, e2],
    AType(Solver s) {
      s.requireEqual(e1, bInt(), error(e1, "El extremo del rango debe ser Integer, no %t", e1));
      s.requireEqual(e2, bInt(), error(e2, "El extremo del rango debe ser Integer, no %t", e2));
      return bInt();
    });
  collect(e1, e2, c);
}

// for con <- y con in. El cuerpo es un Block; el patrón define sus variables.
void collect(current: (ForLoop) `for ( <IterationPattern pattern> \<- <Expression source> ) <Block body>`, Collector c) {
  c.enterScope(current);
    collect(source, c);
    collect(pattern, c);
    collect(body, c);
  c.leaveScope(current);
}
void collect(current: (ForLoop) `for ( <IterationPattern pattern> in <Expression source> ) <Block body>`, Collector c) {
  c.enterScope(current);
    collect(source, c);
    collect(pattern, c);
    collect(body, c);
  c.leaveScope(current);
}

// INTEGRACIÓN CON A: el tipo del elemento (hoy bUnknown) depende del modelo de
// colecciones de A.
void collect(current: (IterationPattern) `<Id name>`, Collector c) {
  c.define("<name>", variableId(), name, defType(bUnknown()));
}
void collect(current: (IterationPattern) `( <{Id ","}+ names> )`, Collector c) {
  for (nm <- names) {
    c.define("<nm>", variableId(), nm, defType(bUnknown()));
  }
}

// Llamadas libres: print/println -> Void. INTEGRACIÓN CON A: resolver el resto.
void collect(current: (Expression) `<Id name> ( <{Expression ","}* args> )`, Collector c) {
  collect(args, c);
  if ("<name>" in {"print", "println"}) {
    c.fact(current, bVoid());
  } else {
    c.fact(current, bUnknown());
  }
}

// INTEGRACIÓN CON A: acceso a miembros y llamadas a métodos (modelo de objetos).
void collect(current: (Expression) `<Expression target> . <MemberName member>`, Collector c) {
  collect(target, c);
  c.fact(current, bUnknown());
}
void collect(current: (Expression) `<Expression target> . <MemberName member> ( <{Expression ","}* args> )`, Collector c) {
  collect(target, c);
  collect(args, c);
  c.fact(current, bUnknown());
}

// INTEGRACIÓN CON A: new y lambda (modelo de objetos / transformaciones).
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
    collect(param, c);
    collect(result, c);
  c.leaveScope(current);
  c.fact(current, bUnknown());
}

// Declaraciones val/var. INTEGRACIÓN CON A: `Declaration` es compartida (A la usa
// para campos de objeto); al integrar, unificar esta regla con la de A.
void collect(current: (Declaration) `<Binding mode> <Id name> = <Expression expr>`, Collector c) {
  c.define("<name>", variableId(), name, defType(expr));
  collect(expr, c);
}
void collect(current: (Declaration) `<Binding mode> <Id name> : <Type tp> = <Expression expr>`, Collector c) {
  c.define("<name>", variableId(), name, defType(tp));
  c.require("tipo de la declaración `<name>`", current, [tp, expr],
    void(Solver s) {
      s.requireEqual(expr, tp, error(expr, "`<name>` se declara como %t pero la expresión es %t", tp, expr));
    });
  collect(tp, c);
  collect(expr, c);
}

// Arranque del checker de B (pruebas aisladas y programa completo).
TypePalConfig configB() = tconfig();

public TModel checkExpr(Expression e) = collectAndSolve(e, config = configB(), modelName = "Objectilang-B-expr");
public TModel checkInstruction(Instruction i) = collectAndSolve(i, config = configB(), modelName = "Objectilang-B-inst");
public list[Message] messagesOfExpr(Expression e) = checkExpr(e).messages;
public list[Message] messagesOfInstruction(Instruction i) = checkInstruction(i).messages;

public TModel checkModule(start[Module] pt) = collectAndSolve(pt.top, config = configB(), modelName = "Objectilang");
public list[Message] messagesOfModule(start[Module] pt) = checkModule(pt).messages;
