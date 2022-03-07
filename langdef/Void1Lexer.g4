lexer grammar Void1Lexer;

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
LShift: '<<';
RShift: '>>';
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
Cast: 'as';
Arrow: '->';
Return: 'ret';
IfOp: '?';
ElseOp: ':';

//keywords
Var: 'var';
Class: 'class';
Struct: 'struct';
Public: 'pub';
Private: 'priv';
Protected: 'prot';
Virtual: 'virtual';
//qualifiers
Name: [a-zA-Z_] ([a-zA-Z0-9_])*;