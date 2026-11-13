# Cambios — Proyecto 3 de Objectilang

Documento de cambios para la tercera iteración del proyecto. Recoge las
correcciones a los errores señalados en la entrega anterior y la instalación de
TypePal como base para el sistema de tipos.

No se utilizó la solución de otro grupo: los cambios parten de la gramática
propia del Proyecto 2 (módulos en `project2/src/main/rascal`).

## 1. Correcciones de los errores señalados

En la retroalimentación del Proyecto 2 se marcaron cuatro errores. Todos tienen
su origen en que la especificación formal del Proyecto 1 **declaraba** los
operadores `->`, `=>` y la palabra reservada `in`, pero **ninguna regla de
producción los usaba**, y en que el `for` quedó incompleto. Se corrigieron así:

| Error señalado | Corrección |
|---|---|
| Faltan los operadores `->` y `=>` | Se añadieron como alternativas de `Expression` en `SyntaxExpr.rsc`. |
| Falta el operador `in` | Se añadió como alternativa a `<-` en el `for`. |
| No hay soporte de rangos para el `for` | El origen del `for` es una `Expression`, que ahora incluye el rango `->`. |
| El cuerpo del `for` está mal limitado | El cuerpo pasó de una sola `Instruction` a un `Block` delimitado con `{ ... }`. |

### 1.1. Operadores `->` y `=>` (`SyntaxExpr.rsc`)

Se agregaron dos niveles nuevos de precedencia a la regla `Expression`, por
debajo de `or` y por encima de `if-then-else`:

```rascal
> non-assoc range: Expression from "-\>" Expression to
> right lambda: IterationPattern param "=\>" Expression result
```

- **`->` (rango).** `1 -> 10` produce la secuencia de enteros entre los dos
  extremos. Es **no asociativo** (`1 -> 2 -> 3` es un error de sintaxis), igual
  que las comparaciones.
- **`=>` (lambda / transformación).** `x => x + 1` asocia un patrón de iteración
  con una expresión resultado. Es **asociativo a la derecha** para poder
  encadenarse. El lado izquierdo reutiliza `IterationPattern`, de modo que admite
  tanto un nombre simple (`x => ...`) como una tupla (`(a, b) => ...`).

> Nota de interpretación: la especificación del Proyecto 1 solo listaba `->` y
> `=>` como símbolos operadores, sin asociarlos a una construcción. Se les dio la
> semántica convencional (rango e intervalo / lambda), que además encaja con el
> error de «soporte de rangos para el `for`».

### 1.2. Operador `in` y el `for` (`SyntaxExpr.rsc`)

El `for` se reescribió para admitir las dos formas de origen de la iteración
(`<-` y `in`) y para delimitar su cuerpo con un bloque:

```rascal
syntax ForLoop
  = forLoop: "for" "(" IterationPattern pattern "\<-" Expression source ")" Block body
  | forLoop: "for" "(" IterationPattern pattern "in" Expression source ")" Block body
  ;
```

- **`in` como alternativa a `<-`.** `for (x in coll) { ... }` y
  `for (x <- coll) { ... }` son equivalentes.
- **Rangos en el `for`.** Como el origen es una `Expression`, el rango queda
  cubierto automáticamente: `for (i <- 1 -> 10) { ... }` y
  `for (i in 0 -> n) { ... }` son válidos.
- **Cuerpo bien delimitado.** El cuerpo pasó de `Instruction body` a
  `Block body`. Al exigir `{ ... }` se elimina la ambigüedad sobre dónde termina
  el `for` y dónde empieza la siguiente instrucción.

### 1.3. AST (`AST.rsc`)

Se ajustó el AST para reflejar las nuevas producciones, conservando el nombre y
la aridad de cada etiqueta para que `implode` siga funcionando:

- Nuevos constructores de `Expression`:
  - `range(Expression from, Expression to)`
  - `lambda(IterationPattern param, Expression result)`
- Se cambió el cuerpo del bucle:
  - antes: `data ForLoop = forLoop(IterationPattern pattern, Expression source, Instruction body);`
  - ahora: `data ForLoop = forLoop(IterationPattern pattern, Expression source, Block body);`

## 2. Instalación de TypePal (`pom.xml`)

Se agregó TypePal como dependencia Maven, base para el sistema de tipos
(puntos 3, 5 y 6 del enunciado):

```xml
<dependency>
  <groupId>org.rascalmpl</groupId>
  <artifactId>typepal</artifactId>
  <version>0.17.3</version>
</dependency>
```

- Se eligió la versión **0.17.3** (la estable más reciente en el repositorio
  `usethesource`).
- Su `pom` declara dependencia de **Rascal 0.43.0**, exactamente la versión que
  ya usa el proyecto, por lo que no hay conflicto de versiones.
- El repositorio `usethesource` ya estaba declarado en `pom.xml`, así que no hizo
  falta añadir ninguna fuente nueva.

## 3. Archivos modificados

- `project2/src/main/rascal/SyntaxExpr.rsc` — operadores `->` y `=>`, `in` en el
  `for`, cuerpo del `for` como `Block`.
- `project2/src/main/rascal/AST.rsc` — constructores `range` y `lambda`, cuerpo
  `Block` en `ForLoop`.
- `project2/src/main/rascal/TestB.rsc` — pruebas de `in`, rangos, lambdas y `for`
  con bloque.
- `project2/src/main/rascal/TestSnippets.rsc` — Snippet 4 adaptado al `for` con
  bloque.
- `project2/pom.xml` — dependencia de TypePal.

## 4. Pruebas realizadas

- **Compilación.** `mvn compile` termina en `BUILD SUCCESS`, sin errores ni
  advertencias en los módulos `.rsc`. Maven descargó `typepal-0.17.3.jar` al
  repositorio local.
- **`TestB` (instrucciones y expresiones).** Las 16 instrucciones parsean sin
  error y su `implode` produce el AST esperado. Ejemplos verificados:
  - `for (i in xs) { print(i) }`
    → `control(forLoop(single("i"), variable("xs"), block([...])))`
  - `for (i <- 1 -> 10) { print(i) }`
    → `forLoop(single("i"), range(intLit("1"), intLit("10")), block([...]))`
  - `print(xs => x + 1)`
    → `lambda(single("xs"), add(variable("x"), intLit("1")))`
- **`TestSnippets` (snippets del enunciado).** Los Snippets 1 a 4 dan `OK`,
  incluido el Snippet 4 con el `for` en formato bloque. La prueba de
  `print ("con espacio")` sigue fallando con ambigüedad **a propósito**, tal como
  estaba previsto.

## 5. Tipo `Char` y literales tipados (punto 4 — parte B)

- Se agregó `Char` como tipo primitivo: palabra reservada en `Lexical.rsc`,
  alternativa `character` de `PrimitiveType` en `SyntaxObjects.rsc` y constructor
  `character()` en `AST.rsc`.
- Se agregó el literal de carácter `charLit` con un léxico `CharLit`: un carácter
  entre comillas simples, con escapes (`'a'`, `'\n'`). El cuerpo (`CharChar`) es
  un carácter que no sea comilla simple ni backslash, o un escape.
- Representación interna: `implode` guarda el texto crudo con las comillas simples
  incluidas (p. ej. `charLit("'a'")`); el checker y el intérprete quitan las
  comillas y resuelven el escape.
- Archivos: `Lexical.rsc`, `SyntaxObjects.rsc`, `SyntaxExpr.rsc`, `AST.rsc`,
  `TestB.rsc` (pruebas de `'a'`, `'\n'` y `val c: Char = 'x'`).

## 6. Chequeo de tipos de expresiones y control de flujo (puntos 4 y 5 — parte B)

Las reglas de tipo de la parte B viven en un módulo propio, `CheckerB.rsc`, sobre
el árbol de sintaxis concreta (TypePal 0.17.3 trabaja sobre el `Tree` del parse,
no sobre el AST). Cubren:

- Literales tipados (Integer, Boolean, Char, String).
- Aritmética (`+ - * / % **`): operandos Integer, resultado Integer.
- Comparaciones (`< > <= >= <> =`): operandos del mismo tipo, resultado Boolean.
- Lógica (`and`, `or`, `neg`): operandos Boolean, resultado Boolean.
- `if-then-else`: condición Boolean y ramas del mismo tipo.
- Interpolación y concatenación de strings (`$name` y `${expr}`): resultado
  String, con chequeo de las subexpresiones interpoladas.
- Rango (`1 -> 10`): extremos Integer.
- `for` (con `<-` y con `in`), `Block` e `IterationPattern`: definen las variables
  de iteración y recorren el cuerpo.
- Uso de variables (deben existir) y declaraciones `val`/`var` (definen la
  variable y, si hay anotación de tipo, exigen que la expresión coincida).

Frontera con A: acceso a miembros, llamadas a métodos, `new` y `lambda` dependen
del modelo de objetos de A; sus reglas quedan con tipo neutro (`bUnknown`) y
marcadas con «INTEGRACIÓN CON A».

Archivos: `CheckerB.rsc`, `TestCheckerB.rsc` (27 casos de chequeo).

## 7. Ejecución: intérprete sobre el AST (punto 2 — parte B)

- El punto 2 se resolvió como un intérprete sobre el AST en Rascal: `Eval.rsc`.
- `data Value` representa los valores en ejecución (entero, booleano, carácter,
  string, lista para los rangos, tupla, objeto y void).
- Evalúa literales (resolviendo escapes de `Char` y strings), aritmética,
  comparaciones, lógica con cortocircuito, `neg`, `**`, paréntesis, condicional,
  rango (lista de enteros), interpolación, el `for` (patrón simple y en tupla) y
  `print`/`println` en consola.
- Archivos: `Eval.rsc`, `TestEval.rsc`.

## 8. Programa de consola end-to-end (punto 2 — parte B)

- `Main.rsc` implementa el flujo completo: leer un `.ol`, parsear, chequear tipos;
  si hay errores, reportarlos con su ubicación y cancelar; si no, `implode` y
  ejecutar, mostrando la salida en consola. Maneja archivo inexistente, extensión
  incorrecta y errores de sintaxis.
- Archivos de prueba en `project2/examples/`: `expresiones.ol` (ejecuta end-to-end),
  `error_tipo.ol` (se detiene en el chequeo) y los cuatro snippets del enunciado
  (`snippet1..4.ol`).
- Archivos: `Main.rsc`, `TestOl.rsc`, `examples/*.ol`.

## 9. Correcciones tras la integración A + B

Al integrar la parte A (commit «integración parte a con b») con la parte B y
correr el pipeline completo (parseo → TypePal → `implode` → ejecución)
aparecieron fallos que se corrigieron. Todos se manifestaban como `CallFailed` en
tiempo de ejecución, no como errores de compilación: por eso `mvn compile` daba
`BUILD SUCCESS` aunque los snippets no corrieran.

1. **`NewArgs` / `NewArguments` (`AST.rsc`, `Eval.rsc`).** La gramática define la
   producción `NewArgs` (etiqueta `newArgs`), pero el AST tenía el tipo
   `NewArguments` (constructor `newArguments`). Como `implode` exige que el nombre
   y la aridad del AST coincidan con la producción, `new List(new Dog)` (Snippet 1)
   fallaba. Se renombró el AST a `NewArgs` / `newArgs` y se actualizó `Eval.rsc`.

2. **`Implode.rsc` no importaba `Lexical`.** Al reificar la gramática en
   `parseModule`, el módulo necesita ver el `layout Layout` de `Lexical.rsc`. Sin
   el import, fallaba con «Undeclared non-terminal: $l_Layout». Se añadió
   `import Lexical;`.

3. **Reglas `collect` que delegaban en funciones auxiliares (`CheckerB.rsc`).** La
   aritmética y las comparaciones delegaban su cuerpo en auxiliares que recibían
   `Tree current`; TypePal no registra así una regla de sintaxis concreta, y
   fallaba con `CallFailed`. Se escribió la lógica de cada operador en línea
   dentro de su propia regla.

4. **Reglas `collect` faltantes para `Block` e `IterationPattern`
   (`CheckerB.rsc`).** Sin la regla de `Block`, TypePal no recorría el cuerpo de
   `main` ni de los `for`. Los patrones del `for` se manejaban con un `switch`
   auxiliar que causaba `CallFailed`. Se añadió la regla de `Block` y reglas
   `collect` directas sobre `IterationPattern` (forma simple y en tupla).

5. **`TestOl.rsc`: `extend` en vez de `import`.** El módulo que corre
   `collectAndSolve` debe incorporar las reglas de ambos checkers con `extend`;
   con `import`, las reglas de `Checker` (A) y `CheckerB` (B) no se fusionan en el
   espacio de sobrecarga que ve TypePal y toda expresión falla con `CallFailed`.

### Estado de los snippets tras las correcciones

- **Snippet 2**: pasa las tres fases (parseo, chequeo y ejecución).
- **Snippet 4**: parsea y el chequeo lo rechaza por variables no declaradas
  (`a`, `b`, `ratings`), que es lo correcto porque el fragmento del enunciado está
  incompleto. El `for` en tupla y la interpolación se procesan sin error.
- **Snippets 1 y 3**: siguen fallando con `CallFailed` sobre `TypeArgs` (los tipos
  genéricos `List[Dog]` y `Transformer[Animal, DogFood]`). Pertenece a la regla de
  `UserType` / `TypeArgs` de la parte A (le falta una regla `collect` para
  `TypeArgs`, análoga a la añadida para `IterationPattern`). Queda pendiente de A.

## 10. Nota sobre artefactos de compilación (`project2/target/`)

La carpeta `project2/target/` (archivos `.tpl` compilados por Rascal) quedó
versionada en una entrega anterior, antes de existir el `.gitignore`. El
intérprete de Rascal carga esos `.tpl` en caché por encima del fuente, lo que
puede ocultar cambios recientes. Conviene recompilar desde cero (borrando
`target/`) tras cada cambio y sacar la carpeta del control de versiones con
`git rm -r --cached project2/target`.

## 11. Archivos agregados o modificados (parte B y correcciones)

- `Lexical.rsc`, `SyntaxObjects.rsc`, `SyntaxExpr.rsc`, `AST.rsc` — tipo y literal
  `Char`; renombre `NewArgs`.
- `Implode.rsc` — `import Lexical`.
- `CheckerB.rsc` — reglas de tipo de expresiones y control de flujo (nuevo).
- `Eval.rsc` — intérprete sobre el AST (nuevo).
- `Main.rsc` — programa de consola end-to-end.
- `TestCheckerB.rsc`, `TestEval.rsc`, `TestOl.rsc` — pruebas.
- `examples/*.ol` — programas de prueba, incluidos los cuatro snippets.
