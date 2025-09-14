{-# LANGUAGE TemplateHaskell #-}
module Void.Compile(compileModule) where

import qualified Void.Ast as Ast
import qualified Void.IR as IR
import qualified Void.Analyse as Analyser
import qualified Void.Analyse.Setup as Setup
import qualified Data.Map as Map
import Control.Monad.State
import Control.Monad
import Void.Trans
import Control.Lens.TH
import Control.Lens hiding ((<|), at)
import Data.Generics.Uniplate.Operations(transformBi)
import Control.Monad.Reader hiding (local)

data EmitState = EmitState {
    _idMapping :: Map.Map Int Int, -- global -> local
    _nextVarId :: Int,
    _nextBlockId :: Int,
    _emittedBlocks :: [IR.Block]
}
makeLenses ''EmitState

type EntityMap = Map.Map Int Ast.Entity

liftGlobal :: GlobalEmit a -> Emit a
liftGlobal = lift

liftBlock :: State IR.Block a -> Emit a
liftBlock m = liftLocal $ state $ \s -> case s^.emittedBlocks of
        [] -> (evalState m $ IR.Block 0 [], s)
        h:t -> let (r, h') = runState m h in (r, s & emittedBlocks .~ h':t )

liftLocal :: State EmitState a -> Emit a
liftLocal m = StateT (return . (runState m))

type GlobalEmit a = Reader EntityMap a
type Emit a = StateT EmitState (Reader EntityMap) a

emptyEmitState :: EmitState
emptyEmitState = EmitState Map.empty 0 1 [ IR.Block 0 [] ]

runEmit :: EmitState -> Emit a -> GlobalEmit (a, EmitState)
runEmit s m = runStateT m s

globalName :: Ast.Entity -> String
globalName e@(Ast.EExternal {}) = Ast.nameOf e
globalName (Ast.EFunction ("main", _) _ _ _) = "main"
globalName e = (Ast.nameOf e) ++ "$" ++ (Ast.mangle $ Ast.typeOf e)

compileModule :: Setup.SetupState -> Analyser.Module' -> IR.Module
compileModule s (Analyser.Code entities) = IR.Module definitions
    where
        entityList = map snd $ Map.toList entities
        runGlobal = (flip runReader entities)
        definitions = runGlobal $ emitEntities (Setup._implementations s) entityList

emitEntities :: Map.Map Int IR.Def -> [Ast.Entity] -> GlobalEmit [IR.Def]
emitEntities impls = mapM $ \e -> maybe (emitEntity e) return $ Map.lookup (Ast.idOf e) impls

emitEntity :: Ast.Entity -> GlobalEmit IR.Def
emitEntity e@(Ast.EFunction _ ret args stmt) = do
    let ret' = IR.typeOf ret
    let argTypes = map (IR.typeOf . Ast.typeOf) args
    let sig = IR.Fun ret' argTypes
    (args', resultState) <- runEmit emptyEmitState $ do
        args' <- mapM (\arg -> do
                freshId <- freshLocalEntityId
                insertGlobalLocalMapping (Ast.idOf arg) freshId
                return freshId
            ) args
        blockId <- freshLocalBlockId
        startLocalBlock blockId
        emitStatement stmt
        return args'
    let blocks = IR.fixBlocks $ resultState^.emittedBlocks
    return $ IR.FunDef sig args' (globalName e) $ ensureSSA [0..length args-1] blocks
emitEntity e@(Ast.EExternal _ t) = return $ IR.ExtDef (IR.typeOf t) $ Ast.nameOf e
emitEntity _ = error "entities other than functions not supported"

emitStatement :: Ast.Statement -> Emit ()
emitStatement (Ast.SBlock stmts _) = mapM_ emitStatement stmts
emitStatement (Ast.SReturn (Just e)) = do
    result <- emitExpression e
    ir $ IR.IRet $ Just result
emitStatement (Ast.SReturn Nothing) = ir $ IR.IRet Nothing
emitStatement (Ast.SExpression e) = do
    void $ emitExpression e
    return ()
emitStatement (Ast.SIf e t Nothing) = do
    cond <- emitExpression e
    trueBranchId <- freshLocalBlockId
    targetBlockId <- freshLocalBlockId
    ir $ IR.ICond cond trueBranchId targetBlockId
    startLocalBlock trueBranchId
    emitStatement t
    needsJump <- liftBlock $ gets IR.blockJumpTargets <&> null
    when needsJump $ ir $ IR.IJump targetBlockId
    startLocalBlock targetBlockId
emitStatement (Ast.SIf e t (Just f)) = do
    cond <- emitExpression e
    trueBranchId <- freshLocalBlockId
    falseBranchId <- freshLocalBlockId
    targetBlockId <- freshLocalBlockId
    ir $ IR.ICond cond trueBranchId falseBranchId
    startLocalBlock trueBranchId
    emitStatement t
    trueNeedsJump <- liftBlock $ gets IR.blockJumpTargets <&> null
    when trueNeedsJump $ ir $ IR.IJump targetBlockId
    startLocalBlock falseBranchId
    emitStatement f
    falseNeedsJump <- liftBlock $ gets IR.blockJumpTargets <&> null
    when falseNeedsJump $ ir $ IR.IJump targetBlockId
    startLocalBlock targetBlockId

emitExpression :: Ast.Expression -> Emit (IR.Val)
emitExpression (Ast.EBool v) = return $ IR.bool v
emitExpression (Ast.EInt v) = return $ IR.int v
emitExpression (Ast.EString _) = error "string expressions not supported"
emitExpression (Ast.ENamed (_, targetId) t) = do
    let t' = IR.typeOf t
    findGlobalEntity targetId >>= \e -> case e of
        Nothing -> mapGlobalToLocal targetId <&> IR.VLocal t'
        Just e' -> return $ IR.VGlobal t' $ globalName e'
emitExpression (Ast.ECall target args) = do
    target' <- emitExpression target
    args' <- mapM emitExpression args
    freshId <- freshLocalEntityId
    let callE = IR.ECall (IR.typeOf target') target' args'
    ir $ IR.IAssign freshId callE
    return $ IR.VLocal (IR.typeOf callE) freshId

ir :: IR.Instr -> Emit ()
ir instr = liftLocal $ modify (& emittedBlocks %~ insertToTop)
    where
        insertToTop :: [IR.Block] -> [IR.Block]
        insertToTop [] = error "cannot insert instruction when no block is present"
        insertToTop (h:t) = ((flip transformBi) h (instr :)):t

findGlobalEntity :: Ast.EntityId -> Emit (Maybe Ast.Entity)
findGlobalEntity entityId = liftGlobal ask <&> Map.lookup entityId

startLocalBlock :: Int -> Emit ()
startLocalBlock blockId = pushLocalBlock $ IR.Block blockId []

pushLocalBlock :: IR.Block -> Emit ()
pushLocalBlock b = liftLocal $ emittedBlocks %= (b:)

freshLocalEntityId :: Emit Int
freshLocalEntityId = liftLocal $ nextVarId <<+= 1

freshLocalBlockId :: Emit Int
freshLocalBlockId = liftLocal $ nextBlockId <<+= 1

mapGlobalToLocal :: Ast.EntityId -> Emit Int
mapGlobalToLocal entityId = do
    result <- liftLocal (use idMapping) <&> Map.lookup entityId
    maybe (error "internal error, missing global -> local mapping") return result

insertGlobalLocalMapping :: Ast.EntityId -> Int -> Emit ()
insertGlobalLocalMapping entityId localId = liftLocal $ idMapping %= Map.insert entityId localId