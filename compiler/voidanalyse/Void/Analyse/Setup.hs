{-# LANGUAGE TemplateHaskell #-}
module Void.Analyse.Setup where

import Control.Lens.TH
import Control.Lens hiding ((<|), at)
import qualified Data.Map as Map
import qualified Void.Analyse.Context as Context
import Control.Monad.State(State, modify, execState)
import qualified Void.Ast as Ast
import qualified Void.IR as IR
import Data.List

instance IR.Typed Ast.Type where
    typeOf t = case t of
        Ast.TVoid -> IR.Void
        Ast.TBool -> IR.boolType
        Ast.TInt -> IR.intType
        Ast.TString -> IR.stringType
        Ast.TOptional t' -> IR.Struct [IR.boolType, IR.typeOf t']
        Ast.TUnion _ -> error "unions not supported"
        Ast.TArray t' -> IR.arrayType $ IR.typeOf t'
        Ast.TName i -> error "named types not supported"
        Ast.TStruct members -> error "structs not supported"
        Ast.TFunction ret args -> IR.Fun (IR.typeOf ret) (map IR.typeOf args)
        Ast.TTuple members -> IR.Struct $ map IR.typeOf members

data SetupState = SetupState {
    _nextGlobalId :: Int,
    _resolverEntities :: Map.Map Ast.EntityId Ast.Entity,
    _implementations :: Map.Map Ast.EntityId IR.Def,
    _operatorPrecedences :: Map.Map String Int,
    _globalScope :: Context.Scope
}
makeLenses ''SetupState

type Setup a = State SetupState a

execSetup :: Setup a -> SetupState
execSetup m = execState m $ SetupState (-1) (Map.empty) (Map.empty) (Map.empty) $ Context.emptyScope

freshId :: Setup Int
freshId = nextGlobalId <<-= 1

makeEntity :: (Ast.EntityId -> Ast.Entity) -> Setup Ast.Entity
makeEntity factory = do
    entity <- freshId <&> factory
    modify (& resolverEntities %~ Map.insert (Ast.idOf entity) entity)
    return entity

implementFunction :: Ast.Entity -> [IR.Block] -> Setup ()
implementFunction entity body = do
    let entityId = Ast.idOf entity
    let sig = Ast.typeOf entity
    let argCount = case sig of
            Ast.TFunction _ args -> length args
            _ -> error "trying to implement non-function entity"
    let impl = IR.FunDef (IR.typeOf sig) [0 .. argCount - 1] (Ast.nameOf entity) body
    modify (& implementations %~ Map.insert entityId impl)

makeOperator :: String -> Int -> Ast.Entity -> Setup ()
makeOperator name precedence target = do
    modify (& operatorPrecedences %~ Map.insert name precedence)
    modify (& globalScope . Context.nameMapping %~ Map.insert name (Ast.idOf target))