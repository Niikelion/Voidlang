parser grammar VoidParser;
options {
    tokenVocab = VoidLexer;
}

//top level
input: file;
file: importStatements definitions EOF;

importStatements: importStatement*;
importStatement: Import Name (Dot Name)*;

definitions: definition*;

definition: traitDefinition | functionDefinition;

traitDefinition: Trait Name genericArgumentsDefinition? traitScope;
functionDefinition: functionDeclaration genericArgumentsDefinition? functionBodyDefinition;

functionBodyDefinition: valueFunctionBodyDefinition | fullFunctionBodyDefinition;

valueFunctionBodyDefinition: Arrow valueExpression ExpressionSeparator;
fullFunctionBodyDefinition: '{' expression*'}';

traitScope: '{' (functionDeclaration | propertyDeclaration)+ '}';

functionDeclaration: Name genericArgumentsDefinition? functionArgumentsDefinition ':' type;
propertyDeclaration: Name ':' type '{' (Get | Set) (',' (Get | Set))* '}';

functionArgumentsDefinition: '(' (functionArgumentDefinition (',' functionArgumentDefinition)*)? ')';
functionArgumentDefinition: Name ':' type;

genericArgumentsDefinition: '<' Name (',' Name)* '>';

type: tupleType | normalType | optionalType;

optionalType: basicType '?';
normalType: basicType | functionType;
basicType: namedType | tupleType | genericType; //TODO: support namespaces and nested types?

genericType: namedType genericArgumentsSpecification;
functionType: (basicType | optionalType) Arrow type;
tupleType: '(' type (',' type)* ')';
namedType: Name;

genericArgumentsSpecification: '<' type (',' type)* '>';

expression: valueExpression; //TODO add non value expressions
valueExpression: '(' valueExpression ')' | simpleValueExpression; //TODO add other value expression

simpleValueExpression: constantValue | Name;

constantValue: constantStringValue | constantIntegerValue;

constantStringValue: SimpleString;
constantIntegerValue: DecimalNumber | HexadecimalNumber;