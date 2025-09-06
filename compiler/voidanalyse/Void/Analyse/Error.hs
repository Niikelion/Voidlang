module Void.Analyse.Error where
import Data.Char(toLower)

data ErrorType = Syntax | Semantic | Type deriving Show
data CodeError = CodeError ErrorType String (Maybe String) -- type error hint

instance Show CodeError where
    show (CodeError t msg hint) = (map toLower $ show t) ++ "error: " ++ msg ++ maybe "" (", " ++) hint

type ErrorFactory = String -> Maybe String -> CodeError

syntaxErr :: ErrorFactory
syntaxErr = CodeError Syntax

semanticErr :: ErrorFactory
semanticErr = CodeError Semantic

typeErr :: ErrorFactory
typeErr = CodeError Type