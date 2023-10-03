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
propertyDeclaration: Name ':' type '{' propertySpecifier (',' propertySpecifier)* '}';

propertySpecifier: Get | Set;

functionArgumentsDefinition: '(' (functionArgumentDefinition (',' functionArgumentDefinition)*)? ')';
functionArgumentDefinition: Name ':' type;

genericArgumentsDefinition: '<' Name (',' Name)* '>';

type: tupleType | normalType | optionalType;

optionalType: basicType '?';
normalType: basicType | functionType;
basicType: simpleType | arrayType; //TODO: support namespaces and nested types?
simpleType: namedType | tupleType | genericType;

arrayType: arrayType '[' DecimalNumber? ']' | simpleType;
genericType: namedType genericArgumentsSpecification;
functionType: (basicType | optionalType) Arrow type;
tupleType: '(' type (',' type)* ')';
namedType: Name;

genericArgumentsSpecification: '<' type (',' type)* '>';

expression: valueExpression; //TODO add non value expressions
valueExpression: simpleValueExpression; //TODO add other value expression

simpleValueExpression: '(' valueExpression ')' | constantValue | namedValueExpression | functionCallExpression;

accessValueExpression: simpleValueExpression | accessValueExpression '.' namedValueExpression; //TODO

possibleMemberAccessExpression: ;//TODO

arrayAccessExpression: simpleValueExpression '[' valueExpression ']';
namedValueExpression: Name;
functionCallExpression: Name genericArgumentsSpecification? functionCallArguments;
functionCallArguments: '(' (valueExpression (',' valueExpression)*)? ')';

constantValue: constantStringValue | constantIntegerValue;

constantStringValue: SimpleString;
constantIntegerValue: DecimalNumber | HexadecimalNumber;