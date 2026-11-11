module Checker

import AST;
import analysis::typepal::Collector;
import analysis::typepal::TypePal;

// 1. Representación interna de los tipos de Objectilang en TypePal
data AType
  = aInt()
  | aBool()
  | aString()
  | aClass(str name)                
  | aGeneric(str name)              
  | aMethod(list[AType] formals, AType returnType) 
  ;

// 2. Roles semánticos (para distinguir clases, variables, métodos y genéricos)
data IdRole
  = classId()
  | methodId()
  | varId()
  | typeParamId()
  ;

// 3. Recolección (Collector) - Aquí definimos qué existe y qué se usa

// Módulo principal
void collect(current: prog(list[Definition] defs, MainMethod main, list[Definition] otherDefs), Collector c) {
    c.enterScope(current); 
    collect(defs, c);
    collect(main, c);
    collect(otherDefs, c);
    c.leaveScope(current);
}

// ==========================================
// TAREAS PERSONA A: Objetos y Tipos
// ==========================================

// Definición de Objetos
void collect(current: defObject(TypeId name, list[GenericParams] params, list[Extends] parent, list[Constructor] constructor, list[ObjectBody] body), Collector c) {
    c.define("<name>", classId(), current, defType(aClass(name)));
    
    c.enterScope(current); // Todo lo que esté adentro (métodos/campos) pertenece a esta clase
    collect(params, c);
    collect(parent, c);
    collect(constructor, c);
    collect(body, c);
    c.leaveScope(current);
}

// Parámetros Genéricos (+A, -In, +Out)
void collect(current: genericParameter(list[Variance] variance, TypeId name), Collector c) {
    c.define("<name>", typeParamId(), current, defType(aGeneric(name)));
}

// ==========================================
// PUNTO 6: Verificar que los elementos existan
// ==========================================

// Herencia: Asegurar que la clase de la que heredo existe
void collect(current: extends(TypeId superType), Collector c) {
    c.use(superType, {classId()}); // Exigimos que el nombre exista y que sea una clase
}

// Uso de Tipos (ej. List[Dog], input: In): Asegurar que el tipo existe
void collect(current: userType(TypeId name, list[TypeArgs] args), Collector c) {
    // Un tipo de usuario puede ser una clase existente (Dog) o un genérico (In, Out)
    c.use(name, {classId(), typeParamId()}); 
    collect(args, c);
}

// ==========================================
// TAREAS PERSONA A: Declaraciones y Métodos
// ==========================================

// Parámetros del constructor (val item: A)
void collect(current: paramDecl(Binding mode, Id name, Type paramType), Collector c) {
    c.define("<name>", varId(), current);
    collect(paramType, c);
}

// Declaraciones de variables (val max = ...)
void collect(current: declaration(Binding mode, Id name, list[Type] declaredType, Expression expr), Collector c) {
    c.define("<name>", varId(), current); 
    collect(declaredType, c);
    collect(expr, c); 
}

// Métodos miembros (override transform(...) ...)
void collect(current: memberMethod(list[Override] override, Id name, list[MethodParam] params, list[Type] returnType, MethodBody body), Collector c) {
    c.define("<name>", methodId(), current);
    
    c.enterScope(current); // El método abre un nuevo ámbito para sus parámetros
    collect(params, c);
    collect(returnType, c);
    collect(body, c);
    c.leaveScope(current);
}

// Parámetros de métodos (animal: Animal)
void collect(current: methodParam(Id name, Type paramType), Collector c) {
    c.define("<name>", varId(), current);
    collect(paramType, c);
}

// Método Main
void collect(current: mainMethod(Block body), Collector c) {
    c.enterScope(current);
    collect(body, c);
    c.leaveScope(current);
}

// ==========================================
// Utilidades de recolección
// ==========================================
void collect(list[value] elements, Collector c) {
    for (e <- elements) collect(e, c);
}

// Ignoramos nodos que aún no procesamos (como expresiones matemáticas que hará B)
void collect(value v, Collector c) { }

// Configuración y ejecución del Type Checker
TypePalConfig objectilangConfig() = tconfig(collect);
public TModel checkProgram(AST::Module p) = newTyping(p, objectilangConfig());