module Main

/*
 * ============================================================================
 *  Programa de consola de Objectilang (punto 2 del enunciado).
 * ============================================================================
 *
 *  Flujo end-to-end:
 *    archivo .ol  ->  parse (árbol concreto)
 *                 ->  chequeo de tipos (TypePal)
 *                 ->  si hay errores: reportar y detener
 *                 ->  si no: implode al AST  ->  ejecutar  ->  salida en consola
 *
 *  Responsabilidad del Estudiante B. El chequeo usa CheckerB (reglas de
 *  expresiones y control de flujo de B). INTEGRACIÓN CON A: cuando el checker de
 *  objetos/tipos de A esté integrado, `checkModule` será el checker único de
 *  todo el programa; aquí no hay que cambiar nada más.
 */

import IO;
import ParseTree;
import Message;
import String;

import Lexical;
import SyntaxObjects;
import SyntaxExpr;
import AST;
import Implode;
import CheckerB;
import Eval;

// Cuenta los errores de una lista de mensajes.
int countErrors(list[Message] msgs) = (0 | it + 1 | m <- msgs, error(_, _) := m);

// Ejecuta el pipeline completo sobre el texto fuente de un programa.
// Devuelve true si el programa se ejecutó, false si se detuvo antes.
public bool runSource(str source) {
  // 1. Parseo (árbol concreto)
  start[Module] pt;
  try {
    pt = parse(#start[Module], source);
  } catch ParseError(loc l): {
    println("Error de sintaxis en <l>.");
    return false;
  }

  // 2. Chequeo de tipos
  list[Message] msgs = messagesOfModule(pt);
  int errs = countErrors(msgs);
  if (errs > 0) {
    println("El programa tiene <errs> error(es) de tipo:");
    for (m <- msgs, error(str txt, loc at) := m)
      println("  - <at>: <txt>");
    println("Ejecución cancelada.");
    return false;
  }

  // 3. Implode al AST y 4. ejecución
  AST::Module prog = implode(#AST::Module, pt);
  println("--- Salida del programa ---");
  Eval::run(prog);
  println("\n--- Fin ---");
  return true;
}

// Ejecuta el pipeline completo sobre un archivo .ol.
public bool runFile(loc fileLoc) {
  if (!exists(fileLoc)) {
    println("El archivo no existe: <fileLoc>");
    return false;
  }
  if (fileLoc.extension != "ol") {
    println("El archivo no tiene extensión .ol: <fileLoc>");
    return false;
  }
  return runSource(readFile(fileLoc));
}

// Punto de entrada: recibe la ruta del archivo .ol como primer argumento.
int main(list[str] args=[]) {
  if (args == []) {
    println("Uso: pase la ruta de un archivo .ol como argumento.");
    return 1;
  }
  loc fileLoc = |cwd:///| + args[0];
  return runFile(fileLoc) ? 0 : 1;
}
