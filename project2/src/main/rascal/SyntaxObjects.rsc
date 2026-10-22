module SyntaxObjects

import Lexical;
//import SyntaxExpr; 

start syntax Module = prog: DefObject* defs MainMethod main DefObject* otherDefs;

syntax MainMethod = 
mainMethod: "method" "main" "{" Instruction* instructions "}";

syntax DefObject = 
defObject: "object" TypeId name GenericParams? Extends? Constructor? Block?;

syntax Extends = 
extends: "extends" TypeId;

syntax GenericParams = 
genericParams: "[" {GenericParameter ","}+ "]";

syntax GenericParameter = 
genericParameter: Variance? TypeId name;

syntax Variance = 
    plus: "+" 
  | minus: "-";

syntax Constructor = 
constructor: "(" {ParamDecl ","}* params ")";

syntax ParamDecl = 
paramDecl: ("val" | "var") TypeId name ":" Type;

syntax DefMethod = 
defMethod: "override"? TypeId? name "="? "method" "(" {MethodParam ","}* params ")" (":" Type)? ("=" (Expression | Block))?;

syntax MethodParam = 
methodParam: TypeId name ":" Type;

syntax Type = 
primitive: PrimitiveType
  | user: UserType;

syntax PrimitiveType = 
string: "String"
  | integer: "Integer"
  | boolean: "Boolean";

syntax UserType = 
userType: TypeId name TypeArgs?;

syntax TypeArgs = 
typeArgs: "[" {Type ","}+ "]";

syntax Declaration = 
declaration: ("val" | "var") TypeId name (":" Type)? "=" Expression;

syntax Instruction = 
decl: Declaration
  | expr: Expression;

syntax Block = 
block: "{" Instruction* instructions "}";