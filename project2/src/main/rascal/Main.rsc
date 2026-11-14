module Main

// Programa de consola (parte B). Flujo: .ol -> parse -> chequeo de tipos -> si
// no hay errores, implode y ejecución; si hay, se reporta y se cancela.

import IO;
import ParseTree;
import Message;
import String;

import Lexical;
import SyntaxObjects;
import SyntaxExpr;
import AST;
import Implode;
extend CheckerB;
extend Checker;
import Eval;

int countErrors(list[Message] msgs) = (0 | it + 1 | m <- msgs, error(_, _) := m);

// Devuelve true si el programa se ejecutó, false si se detuvo antes.
public bool runSource(str source) {
  start[Module] pt;
  try {
    pt = parse(#start[Module], source);
  } catch ParseError(loc l): {
    println("Error de sintaxis en <l>.");
    return false;
  }

  list[Message] msgs = collectAndSolve(pt, config = tconfig()).messages;
  int errs = countErrors(msgs);
  if (errs > 0) {
    println("El programa tiene <errs> error(es) de tipo:");
    for (m <- msgs, error(str txt, loc at) := m)
      println("  - <at>: <txt>");
    println("Ejecución cancelada.");
    return false;
  }

  AST::Module prog = implode(#AST::Module, pt);
  println("--- Salida del programa ---");
  Eval::run(prog);
  println("\n--- Fin ---");
  return true;
}

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

int main(list[str] args=[]) {
  if (args == []) {
    println("Uso: pase la ruta de un archivo .ol como argumento.");
    return 1;
  }
  loc fileLoc = |cwd:///| + args[0];
  return runFile(fileLoc) ? 0 : 1;
}
