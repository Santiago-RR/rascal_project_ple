module TestEval

// Pruebas del intérprete de la parte B (Eval.rsc).

import IO;
import ParseTree;
import SyntaxExpr;
import SyntaxObjects;
import Lexical;
import AST;
import Eval;

// El tipo del parse debe ir calificado (#SyntaxExpr::Instruction); si no, implode
// no resuelve los constructores de los otros módulos de sintaxis.
AST::Instruction toInst(str src) = implode(#AST::Instruction, parse(#SyntaxExpr::Instruction, src));

AST::Expression toExpr(str src) {
  AST::Instruction i = toInst(src);
  if (expr(AST::Expression e) := i) return e;
  throw "No es una expresión: <src>";
}

void expectVal(str src, Eval::Value expected) {
  Eval::Value got = eval(toExpr(src), ());
  str verdict = (got == expected) ? "OK" : "FALLA";
  println("[<verdict>] <src> =\> <got> (esperado <expected>)");
}

void runInst(str src) {
  println("--- ejecutando: <src>");
  exec(toInst(src), ());
}

void main(list[str] args=[]) {
  println("=== Pruebas del Intérprete (Eval) de la Parte B ===");

  println("\n--- Aritmética ---");
  expectVal("1 + 2 * 3", intVal(7));
  expectVal("(1 + 2) * 3", intVal(9));
  expectVal("10 - 4 - 3", intVal(3));
  expectVal("2 ** 10", intVal(1024));
  expectVal("17 % 5", intVal(2));

  println("\n--- Comparaciones y lógica ---");
  expectVal("1 \< 2", boolVal(true));
  expectVal("3 \<= 2", boolVal(false));
  expectVal("true and false", boolVal(false));
  expectVal("true or false", boolVal(true));
  expectVal("neg true", boolVal(false));

  println("\n--- Condicional ---");
  expectVal("if 1 \< 2 then 10 else 20", intVal(10));
  expectVal("if 1 \> 2 then 10 else 20", intVal(20));

  println("\n--- Literales ---");
  expectVal("\'a\'", charVal("a"));
  expectVal("\"hola\"", strVal("hola"));

  println("\n--- Rango ---");
  expectVal("1 -\> 3", listVal([intVal(1), intVal(2), intVal(3)]));

  println("\n--- Interpolación (ejecución) ---");
  runInst("print(\"suma = ${1 + 2}\")");         // suma = 3
  println("");

  println("\n--- for con print ---");
  runInst("for (i \<- 1 -\> 3) { print(\"i=${i} \") }");  // i=1 i=2 i=3
  println("");
  runInst("for (i in 1 -\> 3) { println(i) }");            // 1 2 3 en líneas

  println("\n=== Fin ===");
}
