module Void.Parser(
    Module(..),
    parseCode,
    moduleFromCode,
    Ast.EntityId,
    Ast.EntityInfo,
    Ast.Entity(..),
) where

import qualified Void.Ast as Ast
import qualified Void.Abs as Abs
import qualified Void.Par as Par
import qualified Void.Lex as Lex

import Void.Module(moduleFromCode, Module(..))
import Control.Monad.Except (ExceptT, throwError)

parseCode :: Monad m => String -> ExceptT String m Abs.Code
parseCode source = do
    let result = Par.pCode $ Lex.tokens source
    either (throwError) return result