# Cambios a la gramática de Objectilang — Parte B (expresiones, literales y control de flujo)

Cambios respecto a la gramática del Proyecto 1. No se usó la solución de otro grupo.

## 1. Correcciones del Proyecto 1

| Observación | Cambio |
|---|---|
| `_`, espacio, tabulador y nueva línea no son parte del lenguaje | Se quitaron del alfabeto y del identificador. Los espacios y los comentarios (`#`) van en `layout`, no en la gramática. |
| No-terminales como barewords y terminales entre comillas | En Rascal los no-terminales son nombres capitalizados (`Expression`, `Literal`, `ForLoop`) y los terminales van entre comillas (`"if"`, `"**"`). |
| Identificador: minúscula inicial, luego letras, dígitos o guiones | `Id = [a-z] [a-zA-Z0-9\-]*`, sin las palabras reservadas (`\ Keywords`). |
| El elemento inicial debe ser un módulo | El símbolo inicial es `start syntax Module` (parte A). |

## 2. Cambios para que el lenguaje funcione en Rascal

- **Dos tipos de identificador.** Los ejemplos del enunciado nombran objetos y tipos con mayúscula (`Animal`, `List`, `In`), y un identificador solo con minúscula inicial no los deriva. Se separó `Id` (variables, métodos, parámetros) de `TypeId` (objetos, tipos, parámetros genéricos, con mayúscula inicial).
- **Palabra reservada faltante.** `then` no estaba entre las reservadas y se agregó.
- **Precedencia integrada.** Los niveles `expression_or`, `expression_and`, `expression_add`, etc. pasaron a un solo `Expression` con precedencia (`>`) y asociatividad (`left`, `right`, `non-assoc`). El orden de mayor a menor es: acceso a miembros y llamadas, `neg`, `**`, `* / %`, `+ -`, comparaciones, `and`, `or`, `if-then-else`.
- **`neg` y `**`.** En el Proyecto 1, `neg a ** b` se leía `neg (a ** b)`. Ahora `neg` liga más fuerte y se lee `(neg a) ** b`. Así `a ** neg b` sigue siendo válido.
- **Comparaciones no asociativas.** `a < b < c` es un error de sintaxis, igual que en el Proyecto 1 (`( op expr )?`).
- **Interpolación de strings.**
  - Se aceptan las dos formas que aparecen en los ejemplos: `$name` (Snippet 4) y `${expr}` (Snippet 1). La del Proyecto 1 solo cubría `${expr}`.
  - `$name` se conserva en el AST como `interpolatedName`, con sus nombres sucesivos en `StrTailSimple`.
  - La cadena se parte en trozos léxicos (`StrPlain`, `StrPre`, `StrMid`, `StrPost` y sus variantes simples) para que los espacios dentro del texto no se traten como layout. Se reemplazó la regla `string_char`, que no estaba definida.
- **`new` con o sin argumentos.** Se separó en dos producciones (`newObject` y `newObjectArgs`), ambas con `ObjectBody` opcional para el cuerpo anónimo del Snippet 3.
- **`for`.** Patrón simple (`i`) o en tupla (`(name, rating)`), con `<-`. Es una instrucción, no una expresión.

## 3. Decisiones y limitaciones

- **Paréntesis pegado a la llamada.** Como no hay terminador de instrucción, `print ("x")` (con espacio) se podía leer como `print` seguido de `("x")`. Se agregaron restricciones `!>> "("` en las variables, en el acceso a miembros y en `new`. El `(` de una llamada debe ir pegado al nombre.
- **Guiones en identificadores.** Los identificadores empiezan con una minúscula y continúan con letras, dígitos o guiones (`[a-z][a-zA-Z0-9\-]*`). Por eso `a-b` es un solo identificador, no una resta; los guiones bajos no forman parte del lenguaje.
- **`if-then-else`.** Es la expresión de menor precedencia: la rama `else` abarca todo lo que pueda (`if a then b else c + 1` es `if a then b else (c + 1)`). Puede usarse como operando derecho sin paréntesis (`1 + if a then b else c`).

## 4. AST

Cada alternativa de `Expression`, `Literal`, `StringLiteral` y `ForLoop` tiene su constructor, con el mismo nombre y la misma aridad que la etiqueta de la producción, para poder usar `implode`. Un no-terminal opcional se representa como `list[...]` de 0 o 1 elemento.

## 5. Pruebas

- Los 4 snippets del enunciado parsean sin ambigüedad.
- Precedencia, asociatividad y `implode` de expresiones, interpolaciones y bucles `for` (simples, en tupla y anidados).
- Las pruebas incluyen interpolación simple múltiple (`$name`), identificadores con guiones, `a-b` como un solo identificador y acceso a miembros con nombres en minúscula.
- También se prueba la precedencia de negación, potencia, aritmética, lógica y condicionales.
