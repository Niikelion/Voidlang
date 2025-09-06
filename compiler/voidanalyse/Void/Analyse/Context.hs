{-# LANGUAGE TemplateHaskell #-}
module Void.Analyse.Context (
    Position(..),
    Positional(..),
    PositionalError(..),
    NameMapping,
    Scope(..),
    nameMapping,
    scopeReturnType,
    scopeClosed,
    emptyScope,
    AnalyserState(..),
    resolverEntities,
    operatorPrecedences,
    scopeStack,
    Analyser(..),
    execAnalyser,
    liftGlobal,
    liftScope,
    global,
    scoped,
    freshId,
    popScope,
    pushScopeWithReturnType,
    pushScope,
    closeCurrentScope,
    modifyNameMapping,
    throwE,
    at
) where

import Control.Lens.TH
import Control.Lens hiding ((<|), at)
import qualified Data.Map as Map
import Data.List.NonEmpty(NonEmpty(..), (<|), nonEmpty)
import Void.Ast hiding (Entity, Arg, debugName)
import qualified Void.Parser as Parser

import Control.Monad.State(MonadTrans(..), StateT(..), State, modify, MonadState(state), runState, execStateT)
import Control.Monad.Except(MonadError(throwError), Except, runExcept)
import qualified Void.Ast

data Position = Pos {
    line :: Int,
    col :: Int
}
instance Show Position where show (Pos l c) = "(" ++ show l ++ "," ++ show c ++ ")"

class Positional a where pos :: a -> Maybe Position

instance Positional (Maybe (Int, Int)) where pos = maybe Nothing $ Just . (uncurry Pos)
instance Positional Parser.Exp where pos = pos . Parser.hasPosition
instance Positional Parser.Type where pos = pos . Parser.hasPosition
instance Positional Parser.Stmt where pos = pos . Parser.hasPosition

data PositionalError a = Show a => ErrorAt (Maybe Position) a
instance Show a => Show (PositionalError a) where show (ErrorAt p v) = (maybe "" ((++ ": ") . show) p) ++ show v
instance Show a => Positional (PositionalError a) where pos (ErrorAt p _) = p

type NameMapping = Map.Map String Int

debugName :: (Named a, Identifiable a) => a -> String
debugName e = (nameOf e) ++ "@" ++ (show $ idOf e)

data Arg = Arg String Int Type (Maybe Expression)
instance Typed Arg where typeOf (Arg _ _ t _) = t
instance Named Arg where nameOf (Arg n _ _ _) = n
instance Identifiable Arg where idOf (Arg _ i _ _) = i
instance Show Arg where
    show a@(Arg _ _ t v) = debugName a ++ ": " ++ show t ++ initPart
        where
            initPart :: String
            initPart = (maybe "" ((" = " ++) . show) v)

data UnqualifiedEntity
    = Function Type [Arg] Statement
    | External Type
instance Typed UnqualifiedEntity where
    typeOf (Function ret args _) = TFunction ret $ map typeOf args
    typeOf (External t) = t

data Entity = Entity String Int UnqualifiedEntity
instance Typed Entity where typeOf (Entity _ _ e) = typeOf e
instance Named Entity where nameOf (Entity n _ _) = n
instance Identifiable Entity where idOf (Entity _ i _) = i

data Scope = Scope {
    _nameMapping :: NameMapping,
    _scopeReturnType :: Type,
    _scopeClosed :: Bool
}
makeLenses ''Scope

emptyScope :: Scope
emptyScope = Scope Map.empty TVoid False

data AnalyserState = AnalyserState {
    _nextGlobalId :: Int,
    _resolverEntities :: Map.Map Int Void.Ast.Entity,
    _operatorPrecedences :: Map.Map String Int,
    _scopeStack :: NonEmpty Scope
}
makeLenses ''AnalyserState

newtype Analyser a = Analyser {
    runAnalyser :: StateT AnalyserState (Except String) a
} deriving (Functor, Applicative, Monad)

execAnalyser :: AnalyserState -> Analyser a -> Either String AnalyserState
execAnalyser s m = runExcept $ execStateT (runAnalyser m) s

liftGlobal :: State AnalyserState a -> Analyser a
liftGlobal = Analyser . state . runState

global :: (a -> State AnalyserState a') -> a -> Analyser a'
global = (liftGlobal .)

liftScope :: State Scope a -> Analyser a
liftScope m = liftGlobal $ state $ \s ->
        let (top :| rest) = s^.scopeStack
            (r, top') = runState m top
        in (r, s & scopeStack .~ top' :| rest)

scoped :: (a -> State Scope a') -> a -> Analyser a'
scoped = (liftScope .)

freshId :: Analyser Int
freshId = liftGlobal $ nextGlobalId <<+= 1

popScope :: Analyser Scope
popScope = do
    scope <- global state $ \s -> let h :| t = s ^. scopeStack in (h, s & scopeStack .~ assertJust (nonEmpty t))
    let toDelete = map snd $ Map.toList $ _nameMapping scope
    global modify (& resolverEntities %~ (\e -> foldl (flip Map.delete) e toDelete))
    return scope
    where
        assertJust :: Maybe a -> a
        assertJust Nothing = error "internal error, unexpected nothing"
        assertJust (Just a) = a

pushScopeWithReturnType :: Type -> Analyser ()
pushScopeWithReturnType t = liftGlobal $ scopeStack %= ((emptyScope & scopeReturnType .~ t) <|)

pushScope :: Analyser ()
pushScope = scoped use scopeReturnType >>= pushScopeWithReturnType

closeCurrentScope :: Analyser ()
closeCurrentScope = liftScope $ scopeClosed .= True

modifyNameMapping :: (NameMapping -> NameMapping) -> Analyser ()
modifyNameMapping = liftScope . (nameMapping %=)

throwE :: Show a => a -> Analyser b
throwE = Analyser . lift . throwError . show

at :: (Positional a, Show b) => a -> (PositionalError b -> Analyser c) -> b -> Analyser c
at target b e = b (ErrorAt (pos target) e)