module Checker

import ParseTree;
import SyntaxObjects;
import Lexical;
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

// 3. Collector principal
void collect(current: (Module) `<Definition* defs> <MainMethod main> <Definition* otherDefs>`, Collector c) {
    c.enterScope(current); 
    for (arg <- current.args) collect(arg, c);
    c.leaveScope(current);
}

// Objetos y Varianza
void collect(current: (DefObject) `object <TypeId name> <GenericParams? params> <Extends? parent> <Constructor? constructor> <ObjectBody? body>`, Collector c) {
    c.define("<name>", classId(), current, defType(aClass("<name>")));
    c.enterScope(current); 
    
    for (arg <- current.args) collect(arg, c);
    c.leaveScope(current);
}

// Parámetros Genéricos
void collect(current: (GenericParameter) `<Variance? variance> <TypeId name>`, Collector c) {
    c.define("<name>", typeParamId(), current, defType(aGeneric("<name>")));
}

// PUNTO 6: Verificación de Existencia de Herencia y Tipos
void collect(current: (Extends) `extends <TypeId superType>`, Collector c) {
    c.use(superType, {classId()}); 
}

void collect(current: (UserType) `<TypeId name> <TypeArgs? args>`, Collector c) {
    c.use(name, {classId(), typeParamId()}); 
    for (arg <- current.args) collect(arg, c);
}

// ======================================================================
// Métodos (Múltiples reglas para manejar la sintaxis opcional ":" Type)
// ======================================================================

// 1. memberMethod CON tipo de retorno
void collect(current: (DefMethod) `<Override? override> <Id name> ( <{MethodParam ","}* params> ) : <Type returnType> <MethodBody body>`, Collector c) {
    c.define("<name>", methodId(), current, defType(aUnknown()));
    c.enterScope(current); 
    for (arg <- current.args) collect(arg, c);
    c.leaveScope(current);
}

// 2. memberMethod SIN tipo de retorno
void collect(current: (DefMethod) `<Override? override> <Id name> ( <{MethodParam ","}* params> ) <MethodBody body>`, Collector c) {
    c.define("<name>", methodId(), current, defType(aUnknown()));
    c.enterScope(current); 
    for (arg <- current.args) collect(arg, c);
    c.leaveScope(current);
}

// 3. memberMethod CON igual y CON tipo de retorno
void collect(current: (DefMethod) `<Override? override> <Id name> = method ( <{MethodParam ","}* params> ) : <Type returnType> <MethodBody body>`, Collector c) {
    c.define("<name>", methodId(), current, defType(aUnknown()));
    c.enterScope(current); 
    for (arg <- current.args) collect(arg, c);
    c.leaveScope(current);
}

// 4. memberMethod CON igual y SIN tipo de retorno
void collect(current: (DefMethod) `<Override? override> <Id name> = method ( <{MethodParam ","}* params> ) <MethodBody body>`, Collector c) {
    c.define("<name>", methodId(), current, defType(aUnknown()));
    c.enterScope(current); 
    for (arg <- current.args) collect(arg, c);
    c.leaveScope(current);
}

// 5. qualifiedMethod CON tipo
void collect(current: (DefMethod) `<TypeId owner> . <Id name> = method ( <{MethodParam ","}* params> ) : <Type returnType> <MethodBody? qualifiedBody>`, Collector c) {
    c.define("<name>", methodId(), current, defType(aUnknown()));
    c.enterScope(current); 
    for (arg <- current.args) collect(arg, c);
    c.leaveScope(current);
}

// 6. qualifiedMethod SIN tipo
void collect(current: (DefMethod) `<TypeId owner> . <Id name> = method ( <{MethodParam ","}* params> ) <MethodBody? qualifiedBody>`, Collector c) {
    c.define("<name>", methodId(), current, defType(aUnknown()));
    c.enterScope(current); 
    for (arg <- current.args) collect(arg, c);
    c.leaveScope(current);
}

// ======================================================================

// Parámetros de método
void collect(current: (MethodParam) `<Id name> : <Type paramType>`, Collector c) {
    c.define("<name>", varId(), current, defType(aUnknown()));
    c.use(paramType, {classId(), typeParamId()});
    for (arg <- current.args) collect(arg, c);
}

// Variables en Objetos y Constructores
void collect(current: (ParamDecl) `<Binding mode> <Id name> : <Type paramType>`, Collector c) {
    c.define("<name>", varId(), current, defType(aUnknown()));
    for (arg <- current.args) collect(arg, c);
}

// Main
void collect(current: (MainMethod) `method main <Block body>`, Collector c) {
    c.enterScope(current);
    for (arg <- current.args) collect(arg, c);
    c.leaveScope(current);
}