module TestB

import IO;
import ParseTree;
import Lexical;
import SyntaxObjects;
import SyntaxExpr;
import AST;

// Intenta parsear + implode de una instrucción (prueba el for)
void inst(str src) {
  try {
    Tree tr = parse(#SyntaxExpr::Instruction, src);
    println("<src>\n   =\> <implode(#AST::Instruction, tr)>");
  } catch ParseError(loc l): println("<src>\n   =\> ERROR de parseo");
}

void main(int dummy = 0) {
  inst("for (i \<- xs) print(i)");
  inst("for ((name, rating) \<- ratings) print(\"Movie: $name, Rating: $rating\")");
  inst("for (x \<- xs) for (y \<- ys) print(x + y)");

  // Highlighting: categorías asignadas
  Tree t = parse(#start[Module], "method main {\n  val max = if a \> b then 10 else b # comentario\n  print(\"hola $max\")\n}");
  for (/a:appl(prod(_, _, {*_, \tag("category"(str cat))}), _) := t)
    println("  <cat>: <trim("<a>")>");
}
