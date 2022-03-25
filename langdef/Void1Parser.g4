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
ctorInit: CScopeOpen (valueExpression (Comma valueExpression)*)? CScopeClose;

//deconstructing declarations
tupleDeconstructionDecl: RScopeOpen tupleDeconstructionSubDecl (Comma tupleDeconstructionSubDecl)* RScopeClose;
tupleDeconstructionSubDecl: deconstructionSubDecl | tupleDeconstructionDecl | objectDeconstructionDecl;
objectDeconstructionDecl: CScopeOpen objectDeconstructionSubDecl (Comma objectDeconstructionSubDecl)* CScopeClose;
objectDeconstructionSubDecl: deconstructionSubDecl;

deconstructionSubDecl: identifier (Arrow (identifier | tupleDeconstructionDecl | objectDeconstructionDecl))?;

lambdaObjectDecl: CScopeOpen varDeclaration ((Comma | ExpressionSeparator) varDeclaration)* CScopeClose;

//function definitions
functionDefinition: cstyleFunctionDef | arrowFunctionDef;

cstyleFunctionDef: functionDefSignature functionBody;
arrowFunctionDef: functionDefSignature Arrow valueExpression;

functionDefSignature: typeExpression identifier templateArgs? argumentsDef;

argumentsDef: RScopeOpen (varDeclaration (Comma varDeclaration)*)? RScopeClose;
functionBody: CScopeOpen (expression ExpressionSeparator?)* CScopeClose;

//type definitions

classDefinition:
    Class identifier templateArgs? contextArgs? classExtending? classBody;

classBody:
    CScopeOpen (accessLevel Comma | innerDeclaration ExpressionSeparator?)* CScopeClose;

classExtending: Colon typeExpression (Comma typeExpression)*;

templateArgs: Lt templateArg (Comma templateArg)* Gt;
templateArg: typeExpression? identifier;

contextArgs: With contextArg (Comma contextArg)*;
contextArg: identifier (As identifier)?;

typeExpression: typeTemplate | typeExpression Dot typeTemplate | RScopeOpen typeExpression RScopeClose;
typeTemplate: typeName (Lt typeExpression (Comma typeExpression)* Gt)?;

//expressions
expression:
    declaration
|   valueExpression
|   operationExpression
|   scopeExpression;

//scope expressions
scopeExpression: 
    CScopeOpen (expression ExpressionSeparator?)* CScopeClose
|   With ctorContext scopeExpression?
|   Stateless scopeExpression;

//value expressions
valueExpression: logicalTopExpression;

functionCallArgs: RScopeOpen (valueExpression (Comma valueExpression)*)? RScopeClose;

logicalTopExpression:
    ifelseOperatorExpression
|   ifelseOperatorExpression logicalTopOperator logicalTopExpression;

logicalTopOperator: LAnd | LOr;

ifelseOperatorExpression: logicalExpression (Question valueExpression Colon valueExpression)?;

logicalExpression:
    shiftExpression
|   shiftExpression logicalOperator shiftExpression;

logicalOperator: Eq | NotEq | Lt | Gt | Leq | Geq;

binaryExpression:
    shiftExpression
|   binaryExpression binaryOperator;

binaryOperator: And | Or | Xor;

shiftExpression: 
    additiveExpression (shiftOperator shiftExpression)?;

shiftOperator: Lt Lt | Gt Gt;

additiveExpression:
    multiplicativeExpression (additiveOperator additiveExpression)?;

additiveOperator: Plus | Minus;

multiplicativeExpression:
    castExpression (multOperator multiplicativeExpression)?;

multOperator: Mult | Divide | Modulo;

castExpression:
    unaryExpression
|   castExpression As typeExpression
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
    lambdaFunction |
    variableExpression |
    ctorInvoke |
    RScopeOpen valueExpression RScopeClose;

variableExpression: identifier;

constantExpression: numericConstant | SimpleString;

piecewiseSubInit: identifier Assignment valueExpression;
piecewiseInit: CScopeOpen piecewiseSubInit (Comma piecewiseSubInit)* CScopeClose;

//lambdas
lambdaTuple: RScopeOpen valueExpression (Comma valueExpression)* RScopeClose;

lambdaObject: CScopeOpen lambdaObjectMember ((Comma | ExpressionSeparator) lambdaObjectMember)* CScopeClose;
lambdaObjectMember: identifier Assignment valueExpression | varDeclaration;
lambdaObjectSubMember: identifier varDeclInit;

lambdaFunction: conventionalLambda | autoLambda;
conventionalLambda: typeExpression? argumentsDef (Arrow valueExpression | Arrow? functionBody);
autoLambda: identifier Arrow (valueExpression | functionBody);

//constructor calls
ctorInvoke: typeExpression ctorInit (With ctorContext)?;
ctorContext: (contextList | contextMap);

contextList: valueExpression (Comma valueExpression)*;
contextMap: CScopeOpen contextMapPart (Comma contextMapPart)* CScopeClose;
contextMapPart: identifier Assignment valueExpression;

//operations
operationExpression:
    Return valueExpression?;

//sub
numericConstant: 
    DecimalNumber |
    HexadecimalNumber;

typeName: identifier;
identifier: Name;