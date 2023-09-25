parser grammar VoidParser;
options {
    tokenVocab = VoidLexer;
}

//top level
input: file;
file: line* EOF;

line: topLevel | topLevel ExpressionSeparator;

topLevel:
    declaration #topLevelDeclaration
|   Import identifier #importDeclaration
|   Module identifier #moduleDefinition;

//declarations
declaration: commonDeclaration;
innerDeclaration: accessLevel? commonDeclaration;

accessLevel: Public | Private | Protected;

commonDeclaration: varDeclaration | functionDefinition | classDefinition | traitDefinition;

//variable declarations
varDeclaration:
    cStyleVarDeclaration | extendedCStyleVarDeclaration | deconstructionVarDeclaration;

cStyleVarDeclaration: typeExpression varSubDeclaration (Comma varSubDeclaration)*;
extendedCStyleVarDeclaration: Var varSubDeclaration (Comma varSubDeclaration)*;
deconstructionVarDeclaration: Var tupleDeconstructionDecl Assignment valueExpression;

//initialization
varSubDeclaration: identifier varDeclInit?;
varDeclInit: Assignment valueExpression | declInit;

declInit: ctorInit | piecewiseInit;
ctorInit: CScopeOpen (valueExpression (Comma valueExpression)*)? CScopeClose;

//deconstructing declarations
tupleDeconstructionDecl: RScopeOpen identifier (Comma identifier)* RScopeClose;

//function definitions
functionDefinition: cstyleFunctionDef | arrowFunctionDef;

cstyleFunctionDef: functionDefSignature functionBody;
arrowFunctionDef: functionDefSignature Arrow valueExpression;

functionDefSignature: typeExpression identifier templateArgs? argumentsDef;

argumentsDef: RScopeOpen (argumentDef (Comma argumentDef)*)? RScopeClose;
argumentDef: typeExpression identifier (Assignment valueExpression)?;
functionBody: CScopeOpen ExpressionSeparator* ((expression | expression ExpressionSeparator))* ExpressionSeparator* CScopeClose | valueExpression;
functionCallArgs: RScopeOpen (valueExpression (Comma valueExpression)*)? RScopeClose;

//type definitions

traitDefinition: Trait identifier templateArgs? traitBody;

traitBody: CScopeOpen (traitInnerDecl ExpressionSeparator?)* CScopeClose;
traitInnerDecl: functionDefSignature;

classDefinition:
    Class identifier templateArgs? classExtending? contextArgs? classBody;

classBody:
    CScopeOpen (accessBlockStart | innerDeclaration ExpressionSeparator?)* CScopeClose;

accessBlockStart: accessLevel Colon;

classExtending: Colon typeExpression (Comma typeExpression)*;

templateArgs: Lt templateArg (Comma templateArg)* Gt;
templateArg: identifier (Colon typeExpression)?;

contextArgs: With contextArg (Comma contextArg)*;
contextArg: identifier (As identifier)?;

typeExpression:
    typeSubExpression
|   lambdaObjectType;
typeSubExpression: typeTemplate | typeAccess;
//|   typeOfFunction;
typeTemplate: typeName (Lt typeExpression (Comma typeExpression)* Gt)?;
typeAccess: typeTemplate Dot typeSubExpression;

lambdaObjectType: CScopeOpen cStyleVarDeclaration ((Comma | ExpressionSeparator) cStyleVarDeclaration)* CScopeClose;
//typeOfFunction: RScopeOpen typeExpression RScopeClose Arrow typeExpression;
//expressions
expression:
    declaration
|   valueExpression
|   operationExpression
|   scopeExpression;

//scope expressions
scopeExpression: 
    CScopeOpen (expression ExpressionSeparator?)* CScopeClose #blockExp
|   With ctorContext scopeExpression? #statedExp
|   Stateless scopeExpression #statelessExp;

//value expressions
valueExpression: lambdaExpression;

lambdaExpression:
    assignmentExpression #assignmentPassThrough
|   lambdaFunction #lambda;

assignmentExpression:
    logicalTopExpression #logicalTopPassThrough
|   logicalExpression Assignment valueExpression #assignmentOp;

logicalTopExpression:
    ifElseOperatorExpression #ifElseOperatorPassThrough
|   ifElseOperatorExpression logicalTopOperator logicalTopExpression #logicalTopOp;

logicalTopOperator: LAnd | LOr;

ifElseOperatorExpression:
    logicalExpression #logicalPassThrough
|   logicalExpression Question valueExpression Colon valueExpression #ifElseOp;

logicalExpression:
    binaryExpression #binaryPassThrough
|   binaryExpression logicalOperator binaryExpression #logicalOp;

logicalOperator: Eq | NotEq | Lt | Gt | Leq | Geq;

binaryExpression:
    shiftExpression #shiftPassThrough
|   shiftExpression binaryOperator binaryExpression #binaryOp;

binaryOperator: And | Or | Xor;

shiftExpression:
    additiveExpression #additivePassThrough
|   additiveExpression shiftOperator shiftExpression #shiftOp;

shiftOperator: Lt Lt | Gt Gt;

additiveExpression:
    multiplicativeExpression #multiplicativePassThrough
|   multiplicativeExpression additiveOperator additiveExpression #additiveOp;

additiveOperator: Plus | Minus;

multiplicativeExpression:
    castExpression #castPassThrough
|   castExpression multOperator multiplicativeExpression #multiplicativeOp;

multOperator: Mult | Divide | Modulo;

castExpression:
    unaryExpression #unaryPassthrough
|   castExpression As typeExpression #asCast
|   RScopeOpen typeExpression RScopeClose valueExpression #cCast;

unaryExpression:
    postfixExpression #postfixPassThrough
|   unaryOperator unaryExpression #unaryOp;

unaryOperator: MinusMinus | PlusPlus | Not | Neg;

postfixExpression:
    accessExpression #accessPassThrough
|   postfixExpression postfixOperator #postfixOp;

postfixOperator: MinusMinus | PlusPlus;

accessExpression:
    primaryExpression #primaryPassThrough
|   accessExpression Dot variableExpression #memberAccess
|   accessExpression functionCallArgs #functionCall;

primaryExpression:
    RScopeOpen valueExpression RScopeClose |
    constantExpression |
    lambdaObject |
    lambdaTuple |
    variableExpression |
    ctorInvoke;

variableExpression: identifier;

constantExpression: numericConstant | stringConstant;

piecewiseSubInit: Dot identifier Assignment valueExpression;
piecewiseInit: CScopeOpen piecewiseSubInit (Comma piecewiseSubInit)* CScopeClose;

//lambdas
lambdaTuple: RScopeOpen valueExpression (Comma valueExpression)+ RScopeClose;

lambdaObject: CScopeOpen lambdaObjectMember ((Comma | ExpressionSeparator) lambdaObjectMember)* CScopeClose;
lambdaObjectMember: identifier Assignment valueExpression | typeExpression identifier;

lambdaFunction:
    typeExpression? RScopeOpen (lambdaFunctionArgDef (Comma lambdaFunctionArgDef)*)? RScopeClose Arrow functionBody #conventionalLambda
|   identifier Arrow functionBody #simplifiedLambda;

lambdaFunctionArgDef: typeExpression? identifier;

//constructor calls
ctorInvoke: typeExpression ctorInit (With ctorContext)?;
ctorContext: (contextList | contextMap);

contextList: valueExpression (Comma valueExpression)*;
contextMap: CScopeOpen contextMapPart (Comma contextMapPart)* CScopeClose;
contextMapPart: identifier Assignment valueExpression;

//operations
operationExpression:
    Return valueExpression? #returnExpression
|   ifElseExpression #ifElseExp;

ifElseExpression:
    If valueExpression expression (Else expression)??;

//sub
numericConstant: 
    DecimalNumber |
    HexadecimalNumber;

stringConstant:
    SimpleString;

typeName: identifier;
identifier: Name;