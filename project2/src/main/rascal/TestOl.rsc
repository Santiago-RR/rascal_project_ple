module TestOl

import IO;
import ParseTree;
import Lexical;
import SyntaxObjects;
import SyntaxExpr;
import Implode;
import AST;
import Set;
import Exception;

// Importamos ambas partes para fusionar el intérprete y el type checker
import Checker;
import CheckerB;
import Eval;

import analysis::typepal::TypePal;

// Configuración unificada: TypePal usará todas las funciones 'collect' 
// definidas tanto en Checker.rsc como en CheckerB.rsc
TypePalConfig fullConfig() = tconfig();

void runProgram(str name) {
  loc f = |cwd:///examples/| + name;
  println("\n=======================================================");
  println("Ejecutando: <name>");
  println("=======================================================");
  try {
    // 1. Parseo a sintaxis concreta (necesario para TypePal)
    str content = readFile(f);
    start[Module] pt = parse(#start[Module], content);
    println("[1/3] Parseo exitoso.");

    // 2. Chequeo de Tipos con TypePal (Integración A y B)
    TModel model = collectAndSolve(pt, config = fullConfig());
    if (size(model.messages) > 0) {
        println("[2/3] ERRORES DE TIPO ENCONTRADOS:");
        for (msg <- model.messages) {
            println("  - <msg>");
        }
        return; // Detenemos la ejecución si hay errores semánticos
    }
    println("[2/3] Chequeo de tipos exitoso (TypePal OK).");

    // 3. Obtener AST y Ejecutar el código
    AST::Module ast = parseModule(content); 
    println("[3/3] Iniciando ejecución (Eval):");
    println("-------------------------------------------------------");
    run(ast);
    println("\n-------------------------------------------------------");
    println("Ejecución finalizada.");

  } catch ParseError(loc l): {
    println("[FALLA parseo] <name> en <l>");
  } catch value e: {
    println("[ERROR] <name>: <e>");
  }
}

void main(list[str] args=[]) {
  println("=== INTEGRACIÓN FINAL: TYPEPAL + EVAL ===");
  runProgram("snippet1.ol");
  runProgram("snippet2.ol");
  runProgram("snippet3.ol");
  runProgram("snippet4.ol");
  println("=== Fin ===");
}