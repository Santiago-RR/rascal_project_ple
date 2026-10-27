module TestSnippets

import IO;
import ParseTree;
import Lexical;
import SyntaxObjects;
import SyntaxExpr;

str s1 = "object Animal
object Dog extends Animal
object Cat extends Animal

object List[+A](val item: A)

method main {
  val listOfDogs: List[Dog] = new List(new Dog)

  val listOfAnimals: List[Animal] = listOfDogs

  print(\"Print the line of animal dogs: ${listOfAnimals.item}\")
}";

str s2 = "Cat.talk = method() : String {
  print(\"Cats meows\")
}
method main { }";

str s3 = "object Animal
object Dog extends Animal
object Puppy extends Dog

object Food
object DogFood extends Food

object Transformer[-In, +Out]
Transform.transform = method(input: In): Out

method main {
  val animalFeeder: Transformer[Animal, DogFood] = new Transformer[Animal, DogFood] {
    override transform(animal: Animal): DogFood = {
      println(\"Preparing specialized food for an animal...\")
      new DogFood
    }
  }

  // Contravariance (-In): Animal is a supertype of Puppy (Accepts broader input)
  // Covariance (+Out): DogFood is a subtype of Food (Returns narrower output)
  val puppyFeeder: Transformer[Puppy, Food] = animalFeeder

  val myPuppy = new Puppy
  val resultantFood: Food = puppyFeeder.transform(myPuppy)

  print(\"Resulting food type: ${resultantFood.getClass.getSimpleName}\")
}";

str s4 = "method main {
  val max = if a \> b then a else b
  for ((name, rating) \<- ratings) print(\"Movie: $name, Rating: $rating\")
}";

str s5 = "method main {
  print (\"con espacio\")
}";

// Parsea; informa OK, error de sintaxis o ambigüedad
void check(str name, str src) {
  try {
    parse(#start[Module], src);
    println("<name>: OK");
  } catch e:
    println("<name>: ERROR de parseo (<e>)");
}

void main(list[str] args=[]) {
  check("Snippet 1", s1);
  check("Snippet 2", s2);
  check("Snippet 3", s3);
  check("Snippet 4", s4);
  check("Llamada con espacio antes del paréntesis (esta debera fallar)", s5);
}
