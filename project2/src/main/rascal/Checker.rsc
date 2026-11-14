module Checker

import ParseTree;
import SyntaxObjects;
import SyntaxExpr;
import Lexical;
import CheckerB;
extend analysis::typepal::TypePal;

// 1. Representación interna de Tipos para la Parte A
data AType
  = aClass(str name)
  | aGeneric(str name)
  | aMethod(list[AType] formals, AType returnType)
  | aUnknown()
  ;

str prettyAType(aClass(str n)) = n;
str prettyAType(aGeneric(str n)) = n;
str prettyAType(aMethod(fs, ret)) = "(<fs>) -\> <ret>";
str prettyAType(aUnknown()) = "?";

// 2. Roles semánticos (Punto 6)
data IdRole = classId() | methodId() | varId() | typeParamId();

// Auxiliar para recorrer no-terminales opcionales (X?) sin ambigüedad sintáctica
void collectOpt(Tree optTree, Collector c) {
  if (appl(regular(opt(_)), [Tree child]) := optTree) {
    collect(child, c);
  }
}

// 3. Módulo y definiciones de nivel superior
void collect(current: (Module) `<Definition* defs> <MainMethod main> <Definition* otherDefs>`, Collector c) {
  c.enterScope(current);
  for (d <- defs) collect(d, c);
  collect(main, c);
  for (od <- otherDefs) collect(od, c);
  c.leaveScope(current);
}

void collect(current: (Definition) `<DefObject obj>`, Collector c) {
  collect(obj, c);
}

void collect(current: (Definition) `<DefMethod m>`, Collector c) {
  collect(m, c);
}

// 4. Objetos, genéricos, herencia, constructor y cuerpo de objeto


void collect(current: (GenericParams) `[ <{GenericParameter ","}+ params> ]`, Collector c) {
  for (p <- params) collect(p, c);
}

void collect(current: (GenericParameter) `<Variance? variance> <TypeId name>`, Collector c) {
  c.define("<name>", typeParamId(), current, defType(aGeneric("<name>")));
}

// PUNTO 6: Verificar que la superclase y los tipos usados existan
void collect(current: (Extends) `extends <TypeId superType>`, Collector c) {
  c.use(superType, {classId()});
}

void collect(current: (Constructor) `( <{ParamDecl ","}* params> )`, Collector c) {
  for (p <- params) collect(p, c);
}

void collect(current: (ParamDecl) `<Binding mode> <Id name> : <Type paramType>`, Collector c) {
  c.define("<name>", variableId(), name, defType(paramType));
  collect(paramType, c);
}

void collect(current: (ObjectBody) `{ <Member* members> }`, Collector c) {
  for (m <- members) collect(m, c);
}

void collect(current: (Member) `<Declaration f>`, Collector c) {
  collect(f, c);
}

void collect(current: (Member) `<DefMethod m>`, Collector c) {
  collect(m, c);
}

// 5. Tipos de usuario, argumentos genéricos y argumentos de constructor
void collect(current: (Type) `<UserType u>`, Collector c) {
  c.fact(current, u);
  collect(u, c);
}

void collect(current: (UserType) `<TypeId name> <TypeArgs? args>`, Collector c) {
  c.use(name, {classId(), typeParamId()});
  c.fact(current, bUnknown());
  collectOpt(args, c);
}

void collect(current: (TypeArgs) `[ <{Type ","}+ args> ]`, Collector c) {
  for (a <- args) collect(a, c);
}

void collect(current: (NewArgs) `( <{Expression ","}* args> )`, Collector c) {
  for (a <- args) collect(a, c);
}

// 6. Métodos y cuerpos de método
void collect(current: (DefMethod) `<Override? override> <Id name> ( <{MethodParam ","}* params> ) : <Type returnType> <MethodBody body>`, Collector c) {
  c.define("<name>", methodId(), current, defType(aUnknown()));
  c.enterScope(current);
  for (p <- params) collect(p, c);
  collect(returnType, c);
  collect(body, c);
  c.leaveScope(current);
}

void collect(current: (DefMethod) `<Override? override> <Id name> ( <{MethodParam ","}* params> ) <MethodBody body>`, Collector c) {
  c.define("<name>", methodId(), current, defType(aUnknown()));
  c.enterScope(current);
  for (p <- params) collect(p, c);
  collect(body, c);
  c.leaveScope(current);
}

void collect(current: (DefMethod) `<Override? override> <Id name> = method ( <{MethodParam ","}* params> ) : <Type returnType> <MethodBody body>`, Collector c) {
  c.define("<name>", methodId(), current, defType(aUnknown()));
  c.enterScope(current);
  for (p <- params) collect(p, c);
  collect(returnType, c);
  collect(body, c);
  c.leaveScope(current);
}

void collect(current: (DefMethod) `<Override? override> <Id name> = method ( <{MethodParam ","}* params> ) <MethodBody body>`, Collector c) {
  c.define("<name>", methodId(), current, defType(aUnknown()));
  c.enterScope(current);
  for (p <- params) collect(p, c);
  collect(body, c);
  c.leaveScope(current);
}


void collect(current: (MethodBody) `<Block blockBody>`, Collector c) {
  collect(blockBody, c);
}

void collect(current: (MethodBody) `= <Block blockBody>`, Collector c) {
  collect(blockBody, c);
}

void collect(current: (MethodBody) `= <Expression exprBody>`, Collector c) {
  collect(exprBody, c);
}

void collect(current: (MethodParam) `<Id name> : <Type paramType>`, Collector c) {
  c.define("<name>", variableId(), name, defType(paramType));
  collect(paramType, c);
}

// 7. Main
void collect(current: (MainMethod) `method main <Block body>`, Collector c) {
  c.enterScope(current);
  collect(body, c);
  c.leaveScope(current);
}

// En DefObject (verifica que una clase no herede de sí misma):
void collect(current: (DefObject) `object <TypeId name> <GenericParams? params> <Extends? parent> <Constructor? constructor> <ObjectBody? body>`, Collector c) {
  c.define("<name>", classId(), current, defType(aClass("<name>")));
  if ((Extends?) `extends <TypeId superType>` := parent && "<name>" == "<superType>") {
    c.report(error(parent, "El objeto `<name>` no puede heredar de sí mismo"));
  }
  c.enterScope(current);
  collectOpt(params, c);
  collectOpt(parent, c);
  collectOpt(constructor, c);
  collectOpt(body, c);
  c.leaveScope(current);
}

// En qualifiedMethod (verifica que el dueño `owner` exista):
void collect(current: (DefMethod) `<TypeId owner> . <Id name> = method ( <{MethodParam ","}* params> ) : <Type returnType> <MethodBody? qualifiedBody>`, Collector c) {
  c.use(owner, {classId()});
  c.define("<name>", methodId(), current, defType(aUnknown()));
  collectOpt(qualifiedBody, c);
}

void collect(current: (DefMethod) `<TypeId owner> . <Id name> = method ( <{MethodParam ","}* params> ) <MethodBody? qualifiedBody>`, Collector c) {
  c.use(owner, {classId()});
  c.define("<name>", methodId(), current, defType(aUnknown()));
  collectOpt(qualifiedBody, c);
}