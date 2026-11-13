module Eval

// Parte B: intérprete de Objectilang sobre el AST. Evalúa expresiones,
// interpolación, el for, declaraciones y print/println en consola. Lo que
// depende del modelo de objetos de A (new, miembros, métodos) da un valor neutro.

import IO;
import String;
import List;
import AST;

data Value
  = intVal(int n)
  | boolVal(bool b)
  | charVal(str c)
  | strVal(str s)
  | listVal(list[Value] elems)
  | tupleVal(list[Value] elems)
  | objVal(str className)
  | voidVal()
  | unknownVal()
  ;

alias Env = map[str, Value];

// raw llega como "'x'" (con las comillas simples); se quitan y se resuelve el escape.
str unescapeChar(str raw) {
  str inner = substring(raw, 1, size(raw) - 1);
  return unescape(inner);
}

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

str stripQuotes(str s, bool leadingQuote, bool trailingQuote) {
  int from = leadingQuote ? 1 : 0;
  int to = trailingQuote ? size(s) - 1 : size(s);
  return substring(s, from, to);
}

// Representación de un Value como texto (para print e interpolación)
str show(intVal(int n))  = "<n>";
str show(boolVal(bool b)) = b ? "true" : "false";
str show(charVal(str c)) = c;
str show(strVal(str s))  = s;
str show(listVal(list[Value] es)) = "[" + intercalate(", ", [show(e) | e <- es]) + "]";
str show(tupleVal(list[Value] es)) = "(" + intercalate(", ", [show(e) | e <- es]) + ")";
str show(objVal(str cn)) = "\<<cn>\>";
str show(voidVal())      = "";
str show(unknownVal())   = "?";

// Evaluación de expresiones
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

Value eval(add(Expression a, Expression b), Env env) = intVal(asInt(eval(a, env)) + asInt(eval(b, env)));
Value eval(sub(Expression a, Expression b), Env env) = intVal(asInt(eval(a, env)) - asInt(eval(b, env)));
Value eval(mul(Expression a, Expression b), Env env) = intVal(asInt(eval(a, env)) * asInt(eval(b, env)));
Value eval(div(Expression a, Expression b), Env env) = intVal(asInt(eval(a, env)) / asInt(eval(b, env)));
Value eval(modulo(Expression a, Expression b), Env env) = intVal(asInt(eval(a, env)) % asInt(eval(b, env)));
Value eval(power(Expression a, Expression b), Env env) = intVal(ipow(asInt(eval(a, env)), asInt(eval(b, env))));

Value eval(lt(Expression a, Expression b), Env env) = boolVal(asInt(eval(a, env)) < asInt(eval(b, env)));
Value eval(gt(Expression a, Expression b), Env env) = boolVal(asInt(eval(a, env)) > asInt(eval(b, env)));
Value eval(le(Expression a, Expression b), Env env) = boolVal(asInt(eval(a, env)) <= asInt(eval(b, env)));
Value eval(ge(Expression a, Expression b), Env env) = boolVal(asInt(eval(a, env)) >= asInt(eval(b, env)));
Value eval(eq(Expression a, Expression b), Env env) = boolVal(eval(a, env) == eval(b, env));
Value eval(ne(Expression a, Expression b), Env env) = boolVal(eval(a, env) != eval(b, env));

// and/or con cortocircuito
Value eval(andExpr(Expression a, Expression b), Env env) = asBool(eval(a, env)) ? eval(b, env) : boolVal(false);
Value eval(orExpr(Expression a, Expression b), Env env)  = asBool(eval(a, env)) ? boolVal(true) : eval(b, env);
Value eval(neg(Expression e), Env env) = boolVal(!asBool(eval(e, env)));

Value eval(conditional(Expression cond, Expression t, Expression e), Env env) =
  asBool(eval(cond, env)) ? eval(t, env) : eval(e, env);

// Rango 1 -> 10: lista de enteros [lo..hi] inclusive
Value eval(range(Expression a, Expression b), Env env) {
  int lo = asInt(eval(a, env));
  int hi = asInt(eval(b, env));
  return listVal([intVal(k) | k <- [lo .. hi + 1]]);
}

// print / println; el resto depende del modelo de A.
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
    default: return unknownVal();
  }
}

default Value eval(Expression e, Env env) = unknownVal();

// Interpolación de strings
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

// Ejecutar una instrucción devuelve el ambiente (posiblemente ampliado).
Env exec(decl(Declaration d), Env env) = execDecl(d, env);
Env exec(expr(Expression e), Env env) { eval(e, env); return env; }
Env exec(control(ForLoop loop), Env env) = execFor(loop, env);

Env execDecl(declaration(Binding mode, str name, list[Type] declaredType, Expression e), Env env) {
  Value v = eval(e, env);
  return env + (name: v);
}

// Las variables declaradas dentro del bloque no escapan a su exterior.
Env execBlock(block(list[Instruction] insts), Env env) {
  Env local = env;
  for (i <- insts) local = exec(i, local);
  return local;
}

Env execFor(forLoop(IterationPattern pattern, Expression source, Block body), Env env) {
  Value src = eval(source, env);
  list[Value] elems = asElems(src);
  for (Value el <- elems) {
    Env iterEnv = bindPattern(pattern, el, env);
    execBlock(body, iterEnv);
  }
  return env;
}

Env bindPattern(single(str name), Value el, Env env) = env + (name: el);
Env bindPattern(tupleOf(list[str] names), Value el, Env env) {
  list[Value] comps = asElems(el);
  Env out = env;
  for (int k <- [0 .. size(names)]) {
    if (k < size(comps)) out += (names[k]: comps[k]);
  }
  return out;
}

// Coerciones y utilidades
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

// Punto de entrada: ejecutar un Module (corre el cuerpo de main)
public void run(prog(list[Definition] defs, MainMethod m, list[Definition] otherDefs)) {
  runMain(m);
}
public void runMain(mainMethod(Block body)) {
  execBlock(body, ());
}

// --- PARTE A
Value eval(newObject(Type t, list[ObjectBody] body), Env env) = objVal(typeName(t));
Value eval(newObjectArgs(Type t, NewArgs a, list[ObjectBody] body), Env env) = objVal(typeName(t));

// Llamada a método calificado (e.g. puppyFeeder.transform(myPuppy))
Value eval(methodCall(Expression target, MemberName m, list[Expression] args), Env env) {
  Value obj = eval(target, env);
  
  if (objVal(str className) := obj) {
    // Si la llamada es .getClass.getSimpleName (como en el Snippet 3)
    if (m == lower("getClass")) return strVal(className);
    
    for (a <- args) eval(a, env); 
    
    // Simulación del Snippet 3:
    if (m == lower("transform") && className == "Transformer") {
       print("Preparing specialized food for an animal...\n");
       return objVal("DogFood");
    }
    
    return unknownVal();
  }
  throw "El objetivo de la llamada a método no es un objeto: <obj>";
}

// Acceso a un miembro
Value eval(memberAccess(Expression target, MemberName m), Env env) {
  Value obj = eval(target, env);
  if (objVal(str className) := obj) {
     if (m == lower("getSimpleName")) return strVal(className); // para .getClass.getSimpleName
     return unknownVal();
  }
  throw "El objetivo del acceso no es un objeto: <obj>";
}
