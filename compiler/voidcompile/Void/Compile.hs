module Void.Compile(compileModule) where

import qualified Void.Parser as Parser
import qualified Void.Ast as Ast
import qualified Void.IR as IR
import qualified Data.Map as Map
import Control.Monad.Identity
import Control.Monad.State
import Void.Trans
import Data.Generics.Uniplate.Operations (transformBi)

globalName :: Parser.Entity -> String
globalName e@(Parser.EExternal {}) = Ast.nameOf e
globalName e = (Ast.nameOf e) ++ "$" ++ (Ast.mangle $ Ast.typeOf e)

compileModule :: Parser.Module -> IR.Module
compileModule (Parser.Code entities) = IR.Module definitions
    where
        entityList = map snd $ Map.toList entities
        runGlobal = (flip evalState $ GlobalEmitState entities) . runGlobalEmitT
        definitions = runGlobal $ emitEntities entityList

type GlobalEmit a = GlobalEmitT Identity a
type Emit m a = LocalEmitT (GlobalEmitT m) a

emitEntities :: [Parser.Entity] -> GlobalEmit [IR.Def]
emitEntities = mapM emitEntity

emitEntity :: Parser.Entity -> GlobalEmit IR.Def
emitEntity e@(Parser.EFunction _ ret args stmt) = do
    ret' <- mapType ret
    argTypes <- mapM (mapType . Ast.typeOf) args
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
    return $ IR.FunDef sig args' (globalName e) $ ensureSSA [0..argCount-1] $ reverse $ map (transformBi reverseInstrs) $ localBlocks resultState
    where
        reverseInstrs :: [IR.Instr] -> [IR.Instr]
        reverseInstrs = reverse
        argCount = length args
        runLocal = (flip runStateT $ emptyLocalState 0) . runLocalEmitT
emitEntity e@(Parser.EExternal _ t) = do
    t' <- mapType t
    return $ IR.ExtDef t' $ Ast.nameOf e
emitEntity _ = error "entities other than functions not supported"

mapType :: Monad m => Ast.Type -> GlobalEmitT m IR.Type
mapType (Ast.TVoid) = return IR.Void
mapType (Ast.TBool) = return IR.boolType
mapType (Ast.TInt) = return IR.intType
mapType (Ast.TString) = return IR.stringType
mapType (Ast.TOptional t) = do -- TODO: register struct and make exception for pointers
    t' <- mapType t
    return $ IR.Struct [IR.boolType, t']
mapType (Ast.TUnion _) = error "unions not supported"
mapType (Ast.TArray t) = do
    t' <- mapType t
    return $ IR.arrayType t'
mapType (Ast.TName i) = return $ IR.Class $ show i
mapType (Ast.TStruct members) = mapM (\(Ast.TStructMember _ t) -> mapType t) members >>= (return . IR.Struct)
mapType (Ast.TFunction ret args) = do
    ret' <- mapType ret
    args' <- mapM mapType args
    return $ IR.Fun ret' args'
mapType (Ast.TTuple args) = mapM mapType args >>= (return . IR.Struct)

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
    t' <- lift $ mapType t
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

findGlobalEntity :: Monad m => Parser.EntityId -> Emit m (Maybe Parser.Entity)
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

mapGlobalToLocal :: Monad m => Parser.EntityId -> Emit m Int
mapGlobalToLocal entityId = do
    result <- getLocalState $ \s -> Map.lookup entityId $ globalLocalMapping s
    case result of
        Nothing -> error "internal error, missing global -> local mapping"
        Just localId -> return localId

insertGlobalLocalMapping :: Monad m => Parser.EntityId -> Int -> Emit m ()
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
    globalLocalMapping :: Map.Map Parser.EntityId Int,
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
    entities :: Map.Map Parser.EntityId Parser.Entity
}

newtype GlobalEmitT m a = GlobalEmitT {
    runGlobalEmitT :: StateT GlobalEmitState m a
} deriving (Functor, Applicative, Monad)
instance MonadTrans GlobalEmitT where lift = GlobalEmitT . lift