module AST

import Lexical;


data Module = prog(list[DefObject] defs, MainMethod main, list[DefObject] otherDefs);

data MainMethod = mainMethod(list[Instruction] instructions);

data DefObject = defObject(TypeId name, list[GenericParameter] genericParams, Extends ext, Constructor constructor, list[Block] block);

data Extends = noExtends() | extends(TypeId superType);

data GenericParameter = genericParameter(Variance variance, TypeId name);

data Variance = plus() | minus() | none();

data Constructor = constructor(list[ParamDecl] params);

data ParamDecl = paramDecl(str mode, TypeId typeId, Id name, Type paramType);

data DefMethod = defMethod(bool isOverride, TypeId returnType, Id name, list[MethodParam] params, Type type, Expression body);

data MethodParam = methodParam(TypeId typeId, Id name, Type paramType);

data Type = primitive(PrimitiveType prim) | user(UserType user);

data PrimitiveType = stringType() | intType() | boolType();

data UserType = userType(TypeId name, list[Type] typeArgs);

data Declaration = declaration(str mode, TypeId typeId, Id name, Type paramType, Expression expr);

data Instruction = decl(Declaration decl) | expr(Expression expr);

data Block = block(list[Instruction] instructions);