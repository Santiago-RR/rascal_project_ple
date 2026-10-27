module TestA

import IO;
import ParseTree;
import Lexical;
import SyntaxObjects;
import SyntaxExpr;
import AST;

void testObject(str src) {
  try {
    Tree tr = parse(#SyntaxObjects::DefObject, src);
    println("OBJECT OK: <src>");
    try {
      println("  =\> <implode(#AST::DefObject, tr)>");
    } catch e: {
      println("  - ERROR IMPLODE: <e>");
    }
  } catch e: {
    println("ERROR Sintáctico en DefObject: <src>");
  }
}

void testMethod(str src) {
  try {
    Tree tr = parse(#SyntaxObjects::DefMethod, src);
    println("METHOD OK: <src>");
    try {
      println("  =\> <implode(#AST::DefMethod, tr)>");
    } catch e: {
      println("  - ERROR IMPLODE: <e>");
    }
  } catch e: {
    println("ERROR Sintáctico en DefMethod: <src>");
  }
}

void testModule(str src) {
  try {
    Tree tr = parse(#start[Module], src);
    println("MODULE OK");
    try {
      println("  =\> <implode(#AST::Module, tr)>");
    } catch e: {
      println("  - ERROR IMPLODE: <e>");
    }
  } catch e: {
    println("ERROR Sintáctico en Module");
  }
}

void main(list[str] args=[]) {
  println("=== Pruebas Persona A: Estructura, Objetos y Métodos ===");

  println("\n--- 1. Objetos, Herencia y Constructores ---");
  testObject("object Animal");
  testObject("object Dog extends Animal");
  testObject("object List[+A](val item: A)");
  testObject("object Transformer[-In, +Out]");

  println("\n--- 2. Métodos Calificados y Overrides ---");
  testMethod("Cat.talk = method() : String { print(\"Cats meows\") }");
  testMethod("Transform.transform = method(input: In): Out");
  testMethod("override transform(animal: Animal): DogFood = { new DogFood }");

  println("\n--- 3. Módulo Estructural Completo ---");
  testModule("object Animal\nobject Dog extends Animal\nmethod main { val d = new Dog }");
}