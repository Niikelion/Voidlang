module Void.Parser(
    parseCode,
    module Void.Abs
) where

import Void.Abs
import Void.Par(pCode)
import Void.Lex(tokens)
import Control.Monad.Except (ExceptT, throwError)

parse :: String -> Either String Code
parse = pCode . tokens

parseCode :: Monad m => String -> ExceptT String m Code
parseCode source = either (throwError) return $ parse source