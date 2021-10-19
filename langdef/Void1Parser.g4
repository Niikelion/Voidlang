parser grammar Void1Parser;
options {
    tokenVocab = Void1Lexer;
}

numericLiteral: DecimalNumber | HexadecimalNumber;

stringLiteral: SimpleString;

valueExpression: numericLiteral | stringLiteral;

valueSeq: valueExpression | (valueExpression Separator valueSeq) | Separator;

input: valueSeq? EOF;