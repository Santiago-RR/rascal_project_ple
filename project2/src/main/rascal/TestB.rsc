module TestB

import IO;
import ParseTree;
import Lexical;
import SyntaxObjects;
import SyntaxExpr;
import AST;
import String;

// Intenta parsear + implode de una instrucción (prueba el for)
void inst(str src) {
  try {
    Tree tr = parse(#SyntaxExpr::Instruction, src);
    println("<src>\n   =\> <implode(#AST::Instruction, tr)>");
  } catch ParseError(loc l): println("<src>\n   =\> ERROR de parseo");
}

void main(list[str] args=[]) {
  inst("for (i \<- xs) print(i)");
  inst("for ((name, rating) \<- ratings) print(\"Movie: $name, Rating: $rating\")");
  inst("for (x \<- xs) for (y \<- ys) print(x + y)");
  inst("for (item_1 \<- xs) print(\"item_1: $item_1\")");
  inst("for (x \<- xs) print(x-y)");
  inst("print(\"Resulting food type: ${resultantFood.getClass.getSimpleName}\")");
  inst("print(neg a ** b)");
  inst("print(a + b * c)");
  inst("print(a and b or c)");
  inst("print(if a then b else c + 1)");

  // Highlighting: categorías asignadas
  Tree t = parse(#start[Module], "method main {\n  val max = if a \> b then 10 else b // comentario\n  print(\"hola $max\")\n}");
  for (/a:appl(prod(_, _, {*_, \tag("category"(str cat))}), _) := t)
    println("  <cat>: <trim("<a>")>");
}
