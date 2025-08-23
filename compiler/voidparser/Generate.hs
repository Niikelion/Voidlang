import System.Process

main :: IO ()
main = do
  callCommand "rm voidparser/Void/Abs.hs voidparser/Void/ErrM.hs voidparser/Void/Lex.hs voidparser/Void/Par.hs voidparser/Void/Print.hs voidparser/Void/Skel.hs || true"
  callCommand "cd voidparser && bnfc -d --functor -m void.bnf"
  callCommand "happy --array --info --ghc --coerce voidparser/Void/Par.y"
  callCommand "alex --ghc voidparser/Void/Lex.x"
  callCommand "rm voidparser/Void/Test.hs voidparser/Void/Doc.txt voidparser/Void/Par.y voidparser/Void/Lex.x voidparser/Makefile"