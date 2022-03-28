// Generated from H:/projects/Voidlang/tools/libvoid/src/main/antlr\VoidLexer.g4 by ANTLR 4.9.2
import org.antlr.v4.runtime.Lexer;
import org.antlr.v4.runtime.CharStream;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.TokenStream;
import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.atn.*;
import org.antlr.v4.runtime.dfa.DFA;
import org.antlr.v4.runtime.misc.*;

@SuppressWarnings({"all", "warnings", "unchecked", "unused", "cast"})
public class VoidLexer extends Lexer {
	static { RuntimeMetaData.checkVersion("4.9.2", RuntimeMetaData.VERSION); }

	protected static final DFA[] _decisionToDFA;
	protected static final PredictionContextCache _sharedContextCache =
		new PredictionContextCache();
	public static final int
		ExpressionSeparator=1, WhiteScape=2, BlockComment=3, LineComment=4, DecimalNumber=5, 
		HexadecimalNumber=6, SimpleString=7, CScopeOpen=8, CScopeClose=9, RScopeOpen=10, 
		RScopeClose=11, SScopeOpen=12, SScopeClose=13, Comma=14, Dot=15, Plus=16, 
		PlusPlus=17, Minus=18, MinusMinus=19, Mult=20, Divide=21, Modulo=22, And=23, 
		Or=24, Xor=25, Neg=26, Not=27, LAnd=28, LOr=29, Eq=30, NotEq=31, Lt=32, 
		Leq=33, Gt=34, Geq=35, Assignment=36, As=37, Arrow=38, Return=39, Question=40, 
		Colon=41, Var=42, Class=43, Struct=44, Public=45, Private=46, Protected=47, 
		Virtual=48, With=49, Stateless=50, Trait=51, Import=52, Module=53, Name=54;
	public static String[] channelNames = {
		"DEFAULT_TOKEN_CHANNEL", "HIDDEN"
	};

	public static String[] modeNames = {
		"DEFAULT_MODE"
	};

	private static String[] makeRuleNames() {
		return new String[] {
			"ExpressionSeparator", "WhiteScape", "BlockComment", "LineComment", "DecDigit", 
			"HexDigit", "DecimalNumber", "HexadecimalNumber", "SimpleString", "CScopeOpen", 
			"CScopeClose", "RScopeOpen", "RScopeClose", "SScopeOpen", "SScopeClose", 
			"Comma", "Dot", "Plus", "PlusPlus", "Minus", "MinusMinus", "Mult", "Divide", 
			"Modulo", "And", "Or", "Xor", "Neg", "Not", "LAnd", "LOr", "Eq", "NotEq", 
			"Lt", "Leq", "Gt", "Geq", "Assignment", "As", "Arrow", "Return", "Question", 
			"Colon", "Var", "Class", "Struct", "Public", "Private", "Protected", 
			"Virtual", "With", "Stateless", "Trait", "Import", "Module", "Name"
		};
	}
	public static final String[] ruleNames = makeRuleNames();

	private static String[] makeLiteralNames() {
		return new String[] {
			null, "';'", null, null, null, null, null, null, "'{'", "'}'", "'('", 
			"')'", "'['", "']'", "','", "'.'", "'+'", "'++'", "'-'", "'--'", "'*'", 
			"'/'", "'%'", "'&'", "'|'", "'^'", "'~'", "'!'", "'&&'", "'||'", "'=='", 
			"'!='", "'<'", "'<='", "'>'", "'>='", "'='", "'as'", "'->'", "'ret'", 
			"'?'", "':'", "'var'", "'class'", "'struct'", "'pub'", "'priv'", "'prot'", 
			"'virtual'", "'with'", "'stateless'", "'trait'", "'import'", "'module'"
		};
	}
	private static final String[] _LITERAL_NAMES = makeLiteralNames();
	private static String[] makeSymbolicNames() {
		return new String[] {
			null, "ExpressionSeparator", "WhiteScape", "BlockComment", "LineComment", 
			"DecimalNumber", "HexadecimalNumber", "SimpleString", "CScopeOpen", "CScopeClose", 
			"RScopeOpen", "RScopeClose", "SScopeOpen", "SScopeClose", "Comma", "Dot", 
			"Plus", "PlusPlus", "Minus", "MinusMinus", "Mult", "Divide", "Modulo", 
			"And", "Or", "Xor", "Neg", "Not", "LAnd", "LOr", "Eq", "NotEq", "Lt", 
			"Leq", "Gt", "Geq", "Assignment", "As", "Arrow", "Return", "Question", 
			"Colon", "Var", "Class", "Struct", "Public", "Private", "Protected", 
			"Virtual", "With", "Stateless", "Trait", "Import", "Module", "Name"
		};
	}
	private static final String[] _SYMBOLIC_NAMES = makeSymbolicNames();
	public static final Vocabulary VOCABULARY = new VocabularyImpl(_LITERAL_NAMES, _SYMBOLIC_NAMES);

	/**
	 * @deprecated Use {@link #VOCABULARY} instead.
	 */
	@Deprecated
	public static final String[] tokenNames;
	static {
		tokenNames = new String[_SYMBOLIC_NAMES.length];
		for (int i = 0; i < tokenNames.length; i++) {
			tokenNames[i] = VOCABULARY.getLiteralName(i);
			if (tokenNames[i] == null) {
				tokenNames[i] = VOCABULARY.getSymbolicName(i);
			}

			if (tokenNames[i] == null) {
				tokenNames[i] = "<INVALID>";
			}
		}
	}

	@Override
	@Deprecated
	public String[] getTokenNames() {
		return tokenNames;
	}

	@Override

	public Vocabulary getVocabulary() {
		return VOCABULARY;
	}


	public VoidLexer(CharStream input) {
		super(input);
		_interp = new LexerATNSimulator(this,_ATN,_decisionToDFA,_sharedContextCache);
	}

	@Override
	public String getGrammarFileName() { return "VoidLexer.g4"; }

	@Override
	public String[] getRuleNames() { return ruleNames; }

	@Override
	public String getSerializedATN() { return _serializedATN; }

	@Override
	public String[] getChannelNames() { return channelNames; }

	@Override
	public String[] getModeNames() { return modeNames; }

	@Override
	public ATN getATN() { return _ATN; }

	public static final String _serializedATN =
		"\3\u608b\ua72a\u8133\ub9ed\u417c\u3be7\u7786\u5964\28\u0152\b\1\4\2\t"+
		"\2\4\3\t\3\4\4\t\4\4\5\t\5\4\6\t\6\4\7\t\7\4\b\t\b\4\t\t\t\4\n\t\n\4\13"+
		"\t\13\4\f\t\f\4\r\t\r\4\16\t\16\4\17\t\17\4\20\t\20\4\21\t\21\4\22\t\22"+
		"\4\23\t\23\4\24\t\24\4\25\t\25\4\26\t\26\4\27\t\27\4\30\t\30\4\31\t\31"+
		"\4\32\t\32\4\33\t\33\4\34\t\34\4\35\t\35\4\36\t\36\4\37\t\37\4 \t \4!"+
		"\t!\4\"\t\"\4#\t#\4$\t$\4%\t%\4&\t&\4\'\t\'\4(\t(\4)\t)\4*\t*\4+\t+\4"+
		",\t,\4-\t-\4.\t.\4/\t/\4\60\t\60\4\61\t\61\4\62\t\62\4\63\t\63\4\64\t"+
		"\64\4\65\t\65\4\66\t\66\4\67\t\67\48\t8\49\t9\3\2\3\2\3\3\6\3w\n\3\r\3"+
		"\16\3x\3\3\3\3\3\4\3\4\3\4\3\4\7\4\u0081\n\4\f\4\16\4\u0084\13\4\3\4\3"+
		"\4\3\4\3\4\3\4\3\5\3\5\3\5\3\5\7\5\u008f\n\5\f\5\16\5\u0092\13\5\3\5\3"+
		"\5\3\6\3\6\3\7\3\7\3\b\6\b\u009b\n\b\r\b\16\b\u009c\3\t\3\t\3\t\3\t\6"+
		"\t\u00a3\n\t\r\t\16\t\u00a4\3\n\3\n\3\n\3\n\7\n\u00ab\n\n\f\n\16\n\u00ae"+
		"\13\n\3\n\3\n\3\13\3\13\3\f\3\f\3\r\3\r\3\16\3\16\3\17\3\17\3\20\3\20"+
		"\3\21\3\21\3\22\3\22\3\23\3\23\3\24\3\24\3\24\3\25\3\25\3\26\3\26\3\26"+
		"\3\27\3\27\3\30\3\30\3\31\3\31\3\32\3\32\3\33\3\33\3\34\3\34\3\35\3\35"+
		"\3\36\3\36\3\37\3\37\3\37\3 \3 \3 \3!\3!\3!\3\"\3\"\3\"\3#\3#\3$\3$\3"+
		"$\3%\3%\3&\3&\3&\3\'\3\'\3(\3(\3(\3)\3)\3)\3*\3*\3*\3*\3+\3+\3,\3,\3-"+
		"\3-\3-\3-\3.\3.\3.\3.\3.\3.\3/\3/\3/\3/\3/\3/\3/\3\60\3\60\3\60\3\60\3"+
		"\61\3\61\3\61\3\61\3\61\3\62\3\62\3\62\3\62\3\62\3\63\3\63\3\63\3\63\3"+
		"\63\3\63\3\63\3\63\3\64\3\64\3\64\3\64\3\64\3\65\3\65\3\65\3\65\3\65\3"+
		"\65\3\65\3\65\3\65\3\65\3\66\3\66\3\66\3\66\3\66\3\66\3\67\3\67\3\67\3"+
		"\67\3\67\3\67\3\67\38\38\38\38\38\38\38\39\39\79\u014e\n9\f9\169\u0151"+
		"\139\3\u0082\2:\3\3\5\4\7\5\t\6\13\2\r\2\17\7\21\b\23\t\25\n\27\13\31"+
		"\f\33\r\35\16\37\17!\20#\21%\22\'\23)\24+\25-\26/\27\61\30\63\31\65\32"+
		"\67\339\34;\35=\36?\37A C!E\"G#I$K%M&O\'Q(S)U*W+Y,[-]._/a\60c\61e\62g"+
		"\63i\64k\65m\66o\67q8\3\2\t\5\2\13\f\17\17\"\"\4\2\f\f\17\17\3\2\62;\5"+
		"\2\62;CHch\6\2\f\f\17\17$$^^\5\2C\\aac|\6\2\62;C\\aac|\2\u0157\2\3\3\2"+
		"\2\2\2\5\3\2\2\2\2\7\3\2\2\2\2\t\3\2\2\2\2\17\3\2\2\2\2\21\3\2\2\2\2\23"+
		"\3\2\2\2\2\25\3\2\2\2\2\27\3\2\2\2\2\31\3\2\2\2\2\33\3\2\2\2\2\35\3\2"+
		"\2\2\2\37\3\2\2\2\2!\3\2\2\2\2#\3\2\2\2\2%\3\2\2\2\2\'\3\2\2\2\2)\3\2"+
		"\2\2\2+\3\2\2\2\2-\3\2\2\2\2/\3\2\2\2\2\61\3\2\2\2\2\63\3\2\2\2\2\65\3"+
		"\2\2\2\2\67\3\2\2\2\29\3\2\2\2\2;\3\2\2\2\2=\3\2\2\2\2?\3\2\2\2\2A\3\2"+
		"\2\2\2C\3\2\2\2\2E\3\2\2\2\2G\3\2\2\2\2I\3\2\2\2\2K\3\2\2\2\2M\3\2\2\2"+
		"\2O\3\2\2\2\2Q\3\2\2\2\2S\3\2\2\2\2U\3\2\2\2\2W\3\2\2\2\2Y\3\2\2\2\2["+
		"\3\2\2\2\2]\3\2\2\2\2_\3\2\2\2\2a\3\2\2\2\2c\3\2\2\2\2e\3\2\2\2\2g\3\2"+
		"\2\2\2i\3\2\2\2\2k\3\2\2\2\2m\3\2\2\2\2o\3\2\2\2\2q\3\2\2\2\3s\3\2\2\2"+
		"\5v\3\2\2\2\7|\3\2\2\2\t\u008a\3\2\2\2\13\u0095\3\2\2\2\r\u0097\3\2\2"+
		"\2\17\u009a\3\2\2\2\21\u009e\3\2\2\2\23\u00a6\3\2\2\2\25\u00b1\3\2\2\2"+
		"\27\u00b3\3\2\2\2\31\u00b5\3\2\2\2\33\u00b7\3\2\2\2\35\u00b9\3\2\2\2\37"+
		"\u00bb\3\2\2\2!\u00bd\3\2\2\2#\u00bf\3\2\2\2%\u00c1\3\2\2\2\'\u00c3\3"+
		"\2\2\2)\u00c6\3\2\2\2+\u00c8\3\2\2\2-\u00cb\3\2\2\2/\u00cd\3\2\2\2\61"+
		"\u00cf\3\2\2\2\63\u00d1\3\2\2\2\65\u00d3\3\2\2\2\67\u00d5\3\2\2\29\u00d7"+
		"\3\2\2\2;\u00d9\3\2\2\2=\u00db\3\2\2\2?\u00de\3\2\2\2A\u00e1\3\2\2\2C"+
		"\u00e4\3\2\2\2E\u00e7\3\2\2\2G\u00e9\3\2\2\2I\u00ec\3\2\2\2K\u00ee\3\2"+
		"\2\2M\u00f1\3\2\2\2O\u00f3\3\2\2\2Q\u00f6\3\2\2\2S\u00f9\3\2\2\2U\u00fd"+
		"\3\2\2\2W\u00ff\3\2\2\2Y\u0101\3\2\2\2[\u0105\3\2\2\2]\u010b\3\2\2\2_"+
		"\u0112\3\2\2\2a\u0116\3\2\2\2c\u011b\3\2\2\2e\u0120\3\2\2\2g\u0128\3\2"+
		"\2\2i\u012d\3\2\2\2k\u0137\3\2\2\2m\u013d\3\2\2\2o\u0144\3\2\2\2q\u014b"+
		"\3\2\2\2st\7=\2\2t\4\3\2\2\2uw\t\2\2\2vu\3\2\2\2wx\3\2\2\2xv\3\2\2\2x"+
		"y\3\2\2\2yz\3\2\2\2z{\b\3\2\2{\6\3\2\2\2|}\7\61\2\2}~\7,\2\2~\u0082\3"+
		"\2\2\2\177\u0081\13\2\2\2\u0080\177\3\2\2\2\u0081\u0084\3\2\2\2\u0082"+
		"\u0083\3\2\2\2\u0082\u0080\3\2\2\2\u0083\u0085\3\2\2\2\u0084\u0082\3\2"+
		"\2\2\u0085\u0086\7,\2\2\u0086\u0087\7\61\2\2\u0087\u0088\3\2\2\2\u0088"+
		"\u0089\b\4\2\2\u0089\b\3\2\2\2\u008a\u008b\7\61\2\2\u008b\u008c\7\61\2"+
		"\2\u008c\u0090\3\2\2\2\u008d\u008f\n\3\2\2\u008e\u008d\3\2\2\2\u008f\u0092"+
		"\3\2\2\2\u0090\u008e\3\2\2\2\u0090\u0091\3\2\2\2\u0091\u0093\3\2\2\2\u0092"+
		"\u0090\3\2\2\2\u0093\u0094\b\5\2\2\u0094\n\3\2\2\2\u0095\u0096\t\4\2\2"+
		"\u0096\f\3\2\2\2\u0097\u0098\t\5\2\2\u0098\16\3\2\2\2\u0099\u009b\5\13"+
		"\6\2\u009a\u0099\3\2\2\2\u009b\u009c\3\2\2\2\u009c\u009a\3\2\2\2\u009c"+
		"\u009d\3\2\2\2\u009d\20\3\2\2\2\u009e\u009f\7\62\2\2\u009f\u00a0\7z\2"+
		"\2\u00a0\u00a2\3\2\2\2\u00a1\u00a3\5\r\7\2\u00a2\u00a1\3\2\2\2\u00a3\u00a4"+
		"\3\2\2\2\u00a4\u00a2\3\2\2\2\u00a4\u00a5\3\2\2\2\u00a5\22\3\2\2\2\u00a6"+
		"\u00ac\7$\2\2\u00a7\u00a8\7^\2\2\u00a8\u00ab\13\2\2\2\u00a9\u00ab\n\6"+
		"\2\2\u00aa\u00a7\3\2\2\2\u00aa\u00a9\3\2\2\2\u00ab\u00ae\3\2\2\2\u00ac"+
		"\u00aa\3\2\2\2\u00ac\u00ad\3\2\2\2\u00ad\u00af\3\2\2\2\u00ae\u00ac\3\2"+
		"\2\2\u00af\u00b0\7$\2\2\u00b0\24\3\2\2\2\u00b1\u00b2\7}\2\2\u00b2\26\3"+
		"\2\2\2\u00b3\u00b4\7\177\2\2\u00b4\30\3\2\2\2\u00b5\u00b6\7*\2\2\u00b6"+
		"\32\3\2\2\2\u00b7\u00b8\7+\2\2\u00b8\34\3\2\2\2\u00b9\u00ba\7]\2\2\u00ba"+
		"\36\3\2\2\2\u00bb\u00bc\7_\2\2\u00bc \3\2\2\2\u00bd\u00be\7.\2\2\u00be"+
		"\"\3\2\2\2\u00bf\u00c0\7\60\2\2\u00c0$\3\2\2\2\u00c1\u00c2\7-\2\2\u00c2"+
		"&\3\2\2\2\u00c3\u00c4\7-\2\2\u00c4\u00c5\7-\2\2\u00c5(\3\2\2\2\u00c6\u00c7"+
		"\7/\2\2\u00c7*\3\2\2\2\u00c8\u00c9\7/\2\2\u00c9\u00ca\7/\2\2\u00ca,\3"+
		"\2\2\2\u00cb\u00cc\7,\2\2\u00cc.\3\2\2\2\u00cd\u00ce\7\61\2\2\u00ce\60"+
		"\3\2\2\2\u00cf\u00d0\7\'\2\2\u00d0\62\3\2\2\2\u00d1\u00d2\7(\2\2\u00d2"+
		"\64\3\2\2\2\u00d3\u00d4\7~\2\2\u00d4\66\3\2\2\2\u00d5\u00d6\7`\2\2\u00d6"+
		"8\3\2\2\2\u00d7\u00d8\7\u0080\2\2\u00d8:\3\2\2\2\u00d9\u00da\7#\2\2\u00da"+
		"<\3\2\2\2\u00db\u00dc\7(\2\2\u00dc\u00dd\7(\2\2\u00dd>\3\2\2\2\u00de\u00df"+
		"\7~\2\2\u00df\u00e0\7~\2\2\u00e0@\3\2\2\2\u00e1\u00e2\7?\2\2\u00e2\u00e3"+
		"\7?\2\2\u00e3B\3\2\2\2\u00e4\u00e5\7#\2\2\u00e5\u00e6\7?\2\2\u00e6D\3"+
		"\2\2\2\u00e7\u00e8\7>\2\2\u00e8F\3\2\2\2\u00e9\u00ea\7>\2\2\u00ea\u00eb"+
		"\7?\2\2\u00ebH\3\2\2\2\u00ec\u00ed\7@\2\2\u00edJ\3\2\2\2\u00ee\u00ef\7"+
		"@\2\2\u00ef\u00f0\7?\2\2\u00f0L\3\2\2\2\u00f1\u00f2\7?\2\2\u00f2N\3\2"+
		"\2\2\u00f3\u00f4\7c\2\2\u00f4\u00f5\7u\2\2\u00f5P\3\2\2\2\u00f6\u00f7"+
		"\7/\2\2\u00f7\u00f8\7@\2\2\u00f8R\3\2\2\2\u00f9\u00fa\7t\2\2\u00fa\u00fb"+
		"\7g\2\2\u00fb\u00fc\7v\2\2\u00fcT\3\2\2\2\u00fd\u00fe\7A\2\2\u00feV\3"+
		"\2\2\2\u00ff\u0100\7<\2\2\u0100X\3\2\2\2\u0101\u0102\7x\2\2\u0102\u0103"+
		"\7c\2\2\u0103\u0104\7t\2\2\u0104Z\3\2\2\2\u0105\u0106\7e\2\2\u0106\u0107"+
		"\7n\2\2\u0107\u0108\7c\2\2\u0108\u0109\7u\2\2\u0109\u010a\7u\2\2\u010a"+
		"\\\3\2\2\2\u010b\u010c\7u\2\2\u010c\u010d\7v\2\2\u010d\u010e\7t\2\2\u010e"+
		"\u010f\7w\2\2\u010f\u0110\7e\2\2\u0110\u0111\7v\2\2\u0111^\3\2\2\2\u0112"+
		"\u0113\7r\2\2\u0113\u0114\7w\2\2\u0114\u0115\7d\2\2\u0115`\3\2\2\2\u0116"+
		"\u0117\7r\2\2\u0117\u0118\7t\2\2\u0118\u0119\7k\2\2\u0119\u011a\7x\2\2"+
		"\u011ab\3\2\2\2\u011b\u011c\7r\2\2\u011c\u011d\7t\2\2\u011d\u011e\7q\2"+
		"\2\u011e\u011f\7v\2\2\u011fd\3\2\2\2\u0120\u0121\7x\2\2\u0121\u0122\7"+
		"k\2\2\u0122\u0123\7t\2\2\u0123\u0124\7v\2\2\u0124\u0125\7w\2\2\u0125\u0126"+
		"\7c\2\2\u0126\u0127\7n\2\2\u0127f\3\2\2\2\u0128\u0129\7y\2\2\u0129\u012a"+
		"\7k\2\2\u012a\u012b\7v\2\2\u012b\u012c\7j\2\2\u012ch\3\2\2\2\u012d\u012e"+
		"\7u\2\2\u012e\u012f\7v\2\2\u012f\u0130\7c\2\2\u0130\u0131\7v\2\2\u0131"+
		"\u0132\7g\2\2\u0132\u0133\7n\2\2\u0133\u0134\7g\2\2\u0134\u0135\7u\2\2"+
		"\u0135\u0136\7u\2\2\u0136j\3\2\2\2\u0137\u0138\7v\2\2\u0138\u0139\7t\2"+
		"\2\u0139\u013a\7c\2\2\u013a\u013b\7k\2\2\u013b\u013c\7v\2\2\u013cl\3\2"+
		"\2\2\u013d\u013e\7k\2\2\u013e\u013f\7o\2\2\u013f\u0140\7r\2\2\u0140\u0141"+
		"\7q\2\2\u0141\u0142\7t\2\2\u0142\u0143\7v\2\2\u0143n\3\2\2\2\u0144\u0145"+
		"\7o\2\2\u0145\u0146\7q\2\2\u0146\u0147\7f\2\2\u0147\u0148\7w\2\2\u0148"+
		"\u0149\7n\2\2\u0149\u014a\7g\2\2\u014ap\3\2\2\2\u014b\u014f\t\7\2\2\u014c"+
		"\u014e\t\b\2\2\u014d\u014c\3\2\2\2\u014e\u0151\3\2\2\2\u014f\u014d\3\2"+
		"\2\2\u014f\u0150\3\2\2\2\u0150r\3\2\2\2\u0151\u014f\3\2\2\2\13\2x\u0082"+
		"\u0090\u009c\u00a4\u00aa\u00ac\u014f\3\b\2\2";
	public static final ATN _ATN =
		new ATNDeserializer().deserialize(_serializedATN.toCharArray());
	static {
		_decisionToDFA = new DFA[_ATN.getNumberOfDecisions()];
		for (int i = 0; i < _ATN.getNumberOfDecisions(); i++) {
			_decisionToDFA[i] = new DFA(_ATN.getDecisionState(i), i);
		}
	}
}