parser grammar Void1Parser;
options {
    tokenVocab = Void1Lexer;
}

numericLiteral: DecimalNumber | HexadecimalNumber;

stringLiteral: SimpleString;

type1Operation: Plus | Minus | Modulo;
type2Operation: Mult | Divide;

callArguments: CScopeOpen (expression (Comma expression)*)? CScopeClose;

variableAccess: Name (callArguments)? (Dot Name callArguments?)*;

valueExpression: numericLiteral | stringLiteral | variableAccess;

type0Expression: type1Expression | (type1Expression Assignment type0Expression) | (CScopeOpen type0Expression CScopeClose);
type1Expression: type2Expression | (type2Expression type1Operation type1Expression);
type2Expression: valueExpression | (valueExpression type2Operation type2Expression);

expression: type0Expression;

expressionSeq: ((expression ExpressionSeparator) | variableDeclaration | ExpressionSeparator)+;

expressionScope: CScopeOpen expressionSeq CScopeClose;

typeName: Name;

classScope: CScopeOpen (definition)*  CScopeClose;

enumScope: CScopeOpen (Name? (Comma Name)*) CScopeClose;

unionScope: CScopeOpen (memberOnlyDefinition)* CScopeClose;

variableDeclaration: typeName Name ExpressionSeparator;

classDefinition: Class Name classScope;

arguments: (typeName Name) | ((typeName Name) Comma arguments);

functionDefinition: typeName Name RScopeOpen arguments RScopeClose ExpressionSeparator;

functionDeclaration: typeName Name RScopeOpen arguments? RScopeClose expressionScope;

function: functionDefinition | functionDeclaration;

enumDefinition: Enum Name enumScope;

unionDefinition: Union Name unionScope;

usingDefinition: Using Name Assignment typeName ExpressionSeparator;

//maybe parse it in separate pass?
//preprocesorInstruction: expressionScope;

namespaceDefinition: Namespace Name CScopeOpen globalDefinition* CScopeClose;

memberOnlyDefinition: variableDeclaration | classDefinition | enumDefinition | usingDefinition;

definition: memberOnlyDefinition | function;

globalDefinition: definition | namespaceDefinition;


mainScope: globalDefinition+;

input: mainScope? EOF;