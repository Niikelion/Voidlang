lexer grammar VoidLexer;

WhiteScape: [ \t\r\n]+ -> skip;
BlockComment: '/*' .*? '*/' -> skip;
LineComment: '//' ~ [\r\n]* -> skip;
ExpressionSeparator: ';';

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
If: 'if';
Else: 'else';

//keywords
Import: 'import';
Trait: 'trait';
Get: 'get';
Set: 'set';

//qualifiers
Name: [a-zA-Z_] ([a-zA-Z0-9_])*;