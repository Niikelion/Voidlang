lexer grammar VoidLexer;

ExpressionSeparator: ';';
WhiteScape: [ \t\r\n]+ -> skip;
BlockComment: '/*' .*? '*/' -> skip;
LineComment: '//' ~ [\r\n]* -> skip;

//numeric fragments
fragment DecDigit: [0-9];
fragment HexDigit: [a-fA-F0-9];
//numbers
DecimalNumber: DecDigit+;
HexadecimalNumber: '0x'HexDigit+;
//strings
SimpleString: '"' ('\\' . | ~["\\\r\n])* '"';
//scope braces
CScopeOpen: '{';
CScopeClose: '}';

RScopeOpen: '(';
RScopeClose: ')';

SScopeOpen: '[';
SScopeClose: ']';

Comma: ',';
Dot: '.';
//operators

//arithmetic
Plus: '+';
PlusPlus: '++';
Minus: '-';
MinusMinus: '--';
Mult: '*';
Divide: '/';
Modulo: '%';

//binary
And: '&';
Or: '|';
Xor: '^';
Neg: '~';
//logical
Not: '!';
LAnd: '&&';
LOr: '||';
Eq: '==';
NotEq: '!=';
Lt: '<';
Leq: '<=';
Gt: '>';
Geq: '>=';

//common
Assignment: '=';
As: 'as';
Arrow: '->';
Return: 'ret';
Question: '?';
Colon: ':';

//keywords
Var: 'var';
Class: 'class';
Struct: 'struct';
Public: 'pub';
Private: 'priv';
Protected: 'prot';
Virtual: 'virtual';
With: 'with';
Stateless: 'stateless';
Trait: 'trait';
Import: 'import';
Module: 'module';
//qualifiers
Name: [a-zA-Z_] ([a-zA-Z0-9_])*;