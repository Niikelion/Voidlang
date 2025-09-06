module Void.Compile(compileModule) where

import qualified Void.Ast as Ast
import qualified Void.IR as IR
import qualified Void.Analyse as Analyser
import qualified Void.Analyse.Setup as Setup
import qualified Data.Map as Map
import Control.Monad.Identity
import Control.Monad.State
import Void.Trans
import Data.Generics.Uniplate.Operations (transformBi)

globalName :: Ast.Entity -> String
globalName e@(Ast.EExternal {}) = Ast.nameOf e
globalName (Ast.EFunction ("main", _) _ _ _) = "main"
globalName e = (Ast.nameOf e) ++ "$" ++ (Ast.mangle $ Ast.typeOf e)

fixBlocks :: [IR.Block] -> [IR.Block]
fixBlocks = reverse . (map $ transformBi reverseInstrs)
    where
        reverseInstrs :: [IR.Instr] -> [IR.Instr]
        reverseInstrs = reverse

compileModule :: Setup.SetupState -> Analyser.Module -> IR.Module
compileModule s (Analyser.Code entities) = IR.Module definitions
    where
        entityList = map snd $ Map.toList entities
        runGlobal = (flip evalState $ GlobalEmitState entities) . runGlobalEmitT
        definitions = runGlobal $ emitEntities (Setup._implementations s) entityList

type GlobalEmit a = GlobalEmitT Identity a
type Emit m a = LocalEmitT (GlobalEmitT m) a

emitEntities :: Map.Map Int IR.Def -> [Ast.Entity] -> GlobalEmit [IR.Def]
emitEntities impls = mapM $ \e -> maybe (emitEntity e) return $ Map.lookup (Ast.idOf e) impls

emitEntity :: Ast.Entity -> GlobalEmit IR.Def
emitEntity e@(Ast.EFunction _ ret args stmt) = do
    let ret' = IR.typeOf ret
    let argTypes = map (IR.typeOf . Ast.typeOf) args
    let sig = IR.Fun ret' argTypes
    (args', resultState) <- runLocal $ do
        args' <- mapM (\arg -> do
                freshId <- freshLocalEntityId
                insertGlobalLocalMapping (Ast.idOf arg) freshId
                return freshId
            ) args
        blockId <- freshLocalBlockId
        startLocalBlock blockId
        emitStatement stmt
        return args'
    let blocks = fixBlocks $ localBlocks resultState
    return $ IR.FunDef sig args' (globalName e) $ ensureSSA [0..argCount-1] blocks
    where
        argCount = length args
        runLocal = (flip runStateT $ emptyLocalState 0) . runLocalEmitT
emitEntity e@(Ast.EExternal _ t) = return $ IR.ExtDef (IR.typeOf t) $ Ast.nameOf e
emitEntity _ = error "entities other than functions not supported"

emitStatement :: Monad m => Ast.Statement -> Emit m ()
emitStatement (Ast.SBlock stmts _) = mapM_ emitStatement stmts
emitStatement (Ast.SReturn (Just e)) = do
    result <- emitExpression e
    ir [ IR.IRet $ Just result ]
emitStatement (Ast.SReturn Nothing) = ir [ IR.IRet Nothing ]
emitStatement (Ast.SExpression e) = do
    _ <- emitExpression e
    return ()

emitExpression :: Monad m => Ast.Expression -> Emit m (IR.Val)
emitExpression (Ast.EBool v) = return $ IR.bool v
emitExpression (Ast.EInt v) = return $ IR.int v
emitExpression (Ast.EString _) = error "string expressions not supported"
emitExpression (Ast.ENamed (_, targetId) t) = do
    let t' = IR.typeOf t
    findGlobalEntity targetId >>= \e -> case e of
        Nothing -> mapGlobalToLocal targetId >>= return . (IR.VLocal t')
        Just e' -> return $ IR.VGlobal t' $ globalName e'
emitExpression (Ast.ECall target args) = do
    target' <- emitExpression target
    args' <- mapM emitExpression args
    freshId <- freshLocalEntityId
    let callE = IR.ECall (IR.typeOf target') target' args'
    ir [ IR.IAssign freshId callE ]
    return $ IR.VLocal (IR.typeOf callE) freshId

ir :: Monad m => [IR.Instr] -> Emit m ()
ir instrs = modifyLocalState $ \s -> s { localBlocks = insertToTop $ localBlocks s }
    where
        insertToTop :: [IR.Block] -> [IR.Block]
        insertToTop [] = error "cannot insert instruction when no block is present"
        insertToTop (h:t) = ((flip transformBi) h $ ((reverse instrs) ++)):t

findGlobalEntity :: Monad m => Ast.EntityId -> Emit m (Maybe Ast.Entity)
findGlobalEntity entityId = globalState $ \s -> Map.lookup entityId $ entities s

globalState :: Monad m => (GlobalEmitState -> a) -> Emit m a
globalState = lift . GlobalEmitT . gets

startLocalBlock :: Monad m => Int -> Emit m ()
startLocalBlock blockId = pushLocalBlock $ IR.Block blockId []

pushLocalBlock :: Monad m => IR.Block -> Emit m ()
pushLocalBlock block = modifyLocalState $ \s -> s { localBlocks = block : localBlocks s }

freshLocalEntityId :: Monad m => Emit m Int
freshLocalEntityId = localState $ \s ->
        let n = nextLocalEntityId s in (n, s { nextLocalEntityId = n + 1 })

freshLocalBlockId :: Monad m => Emit m Int
freshLocalBlockId = localState $ \s ->
        let n = nextLocalBlockId s in (n, s { nextLocalBlockId = n + 1 })

mapGlobalToLocal :: Monad m => Ast.EntityId -> Emit m Int
mapGlobalToLocal entityId = do
    result <- getLocalState $ \s -> Map.lookup entityId $ globalLocalMapping s
    case result of
        Nothing -> error "internal error, missing global -> local mapping"
        Just localId -> return localId

insertGlobalLocalMapping :: Monad m => Ast.EntityId -> Int -> Emit m ()
insertGlobalLocalMapping entityId localId = modifyLocalState $ \s -> s {
        globalLocalMapping = Map.insert entityId localId $ globalLocalMapping s
    }

getLocalState :: Monad m => (LocalEmitState -> a) -> Emit m a
getLocalState f = localState $ \s -> (f s, s)

modifyLocalState :: Monad m => (LocalEmitState -> LocalEmitState) -> Emit m ()
modifyLocalState f = localState $ \s -> ((), f s)

localState :: Monad m => (LocalEmitState -> (a, LocalEmitState)) -> Emit m a
localState = LocalEmitT . state

data LocalEmitState = LocalEmitState {
    globalLocalMapping :: Map.Map Ast.EntityId Int,
    nextLocalEntityId :: Int,
    nextLocalBlockId :: Int,
    localBlocks :: [IR.Block]
}

emptyLocalState :: Int -> LocalEmitState
emptyLocalState argCount = LocalEmitState Map.empty argCount 0 []

newtype LocalEmitT m a = LocalEmitT {
    runLocalEmitT :: StateT LocalEmitState m a
} deriving (Functor, Applicative, Monad)
instance MonadTrans LocalEmitT where lift = LocalEmitT . lift

data GlobalEmitState = GlobalEmitState {
    entities :: Map.Map Ast.EntityId Ast.Entity
}

newtype GlobalEmitT m a = GlobalEmitT {
    runGlobalEmitT :: StateT GlobalEmitState m a
} deriving (Functor, Applicative, Monad)
instance MonadTrans GlobalEmitT where lift = GlobalEmitT . lift