module TestOl

/*
 * Verifica que los archivos .ol de examples/ parsean como Module (árbol
 * concreto). El chequeo de tipos y la ejecución completos de los snippets con
 * objetos dependen de la integración con la parte A; aquí solo se comprueba el
 * parseo, que es responsabilidad compartida de la gramática.
 */

import IO;
import ParseTree;
import Lexical;
import SyntaxObjects;
import SyntaxExpr;

void checkParse(str name) {
  loc f = |cwd:///examples/| + name;
  try {
    parse(#start[Module], readFile(f));
    println("[OK parseo] <name>");
  } catch ParseError(loc l): println("[FALLA parseo] <name> en <l>");
  catch e: println("[ERROR] <name>: <e>");
}

void main(list[str] args=[]) {
  println("=== Parseo de los archivos .ol de examples/ ===");
  checkParse("expresiones.ol");
  checkParse("snippet1.ol");
  checkParse("snippet2.ol");
  checkParse("snippet3.ol");
  checkParse("snippet4.ol");
  println("=== Fin ===");
}
