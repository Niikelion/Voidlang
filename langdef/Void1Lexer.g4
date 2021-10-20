lexer grammar Void1Lexer;

fragment DecDigit: [0-9];
fragment NZDecDigit: [1-9];

ExpressionSeparator: ';';

WS: [ \t\r\n]+ -> skip;

DecimalNumber: (NZDecDigit(DecDigit)+) | DecDigit;

fragment HexDigit: [a-fA-F0-9];

HexadecimalNumber: '0x'HexDigit+;

SimpleString: '"' ('\\' ["\\] | ~["\\\r\n])* '"';

CScopeOpen: '{';
CScopeClose: '}';

RScopeOpen: '(';
RScopeClose: ')';

SScopeOpen: '[';
SScopeClose: ']';

Comma: ',';
Dot: '.';

Plus: '+';
Minus: '-';
Mult: '*';
Divide: '/';
Modulo: '%';

And: '&' | 'and';
Or: '|' | 'or';
Xor: '^' | 'xor';
Not: '!' | 'not';

Assignment: '=';

Class: 'class';
Using: 'using';
Union: 'union';
Enum: 'enum';
Namespace: 'namespace';

Name: [a-zA-Z_] ([a-zA-Z0-9_])*;