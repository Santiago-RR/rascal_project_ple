# Cambios a la gramática de Objectilang - Parte A

No se utilizó la solución de otro grupo.

## Correcciones del Proyecto 1

- `Module` se conserva como el símbolo inicial y contiene exactamente un `method main`.
- Los nombres de objetos, tipos y parámetros genéricos usan `TypeId`; variables,
  métodos y parámetros usan `Id`.
- El guion bajo, los espacios, tabuladores y saltos de línea no son símbolos del
  lenguaje. Los últimos tres pertenecen únicamente a `Layout` en `Lexical.rsc`.
- Las palabras reservadas se excluyen de `Id` y `TypeId`.
- Se mantienen los no terminales con mayúscula y los nombres de datos del AST con
  los mismos nombres de sus producciones.

## Estructura agregada

- `Definition` permite objetos y definiciones de métodos antes o después de `main`.
- `DefObject` soporta herencia, parámetros genéricos con `+` y `-`, constructores
  y un `ObjectBody` opcional.
- `ObjectBody` y `Block` son distintos: el primero contiene campos y métodos; el
  segundo contiene declaraciones, expresiones y control de flujo. Esto permite el
  objeto anónimo de `new Transformer[...] { override transform(...) ... }`.
- Se soportan tanto `Cat.talk = method() : String { ... }` como
  `override transform(animal: Animal): DogFood = { ... }`. Una definición
  calificada puede ser una firma sin cuerpo, como `Transform.transform = method(input: In): Out`.
- Las declaraciones y parámetros usan correctamente `Id` para el nombre, por lo
  que `val item: A` y `val listOfDogs: List[Dog] = ...` son válidos.

## AST e implosión

- `AST.rsc` ahora refleja la etiqueta, aridad y opcionalidad de cada producción.
  Los opcionales se representan como `list[...]` de tamaño cero o uno.
- `Implode.rsc` centraliza `parseModule` y `parseInstruction` mediante
  `implode`, para que las pruebas no repitan la conversión de árbol concreto a AST.

## Pruebas realizadas

- La compilación con Maven/Rascal finaliza sin errores.
- Los Snippets 1, 2 y 4 parsean. El Snippet 3 requirió aceptar firmas calificadas
  sin cuerpo y cuerpos de objeto en expresiones `new`; ambas correcciones quedaron
  incorporadas.
- Pendiente de la integración con la parte B: su prueba `print ("con espacio")`
  reporta ambigüedad. La regla de llamadas y la separación de instrucciones deben
  acordarse entre ambos integrantes.
