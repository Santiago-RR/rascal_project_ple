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
  // for con "\<-" y cuerpo delimitado por bloque
  inst("for (i \<- xs) { print(i) }");
  inst("for ((name, rating) \<- ratings) { print(\"Movie: $name, Rating: $rating\") }");
  inst("for (x \<- xs) { for (y \<- ys) { print(x + y) } }");
  inst("for (item-1 \<- xs) { print(\"item-1: $item-1\") }");
  inst("for (x \<- xs) { print(x-y) }");
  // for con "in" como alternativa a "\<-"
  inst("for (i in xs) { print(i) }");
  // for con rango usando el operador "-\>"
  inst("for (i \<- 1 -\> 10) { print(i) }");
  inst("for (i in 0 -\> n) { print(i) }");
  // operador de rango y lambda como expresiones
  inst("print(1 -\> 10)");
  inst("print(xs =\> x + 1)");
  inst("print((a, b) =\> a + b)");
  inst("print(\"Resulting food type: ${resultantFood.getClass.getSimpleName}\")");
  inst("print(neg a ** b)");
  inst("print(a + b * c)");
  inst("print(a and b or c)");
  inst("print(if a then b else c + 1)");

  // Literal de carácter (Tarea 1): 'a', un escape, y declaración con tipo Char
  inst("print(\'a\')");
  inst("print(\'\\n\')");
  inst("val c: Char = \'x\'");

  // Highlighting: categorías asignadas
  Tree t = parse(#start[Module], "method main {\n  val max = if a \> b then 10 else b // comentario\n  print(\"hola $max\")\n}");
  for (/a:appl(prod(_, _, {*_, \tag("category"(str cat))}), _) := t)
    println("  <cat>: <trim("<a>")>");
}
