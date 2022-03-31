parser grammar VoidParser;
options {
    tokenVocab = VoidLexer;
}

//top level
input: file;
file: (topLevel ExpressionSeparator?)* EOF;

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
    cStyleVarDeclaration | extendedcStyleVarDeclaration | deconstructionVarDeclaration;

cStyleVarDeclaration: typeExpression varSubDeclaration (Comma varSubDeclaration)*;
extendedcStyleVarDeclaration: (Var | lambdaObjectDecl) varSubDeclaration (Comma varSubDeclaration)*;
deconstructionVarDeclaration: Var (tupleDeconstructionDecl | objectDeconstructionDecl) Assignment valueExpression;

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

argumentsDef: RScopeOpen (argumentDef (Comma argumentDef)*)? RScopeClose;
argumentDef: typeExpression identifier (Assignment valueExpression)?;
functionBody: CScopeOpen (expression ExpressionSeparator?)* CScopeClose;

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
    typeTemplate
|   typeAccess;
//|   typeOfFunction;
typeTemplate: typeName (Lt typeExpression (Comma typeExpression)* Gt)?;
typeAccess: typeTemplate Dot typeExpression;
//typeOfFunction: RScopeOpen typeExpression RScopeClose Arrow typeExpression;
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
valueExpression: assignmentExpression;

functionCallArgs: RScopeOpen (valueExpression (Comma valueExpression)*)? RScopeClose;

assignmentExpression:
    logicalTopExpression
|   logicalExpression Assignment valueExpression;

logicalTopExpression:
    ifelseOperatorExpression
|   ifelseOperatorExpression logicalTopOperator logicalTopExpression;

logicalTopOperator: LAnd | LOr;

ifelseOperatorExpression: logicalExpression (Question valueExpression Colon valueExpression)?;

logicalExpression:
    binaryExpression
|   binaryExpression logicalOperator binaryExpression;

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
lambdaObjectMember: identifier varDeclInit | typeExpression identifier;

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