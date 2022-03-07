parser grammar Void1Parser;
options {
    tokenVocab = Void1Lexer;
}

//top level
input: file;
file: (declaration ExpressionSeparator?)* EOF;
//declarations
declaration: commonDeclaration;
innerDeclaration: accessLevel? commonDeclaration;

accessLevel: Public | Private | Protected;

commonDeclaration: varDeclaration | functionDefinition | classDefinition;

//variable declarations
varDeclaration:
    (Var | typeExpression | lambdaObjectDecl) varSubDeclaration (Comma varSubDeclaration)* |
    Var tupleDeconstructionDecl Assignment valueExpression |
    Var objectDeconstructionDecl Assignment valueExpression;

//initialization
varSubDeclaration: identifier varDeclInit?;
varDeclInit: Assignment valueExpression | declInit;

declInit: ctorInit | piecewiseInit;
ctorInit: CScopeOpen valueExpression (Comma valueExpression)* CScopeClose;

//deconstructing declarations
tupleDeconstructionDecl: RScopeOpen tupleDeconstructionSubDecl (Comma tupleDeconstructionSubDecl)* RScopeClose;
tupleDeconstructionSubDecl: deconstructionSubDecl | tupleDeconstructionDecl | objectDeconstructionDecl;
objectDeconstructionDecl: CScopeOpen objectDeconstructionSubDecl (Comma objectDeconstructionSubDecl)* CScopeClose;
objectDeconstructionSubDecl: deconstructionSubDecl;

deconstructionSubDecl: identifier (Arrow (identifier | tupleDeconstructionDecl | objectDeconstructionDecl))?;

lambdaObjectDecl: CScopeOpen varDeclaration ((Comma | ExpressionSeparator) varDeclaration)* CScopeClose;

//function definitions
functionDefinition: cstyleFunctionDef | arrowFunctionDef | aliasFunctionDef;

cstyleFunctionDef: functionDefSignature functionBody;
arrowFunctionDef: functionDefSignature Arrow valueExpression;
aliasFunctionDef: identifier argumentsDef? Arrow valueExpression;

functionDefSignature: typeExpression identifier argumentsDef;

argumentsDef: RScopeOpen (varDeclaration (Comma varDeclaration)*)? RScopeClose;
functionBody: CScopeOpen expression* CScopeClose;

//type definitions

classDefinition:
    Class identifier classBody;

classBody:
    CScopeOpen (innerDeclaration ExpressionSeparator?)* CScopeClose;

//expressions
expression:
    declaration |
    valueExpression |
    operationExpression;

valueExpression: logicalTopExpression;

functionCallArgs: RScopeOpen (valueExpression (Comma valueExpression)*)? RScopeClose;

logicalTopExpression:
    ifelseOperatorExpression
|   ifelseOperatorExpression logicalTopOperator logicalTopExpression;

logicalTopOperator: LAnd | LOr;

ifelseOperatorExpression: logicalExpression (IfOp valueExpression ElseOp valueExpression)?;

logicalExpression:
    shiftExpression
|   shiftExpression logicalOperator logicalExpression;

logicalOperator: Eq | NotEq | Lt | Gt | Leq | Geq;

binaryExpression:
    shiftExpression
|   binaryExpression binaryOperator;

binaryOperator: And | Or | Xor;

shiftExpression: 
    additiveExpression (shiftOperator shiftExpression)?;

shiftOperator: LShift | RShift;

additiveExpression:
    multiplicativeExpression (additiveOperator additiveExpression)?;

additiveOperator: Plus | Minus;

multiplicativeExpression:
    castExpression (multOperator multiplicativeExpression)?;

multOperator: Mult | Divide | Modulo;

castExpression:
    unaryExpression
|   castExpression Cast typeExpression
|   RScopeOpen typeExpression RScopeClose valueExpression;

unaryExpression:
    postfixExpression
|   unaryOperator unaryExpression;

unaryOperator: MinusMinus | PlusPlus | Not | Neg;

postfixExpression:
    accessExpression
|   postfixExpression postfixOperator;

postfixOperator: MinusMinus | PlusPlus;

accessExpression:
    primaryExpression
|   accessExpression Dot variableExpression
|   accessExpression functionCallArgs;

primaryExpression:
    constantExpression |
    lambdaObject |
    lambdaTuple |
    variableExpression |
    ctorInvoke |
    RScopeOpen valueExpression RScopeClose;

variableExpression: identifier;

constantExpression: numericConstant | SimpleString;

piecewiseSubInit: identifier Assignment valueExpression;
piecewiseInit: CScopeOpen piecewiseSubInit (Comma piecewiseSubInit)* CScopeClose;

lambdaTuple: RScopeOpen valueExpression (Comma valueExpression)* RScopeClose;

lambdaObject: CScopeOpen lambdaObjectMember ((Comma | ExpressionSeparator) lambdaObjectMember)* CScopeClose;
lambdaObjectMember: identifier Assignment valueExpression | varDeclaration;
lambdaObjectSubMember: identifier varDeclInit;

ctorInvoke: typeExpression ctorInit;

typeExpression: typeName;

//operations
operationExpression:
    Return valueExpression?;

//sub
numericConstant: 
    DecimalNumber | 
    HexadecimalNumber;

typeName: Name;
identifier: Name;