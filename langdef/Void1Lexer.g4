lexer grammar Void1Lexer;

fragment DecDigit: [0-9];
fragment NZDecDigit: [1-9];

Separator: ';';

WS: [ \t\r\n]+ -> skip;

DecimalNumber: (NZDecDigit(DecDigit)+) | DecDigit;

fragment HexDigit: [a-fA-F0-9];

HexadecimalNumber: '0x'HexDigit+;

SimpleString: '"' ('\\' ["\\] | ~["\\\r\n])* '"';