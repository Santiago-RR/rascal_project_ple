module TestA

import IO;
import ParseTree;
import Message;
import Lexical;
import SyntaxObjects;
import SyntaxExpr;
import AST;
import Implode;
import Eval;
extend Checker;
extend CheckerB;
import analysis::typepal::TypePal;

int errorsOf(list[Message] msgs) = (0 | it + 1 | m <- msgs, error(_, _) := m);

void expectProgram(str label, str src, int expectedErrors) {
  try {
    start[Module] pt = parse(#start[Module], src);
    TModel model = collectAndSolve(pt, config = tconfig());
    int got = errorsOf(model.messages);
    str verdict = (got == expectedErrors) ? "OK" : "FALLA";
    println("[<verdict>] <label>: esperados <expectedErrors> error(es), obtenidos <got>");
    if (got != expectedErrors) {
      for (m <- model.messages, error(_, _) := m) println("      - <m>");
    }
  } catch value e: {
    println("[ERROR] <label>: <e>");
  }
}

void main(list[str] args=[]) {
  println("=== Pruebas de Objetos, Genéricos y Regla de Existencia (Parte A) ===");

  // Caso 1: Herencia y genéricos válidos (+ y -)
  expectProgram("Herencia y varianza válidas",
    "object Animal
     'object Dog extends Animal
     'object Box[+A](val item: A)
     'object Sink[-In, +Out]
     'method main {
     '  val b: Box[Dog] = new Box(new Dog)
     '}", 0);

  // Caso 2 (Punto 6): Superclase inexistente
  expectProgram("Superclase inexistente (extends Fantasma)",
    "object Dog extends Fantasma
     'method main { }", 1);

  // Caso 3 (Punto 6): Tipo inexistente en atributo de constructor
  expectProgram("Tipo inexistente en constructor (val x: Inexistente)",
    "object Caja(val x: Inexistente)
     'method main { }", 1);

  // Caso 4 (Punto 6): Tipo genérico inexistente en método
  expectProgram("Tipo inexistente en parámetro de método",
    "object Servicio {
     '  procesar(dato: DatoDesconocido): Integer = 1
     '}
     'method main { }", 1);

  // Caso 5 (Punto 6): Dueño inexistente en método calificado
  expectProgram("Dueño inexistente en método calificado (Dragon.volar)",
    "Dragon.volar = method() : String {
     '  print(\"volando\")
     '}
     'method main { }", 1);

  // Caso 6 (Punto 6): Auto-herencia inválida
  expectProgram("Auto-herencia (object Ciclo extends Ciclo)",
    "object Ciclo extends Ciclo
     'method main { }", 1);

  println("=== Fin ===");
}