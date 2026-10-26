module Implode

import ParseTree;
import AST;
import SyntaxObjects;
import SyntaxExpr;

// Punto único para transformar texto fuente en el AST del proyecto.
// Las excepciones ParseError y Ambiguity se propagan al llamador.
public AST::Module parseModule(str source) =
  implode(#AST::Module, parse(#start[Module], source));

public AST::Instruction parseInstruction(str source) =
  implode(#AST::Instruction, parse(#Instruction, source));
