lexer grammar Void1Lexer;

fragment DecDigit: [0-9];
fragment NZDecDigit: [1-9];

DecimalLiteral: (NZDecDigit(DecDigit)+) | DecDigit;

fragment HexDigit: [a-fA-F0-9];

HexadecimalLiteral: '0x'HexDigit+;

Separator: ';';

WS: [ \t\r\n]+ -> skip;