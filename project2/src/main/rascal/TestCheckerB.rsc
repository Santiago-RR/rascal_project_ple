module TestCheckerB

/*
 * Pruebas del type checker de la parte B (CheckerB.rsc), sobre expresiones e
 * instrucciones aisladas. No depende del checker de objetos de A.
 *
 * Cada caso parsea una expresión/instrucción, corre el checker y cuenta los
 * errores. Se compara el número de errores contra lo esperado.
 */

import IO;
import ParseTree;
import Message;
import SyntaxExpr;
import SyntaxObjects;
import Lexical;
import CheckerB;

int errorsOf(list[Message] msgs) = (0 | it + 1 | m <- msgs, error(_, _) := m);

// Prueba una expresión: parsea, chequea y compara el nº de errores con expected.
void expectExpr(str src, int expected) {
  try {
    Expression e = parse(#Expression, src);
    list[Message] msgs = messagesOfExpr(e);
    int got = errorsOf(msgs);
    str verdict = (got == expected) ? "OK" : "FALLA";
    println("[<verdict>] \"<src>\": esperados <expected>, obtenidos <got>");
    if (got != expected) for (m <- msgs) println("      - <m>");
  } catch e: println("[ERROR parseo] \"<src>\": <e>");
}

// Prueba una instrucción (for, etc.).
void expectInst(str src, int expected) {
  try {
    Instruction i = parse(#Instruction, src);
    list[Message] msgs = messagesOfInstruction(i);
    int got = errorsOf(msgs);
    str verdict = (got == expected) ? "OK" : "FALLA";
    println("[<verdict>] \"<src>\": esperados <expected>, obtenidos <got>");
    if (got != expected) for (m <- msgs) println("      - <m>");
  } catch e: println("[ERROR parseo] \"<src>\": <e>");
}

void main(list[str] args=[]) {
  println("=== Pruebas del Checker de la Parte B ===");

  println("\n--- Literales (punto 4) ---");
  expectExpr("42", 0);
  expectExpr("true", 0);
  expectExpr("false", 0);
  expectExpr("\'a\'", 0);
  expectExpr("\"hola\"", 0);

  println("\n--- Aritmética ---");
  expectExpr("1 + 2", 0);
  expectExpr("1 + 2 * 3", 0);
  expectExpr("1 + true", 1);            // true no es Integer
  expectExpr("1 ** 2", 0);

  println("\n--- Comparaciones ---");
  expectExpr("1 \< 2", 0);
  expectExpr("1 = 2", 0);
  expectExpr("1 \< true", 1);           // tipos distintos

  println("\n--- Lógica ---");
  expectExpr("true and false", 0);
  expectExpr("true or false", 0);
  expectExpr("neg true", 0);
  expectExpr("1 and true", 1);          // 1 no es Boolean
  expectExpr("neg 3", 1);               // 3 no es Boolean

  println("\n--- if-then-else ---");
  expectExpr("if true then 1 else 2", 0);
  expectExpr("if 1 then 2 else 3", 1);        // condición no Boolean
  expectExpr("if true then 1 else false", 1); // ramas de distinto tipo

  println("\n--- Interpolación de strings ---");
  expectExpr("\"x=${1 + 2}\"", 0);
  expectExpr("\"x=${1 + true}\"", 1);   // subexpresión mal tipada

  println("\n--- Rango ---");
  expectExpr("1 -\> 10", 0);
  expectExpr("1 -\> true", 1);          // extremo no Integer

  println("\n--- for (control de flujo) ---");
  expectInst("for (i \<- 1 -\> 10) { print(i) }", 0);
  expectInst("for (i in 1 -\> 10) { print(i) }", 0);

  println("\n=== Fin ===");
}
