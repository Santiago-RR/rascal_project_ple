module Eval

/*
 * ============================================================================
 *  PARTE B — Intérprete de Objectilang sobre el AST (punto 2: ejecución).
 * ============================================================================
 *
 *  Responsabilidad del Estudiante B. Evalúa expresiones, interpolación de
 *  strings, el bucle for, declaraciones de variables y print/println en consola.
 *  Trabaja sobre el AST (AST.rsc) obtenido con implode: el AST es más cómodo
 *  para evaluar que el árbol de sintaxis concreta.
 *
 *  Lo que depende del modelo de objetos del Estudiante A (crear objetos con new,
 *  acceso a miembros, llamadas a métodos) se evalúa a un valor neutro
 *  (objVal/unknownVal) y queda marcado con "INTEGRACIÓN CON A". El resto de la
 *  ejecución (expresiones, for, print) es completo.
 */

import IO;
import String;
import List;
import AST;

// ----------------------------------------------------------------------------
// 1. Valores en ejecución
// ----------------------------------------------------------------------------
data Value
  = intVal(int n)
  | boolVal(bool b)
  | charVal(str c)          // un único carácter ya des-escapado, ej. "a" o "\n"
  | strVal(str s)
  | listVal(list[Value] elems)
  | tupleVal(list[Value] elems)
  | objVal(str className)   // INTEGRACIÓN CON A: instancia de objeto (placeholder)
  | voidVal()
  | unknownVal()            // INTEGRACIÓN CON A: resultado no calculable sin A
  ;

// Ambiente de variables: nombre -> valor.
alias Env = map[str, Value];

// ----------------------------------------------------------------------------
// 2. Utilidades de literales
// ----------------------------------------------------------------------------

// Resuelve los escapes y quita las comillas de un literal de carácter 'x' o '\n'.
str unescapeChar(str raw) {
  // raw llega como "'x'" (con las comillas simples). Quitamos la primera y la última.
  str inner = substring(raw, 1, size(raw) - 1);
  return unescape(inner);
}

// Resuelve los escapes de un trozo de texto de string (sin las comillas dobles).
str unescape(str s) {
  str out = "";
  int i = 0;
  int n = size(s);
  while (i < n) {
    str ch = stringChar(charAt(s, i));
    if (ch == "\\" && i + 1 < n) {
      str nextCh = stringChar(charAt(s, i + 1));
      switch (nextCh) {
        case "n": out += "\n";
        case "t": out += "\t";
        case "\"": out += "\"";
        case "\'": out += "\'";
        case "\\": out += "\\";
        default: out += nextCh;
      }
      i += 2;
    } else {
      out += ch;
      i += 1;
    }
  }
  return out;
}

// Quita las comillas dobles de los extremos de un trozo léxico de string.
// Los trozos pueden traer prefijos/sufijos como "\"", "${", "}": se recorta solo
// lo que corresponda a cada extremo.
str stripQuotes(str s, bool leadingQuote, bool trailingQuote) {
  int from = leadingQuote ? 1 : 0;
  int to = trailingQuote ? size(s) - 1 : size(s);
  return substring(s, from, to);
}

// ----------------------------------------------------------------------------
// 3. Representación de un Value como texto (para print e interpolación)
// ----------------------------------------------------------------------------
str show(intVal(int n))  = "<n>";
str show(boolVal(bool b)) = b ? "true" : "false";
str show(charVal(str c)) = c;
str show(strVal(str s))  = s;
str show(listVal(list[Value] es)) = "[" + intercalate(", ", [show(e) | e <- es]) + "]";
str show(tupleVal(list[Value] es)) = "(" + intercalate(", ", [show(e) | e <- es]) + ")";
str show(objVal(str cn)) = "\<<cn>\>";
str show(voidVal())      = "";
str show(unknownVal())   = "?";

// ----------------------------------------------------------------------------
// 4. Evaluación de expresiones
// ----------------------------------------------------------------------------
Value eval(literal(Literal l), Env env) = evalLit(l, env);

Value evalLit(intLit(str n), Env env)   = intVal(toInt(n));
Value evalLit(trueLit(), Env env)       = boolVal(true);
Value evalLit(falseLit(), Env env)      = boolVal(false);
Value evalLit(charLit(str c), Env env)  = charVal(unescapeChar(c));
Value evalLit(stringLit(StringLiteral s), Env env) = strVal(evalStr(s, env));

Value eval(variable(str name), Env env) {
  if (name in env) return env[name];
  throw "Variable no definida en ejecución: <name>";
}

Value eval(paren(Expression e), Env env) = eval(e, env);

// Aritmética
Value eval(add(Expression a, Expression b), Env env) = intVal(asInt(eval(a, env)) + asInt(eval(b, env)));
Value eval(sub(Expression a, Expression b), Env env) = intVal(asInt(eval(a, env)) - asInt(eval(b, env)));
Value eval(mul(Expression a, Expression b), Env env) = intVal(asInt(eval(a, env)) * asInt(eval(b, env)));
Value eval(div(Expression a, Expression b), Env env) = intVal(asInt(eval(a, env)) / asInt(eval(b, env)));
Value eval(modulo(Expression a, Expression b), Env env) = intVal(asInt(eval(a, env)) % asInt(eval(b, env)));
Value eval(power(Expression a, Expression b), Env env) = intVal(ipow(asInt(eval(a, env)), asInt(eval(b, env))));

// Comparaciones
Value eval(lt(Expression a, Expression b), Env env) = boolVal(asInt(eval(a, env)) < asInt(eval(b, env)));
Value eval(gt(Expression a, Expression b), Env env) = boolVal(asInt(eval(a, env)) > asInt(eval(b, env)));
Value eval(le(Expression a, Expression b), Env env) = boolVal(asInt(eval(a, env)) <= asInt(eval(b, env)));
Value eval(ge(Expression a, Expression b), Env env) = boolVal(asInt(eval(a, env)) >= asInt(eval(b, env)));
Value eval(eq(Expression a, Expression b), Env env) = boolVal(eval(a, env) == eval(b, env));
Value eval(ne(Expression a, Expression b), Env env) = boolVal(eval(a, env) != eval(b, env));

// Lógica (and/or con cortocircuito)
Value eval(andExpr(Expression a, Expression b), Env env) = asBool(eval(a, env)) ? eval(b, env) : boolVal(false);
Value eval(orExpr(Expression a, Expression b), Env env)  = asBool(eval(a, env)) ? boolVal(true) : eval(b, env);
Value eval(neg(Expression e), Env env) = boolVal(!asBool(eval(e, env)));

// Condicional
Value eval(conditional(Expression cond, Expression t, Expression e), Env env) =
  asBool(eval(cond, env)) ? eval(t, env) : eval(e, env);

// Rango 1 -> 10 : lista de enteros [1..10] inclusive
Value eval(range(Expression a, Expression b), Env env) {
  int lo = asInt(eval(a, env));
  int hi = asInt(eval(b, env));
  return listVal([intVal(k) | k <- [lo .. hi + 1]]);
}

// Llamada libre: print / println; el resto es INTEGRACIÓN CON A.
Value eval(call(str name, list[Expression] args), Env env) {
  list[Value] vs = [eval(a, env) | a <- args];
  switch (name) {
    case "print": {
      print(intercalate(" ", [show(v) | v <- vs]));
      return voidVal();
    }
    case "println": {
      println(intercalate(" ", [show(v) | v <- vs]));
      return voidVal();
    }
    default: return unknownVal();  // INTEGRACIÓN CON A: funciones/métodos definidos por el usuario
  }
}

// INTEGRACIÓN CON A: objetos, miembros, métodos, lambda.
Value eval(newObject(Type t, list[ObjectBody] body), Env env) = objVal(typeName(t));
Value eval(newObjectArgs(Type t, NewArguments a, list[ObjectBody] body), Env env) = objVal(typeName(t));
Value eval(memberAccess(Expression target, MemberName m), Env env) { eval(target, env); return unknownVal(); }
Value eval(methodCall(Expression target, MemberName m, list[Expression] args), Env env) { eval(target, env); return unknownVal(); }
Value eval(lambda(IterationPattern p, Expression body), Env env) = unknownVal();

// Red de seguridad: cualquier expresión no cubierta.
default Value eval(Expression e, Env env) = unknownVal();

// ----------------------------------------------------------------------------
// 5. Interpolación de strings
// ----------------------------------------------------------------------------
// Reconstruye el texto final resolviendo las subexpresiones y variables.
str evalStr(plain(str text), Env env) = unescape(stripQuotes(text, true, true));

str evalStr(interpolated(str pre, Expression e, StrTail tail), Env env) =
  unescape(stripPre(pre)) + show(eval(e, env)) + evalTail(tail, env);

str evalStr(interpolatedName(str pre, str name, StrTailSimple tail), Env env) =
  unescape(stripPreSimple(pre)) + show(lookup(name, env)) + evalTailSimple(tail, env);

str evalTail(mid(str text, Expression e, StrTail tail), Env env) =
  unescape(stripMid(text)) + show(eval(e, env)) + evalTail(tail, env);
str evalTail(post(str text), Env env) = unescape(stripPost(text));

str evalTailSimple(midSimple(str text, str name, StrTailSimple tail), Env env) =
  unescape(stripMidSimple(text)) + show(lookup(name, env)) + evalTailSimple(tail, env);
str evalTailSimple(postSimple(str text), Env env) = unescape(stripPostSimple(text));

// Recortes de los trozos léxicos:
//  StrPre        "..."${    -> quitar "  inicial y ${ final
//  StrMid        }...${     -> quitar } inicial y ${ final
//  StrPost       }..."      -> quitar } inicial y " final
//  StrPreSimple  "...$      -> quitar " inicial y $ final
//  StrMidSimple  ...$       -> quitar $ final
//  StrPostSimple ..."       -> quitar " final
str stripPre(str s)        = substring(s, 1, size(s) - 2);
str stripMid(str s)        = substring(s, 1, size(s) - 2);
str stripPost(str s)       = substring(s, 1, size(s) - 1);
str stripPreSimple(str s)  = substring(s, 1, size(s) - 1);
str stripMidSimple(str s)  = substring(s, 0, size(s) - 1);
str stripPostSimple(str s) = substring(s, 0, size(s) - 1);

Value lookup(str name, Env env) {
  if (name in env) return env[name];
  throw "Variable no definida en ejecución: <name>";
}

// ----------------------------------------------------------------------------
// 6. Instrucciones y bloques
// ----------------------------------------------------------------------------
// Ejecutar una instrucción devuelve el ambiente (posiblemente ampliado).
Env exec(decl(Declaration d), Env env) = execDecl(d, env);
Env exec(expr(Expression e), Env env) { eval(e, env); return env; }
Env exec(control(ForLoop loop), Env env) = execFor(loop, env);

Env execDecl(declaration(Binding mode, str name, list[Type] declaredType, Expression e), Env env) {
  Value v = eval(e, env);
  return env + (name: v);
}

// Ejecutar un bloque: hilar el ambiente por las instrucciones. Las variables
// declaradas dentro del bloque no escapan a su exterior.
Env execBlock(block(list[Instruction] insts), Env env) {
  Env local = env;
  for (i <- insts) local = exec(i, local);
  return local;
}

// for: evaluar la fuente a una colección y ejecutar el cuerpo por cada elemento.
Env execFor(forLoop(IterationPattern pattern, Expression source, Block body), Env env) {
  Value src = eval(source, env);
  list[Value] elems = asElems(src);
  for (Value el <- elems) {
    Env iterEnv = bindPattern(pattern, el, env);
    execBlock(body, iterEnv);
  }
  return env;
}

// Vincula el patrón de iteración (simple o tupla) al valor del elemento.
Env bindPattern(single(str name), Value el, Env env) = env + (name: el);
Env bindPattern(tupleOf(list[str] names), Value el, Env env) {
  list[Value] comps = asElems(el);
  Env out = env;
  for (int k <- [0 .. size(names)]) {
    if (k < size(comps)) out += (names[k]: comps[k]);
  }
  return out;
}

// ----------------------------------------------------------------------------
// 7. Coerciones y utilidades
// ----------------------------------------------------------------------------
int asInt(intVal(int n)) = n;
default int asInt(Value v) { throw "Se esperaba Integer, se obtuvo <v>"; }

bool asBool(boolVal(bool b)) = b;
default bool asBool(Value v) { throw "Se esperaba Boolean, se obtuvo <v>"; }

list[Value] asElems(listVal(list[Value] es)) = es;
list[Value] asElems(tupleVal(list[Value] es)) = es;
default list[Value] asElems(Value v) { throw "El valor no es iterable: <v>"; }

int ipow(int base, int exp) {
  int r = 1;
  for (int _ <- [0 .. exp]) r *= base;
  return r;
}

str typeName(primitive(PrimitiveType p)) = "<p>";
str typeName(user(UserType u)) = userName(u);
str userName(userType(str name, list[TypeArgs] args)) = name;

// ----------------------------------------------------------------------------
// 8. Punto de entrada: ejecutar un Module (corre el cuerpo de main)
// ----------------------------------------------------------------------------
public void run(prog(list[Definition] defs, MainMethod m, list[Definition] otherDefs)) {
  runMain(m);
}
public void runMain(mainMethod(Block body)) {
  execBlock(body, ());
}
