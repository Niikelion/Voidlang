parser grammar Void1Parser;
options {
    tokenVocab = Void1Lexer;
}

numericLiteral: DecimalLiteral | HexadecimalLiteral;

valueExpression: numericLiteral;

valueSeq: valueExpression | (valueExpression Separator valueSeq);

input: valueSeq? EOF;