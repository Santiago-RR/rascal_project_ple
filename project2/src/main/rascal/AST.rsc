module AST

import Lexical;
import SyntaxObjects;
import SyntaxExpr;

// Cada constructor replica exactamente los campos no literales de la producción
// con la misma etiqueta. Esto permite usar implode(#AST::X, parse(...)).
data Module = prog(list[Definition] defs, MainMethod main, list[Definition] otherDefs);

data Definition
  = objectDef(DefObject object)
  | methodDef(DefMethod method)
  ;

data MainMethod = mainMethod(Block body);

data DefObject = defObject(TypeId name, list[GenericParams] params, list[Extends] parent,
                           list[Constructor] constructor, list[ObjectBody] body);

data GenericParams = genericParams(list[GenericParameter] params);
data GenericParameter = genericParameter(list[Variance] variance, TypeId name);
data Variance = plus() | minus();
data Extends = extends(TypeId superType);
data Constructor = constructor(list[ParamDecl] params);
data ObjectBody = objectBody(list[Member] members);
data Member = field(Declaration field) | method(DefMethod method);

data DefMethod
  = qualifiedMethod(TypeId owner, Id name, list[MethodParam] params,
                    list[Type] returnType, list[MethodBody] body)
  | memberMethod(list[Override] override, Id name, list[MethodParam] params,
                 list[Type] returnType, MethodBody body)
  ;

data Override = override();
data MethodParam = methodParam(Id name, Type paramType);
data MethodBody = bodyBlock(Block body) | bodyExpression(Expression body);

data Type = primitive(PrimitiveType prim) | user(UserType user);
data PrimitiveType = string() | integer() | boolean();
data UserType = userType(TypeId name, list[TypeArgs] args);
data TypeArgs = typeArgs(list[Type] args);

data Binding = val() | var();
data ParamDecl = paramDecl(Binding mode, Id name, Type paramType);
data Declaration = declaration(Binding mode, Id name, list[Type] declaredType, Expression expr);
data Instruction = decl(Declaration decl) | expr(Expression expr) | control(ForLoop loop);
data Block = block(list[Instruction] instructions);

// Parte B: los constructores de las producciones ya presentes en SyntaxExpr.
data Expression
  = literal(Literal literal)
  | variable(Id name)
  | call(Id name, list[Expression] args)
  | paren(Expression expr)
  | newObject(Type objType, list[ObjectBody] body)
  | newObjectArgs(Type objType, NewArgs ctorArgs, list[ObjectBody] body)
  | memberAccess(Expression target, Id member)
  | methodCall(Expression target, Id member, list[Expression] args)
  | neg(Expression expr)
  | power(Expression lhs, Expression rhs)
  | mul(Expression lhs, Expression rhs)
  | div(Expression lhs, Expression rhs)
  | modulo(Expression lhs, Expression rhs)
  | add(Expression lhs, Expression rhs)
  | sub(Expression lhs, Expression rhs)
  | lt(Expression lhs, Expression rhs)
  | gt(Expression lhs, Expression rhs)
  | le(Expression lhs, Expression rhs)
  | ge(Expression lhs, Expression rhs)
  | ne(Expression lhs, Expression rhs)
  | eq(Expression lhs, Expression rhs)
  | andExpr(Expression lhs, Expression rhs)
  | orExpr(Expression lhs, Expression rhs)
  | conditional(Expression cond, Expression thenBranch, Expression elseBranch)
  ;

data NewArgs = newArgs(list[Expression] args);
data Literal = intLit(IntLit n) | trueLit() | falseLit() | stringLit(StringLiteral s);
data StringLiteral = plain(StrPlain text) | interpolated(StrPre pre, Expression expr, StrTail tail);
data StrTail = mid(StrMid text, Expression expr, StrTail tail) | post(StrPost text);
data ForLoop = forLoop(IterationPattern pattern, Expression source, Instruction body);
data IterationPattern = single(Id name) | tupleOf(list[Id] names);
