module SyntaxObjects

import SyntaxExpr;
import Lexical;

// El programa siempre tiene exactamente un punto de entrada. Las definiciones
// pueden aparecer antes o después de main, como en los ejemplos del enunciado.
start syntax Module = prog: Definition* defs MainMethod main Definition* otherDefs;

syntax Definition
  = objectDef: DefObject
  | methodDef: DefMethod
  ;

syntax MainMethod = mainMethod: "method" "main" Block body;

// Objetos, herencia y parámetros de tipo
syntax DefObject = defObject: "object" TypeId name GenericParams? params Extends? parent Constructor? constructor ObjectBody? body;

syntax GenericParams = genericParams: "[" {GenericParameter ","}+ params "]";
syntax GenericParameter = genericParameter: Variance? variance TypeId name;

syntax Variance
  = plus: "+"
  | minus: "-"
  ;

syntax Extends = extends: "extends" TypeId superType;
syntax Constructor = constructor: "(" {ParamDecl ","}* params ")";

// Un cuerpo de objeto contiene miembros; un Block contiene instrucciones.
// Mantenerlos separados evita que un método se confunda con una instrucción.
syntax ObjectBody = objectBody: "{" Member* members "}";

syntax Member
  = field: Declaration
  | method: DefMethod
  ;

// Forma calificada del Snippet 2: Cat.talk = method() : String { ... }
// Forma miembro del Snippet 3: override transform(animal: Animal): DogFood = { ... }
syntax DefMethod
  = qualifiedMethod: TypeId owner "." Id name "=" "method" "(" {MethodParam ","}* params ")" (":" Type)? returnType MethodBody? qualifiedBody
  | memberMethod: Override? override Id name "(" {MethodParam ","}* params ")" (":" Type)? returnType MethodBody body
  | memberMethod: Override? override Id name "=" "method" "(" {MethodParam ","}* params ")" (":" Type)? returnType MethodBody body
  ;

syntax Override = override: "override";
syntax MethodParam = methodParam: Id name ":" Type paramType;

syntax MethodBody
  = bodyBlock: Block blockBody
  | bodyBlock: "=" Block blockBody
  | bodyExpression: "=" Expression exprBody
  ;
// Los tipos de usuario y los nombres de objetos usan TypeId; las variables y
// parámetros usan Id. Así List[Dog] y val item: A son ambos válidos.
syntax Type
  = primitive: PrimitiveType
  | user: UserType
  ;

syntax PrimitiveType
  = string: "String"
  | integer: "Integer"
  | boolean: "Boolean"
  ;

syntax UserType = userType: TypeId name TypeArgs? args;
syntax TypeArgs = typeArgs: "[" {Type ","}+ args "]";

syntax Binding
  = val: "val"
  | var: "var"
  ;

syntax ParamDecl = paramDecl: Binding mode Id name ":" Type paramType;
syntax Declaration = declaration: Binding mode Id name (":" Type)? declaredType "=" Expression expr;

syntax Instruction
  = decl: Declaration
  | expr: Expression
  ;

syntax Block = block: "{" Instruction* instructions "}";
