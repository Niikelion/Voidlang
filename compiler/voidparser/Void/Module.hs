{-# LANGUAGE TemplateHaskell #-}
module Void.Module (moduleFromCode, Module(..)) where

import Void.Abs()
import Void.Ast
import qualified Void.Rebalance as Rebalance
import qualified Data.Map as Map
import qualified Data.Set as Set
import Control.Monad.State( MonadTrans(..), StateT(..), gets, modify, MonadState(state) )
import Control.Monad.Except( ExceptT, MonadError(throwError) )
import Data.Maybe(isJust)
import Control.Monad
import Data.Functor((<&>))
import Control.Lens((^.), (.~), (&), (%~), to)
import Control.Lens.TH
import qualified Void.Abs as Abs

data Scope = Scope {
    _nameMapping :: Map.Map String EntityId,
    _scopeReturnType :: Type,
    _scopeClosed :: Bool
}
makeLenses ''Scope

emptyScope :: Scope
emptyScope = Scope Map.empty TVoid False

data EntityResolverState = EntityResolver {
    _resolverEntities :: Map.Map EntityId Entity,
    _operatorPrecedences :: Map.Map String Int,
    _scopeStack :: [Scope]
}
makeLenses ''EntityResolverState

data CodeError
    = SyntaxE String (Maybe String) -- SyntaxE error hint?
    | SemanticE String (Maybe String) -- SemanticE error hint?
    | TypeE String (Maybe String)   -- TypeE error hint?
instance Show CodeError where
    show e = let (t, msg, hint) = unpackCodeError e in t ++ ": " ++ msg ++ maybe "" (", " ++) hint

unpackCodeError :: CodeError -> (String, String, Maybe String)
unpackCodeError (SyntaxE msg hint) = ("syntax error", msg, hint)
unpackCodeError (SemanticE msg hint) = ("semantic error", msg, hint)
unpackCodeError (TypeE msg hint) = ("type error", msg, hint)

notInScope :: String -> CodeError
notInScope name = SemanticE ("could not find " ++ name) Nothing

data Module = Code (Map.Map EntityId Entity)
instance Show Module where
    show (Code entities) = unlines $ map (("\n" ++) . show . snd) $ Map.toList entities

_precedences :: Map.Map String Int
_precedences = Map.fromList [
        ("+", 5)
    ]

_entities :: Map.Map EntityId Entity
_entities = Map.fromList [
        (-1, EExternal ("$add_int_int", -1) $ TFunction TInt [TInt, TInt])
    ]

_scope :: Scope
_scope = emptyScope & nameMapping .~ Map.fromList [
        ("+", -1)
    ]

moduleFromCode :: Monad m => Abs.Code -> ExceptT String m Module
moduleFromCode (Abs.Void _ defs) = do
    (_, _, EntityResolver entities _ _) <- runEntityResolver 1 (EntityResolver _entities _precedences [_scope]) $ do
        mapM_ forwardDeclareTopEntity defs
        mapM_ resolveTopEntity defs
    return $ Code entities

forwardDeclareTopEntity :: Monad m => Abs.TopDef -> EntityResolverT (ExceptT String m) ()
forwardDeclareTopEntity (Abs.FunDef _ (Abs.Ident name) params ret _) = do
    argTypes <- mapM (\(Abs.ArgDef _ _ t) -> resolveType t) params
    returnType <- resolveType ret
    forwardDeclare name $ TFunction returnType argTypes

resolveTopEntity :: Monad m => Abs.TopDef -> EntityResolverT (ExceptT String m) ()
resolveTopEntity (Abs.FunDef _ (Abs.Ident name) params ret body) = do
    returnType <- resolveType ret
    pushScopeWithReturnType returnType
    params' <- mapM resolveArgDef params
    body' <- case body of --TODO: switch from type equality to type assignability
        Abs.BlockBody _ block -> do
            block' <- resolveBlock block
            case block' of
                SBlock _ closed ->
                    when (not closed && returnType /= TVoid) $ lift $ throwError "not all paths return a value"
                _ ->
                    lift $ throwError "internal error, resolveBlock did not return a block"
            return $ ensureClosedBlock block'
        Abs.ExpBody _ stmt -> do
            stmt' <- resolveStatement stmt
            case stmt' of
                SExpression exp' -> do
                    when (typeOf exp' /= returnType) $ lift $ throwError "return type does not match"
                    return $ SBlock [SReturn $ Just exp'] True
                _ -> lift $ throwError "this statement is not a valid function body"
    popScope_
    declareEntity_ name $ \entityId -> EFunction (name, entityId) returnType params' body'

resolveBlock :: Monad m => Abs.StmtBlock -> EntityResolverT (ExceptT String m) Statement
resolveBlock (Abs.Block _ stmts) = do
    pushScope
    stmts' <- mapM resolveStatement stmts
    closed <- popScope <&> (^.scopeClosed)
    when closed closeCurrentScope
    return $ SBlock stmts' closed


resolveArgDef :: Monad m => Abs.ArgumentDef -> EntityResolverT (ExceptT String m) Arg
resolveArgDef (Abs.ArgDef _ (Abs.Ident name) t) = do
    argType <- resolveType t
    entityId <- declareEntity name $ \entityId -> EVariable (name, entityId) argType
    return $ Arg (name, entityId) argType Nothing

flatUnionType :: Type -> Type -> Type
flatUnionType a b = simplifyUnion $ TUnion $ Set.fromList [a, b]

simplifyUnion :: Type -> Type
simplifyUnion (TUnion m) = case keepers of
    [] -> TVoid -- Should not happen, just in case
    [x] -> x
    xs -> TUnion $ Set.fromList xs
    where
        flatten :: Set.Set Type -> Set.Set Type
        flatten = (foldl (\acc -> (Set.union acc) . flatten . unionTypes) Set.empty) . Set.toList

        flat :: [Type]
        flat = Set.toList $ flatten m

        isStrictlyCoveredBy :: Type -> Type -> Bool
        isStrictlyCoveredBy wider narrower = assignable wider narrower && not (assignable narrower wider)

        dominated :: Type -> Bool
        dominated t = any (\u -> u /= t && isStrictlyCoveredBy u t) flat

        keepers :: [Type]
        keepers = filter (not . dominated) flat
simplifyUnion t = t

resolveType :: Monad m => Abs.Type -> EntityResolverT (ExceptT String m) Type
resolveType (Abs.TVoid _) = return TVoid
resolveType (Abs.TBool _) = return TBool
resolveType (Abs.TInt _) = return TInt
resolveType (Abs.TString _) = return TString
resolveType (Abs.TNamed pos (Abs.Ident name)) = do
    target <- findEntityByName name
    let t = maybe Nothing asType target
    maybe (throwE pos $ notInScope name) return t
resolveType (Abs.TArray _ element) = resolveType element >>= return . TArray
resolveType (Abs.TUnion _ a b) = do
    aType <- resolveType a
    bType <- resolveType b
    return $ flatUnionType aType bType
resolveType (Abs.TFunc _ args ret) = do
    argsType <- resolveType args
    returnType <- resolveType ret
    return $ TFunction returnType $ tupleTypes argsType
resolveType (Abs.TOptional _ inner) = resolveType inner >>= return . TOptional
resolveType (Abs.TTuple _ elements) = do
    elementTypes <- mapM resolveType elements
    return $ case elementTypes of
        [t] -> t
        _ -> TTuple elementTypes

resolveStatement :: Monad m => Abs.Stmt -> EntityResolverT (ExceptT String m) Statement
resolveStatement (Abs.SBlock _ block) = resolveBlock block
resolveStatement (Abs.SExp _ e) = resolveExpression e <&> SExpression
resolveStatement (Abs.SReturn _ e) = do
    e' <- resolveExpression e
    t' <- getsInScope _scopeReturnType
    when (typeOf e' /= t') $ lift $ throwError "type does not match"
    closeCurrentScope
    return $ SReturn $ Just e'
resolveStatement (Abs.SVoidReturn _) = do
    closeCurrentScope
    return $ SReturn Nothing

resolveExpression :: Monad m => Abs.Exp -> EntityResolverT (ExceptT String m) Expression
resolveExpression (Abs.ETrue _) = return $ EBool True
resolveExpression (Abs.EFalse _) = return $ EBool False
resolveExpression (Abs.EInt _ v) = return $ EInt $ fromInteger v
resolveExpression (Abs.EString _ v) = return $ EString v
resolveExpression (Abs.EVar pos (Abs.Ident name)) = do
    target <- findEntityByName name
    case target of
        Just entity -> return $ ENamed (entityInfo entity) $ typeOf entity
        Nothing -> throwE pos $ notInScope name
resolveExpression (Abs.ECall _ target (Abs.ETuple _ args)) = do
    target' <- resolveExpression target
    args' <- mapM resolveExpression args
    case typeOf target' of
        TFunction _ argTypes -> do
            when (length argTypes /= length args') $ lift $ throwError "mismatched amount of arguments"
            (mapM (uncurry convertValueToType) $ zip argTypes args') <&> ECall target'
        _ -> lift $ throwError "expression not callable"
resolveExpression (Abs.ECall {}) = error "internal error: function call without arguments"
resolveExpression e@(Abs.EBinOp {}) = do
    tree <- extractBinaryOperatorTree e
    let result = Rebalance.rebalance (\(p, _, _) -> p) (const Rebalance.LeftA) tree
    resolveBinaryOperatorTree result
resolveExpression (Abs.EPrefOp _ _ _) = lift $ throwError "prefops not supported"
resolveExpression (Abs.EPostOp _ _ _) = lift $ throwError "postops not supported"
resolveExpression (Abs.ETuple _ _) = lift $ throwError "tuples not supported"

type OpExpr = Rebalance.Expr (Int, String, Abs.BNFC'Position) Expression
instance Abs.HasPosition (Maybe (Int, Int)) where hasPosition = id

extractBinaryOperatorTree :: Monad m => Abs.Exp -> EntityResolver m OpExpr
extractBinaryOperatorTree e@(Abs.EBinOp p l (Abs.Op op) r) = do
    when (isUnOp l) $ throwE l ambiguousE
    when (isUnOp r) $ throwE r ambiguousE
    precedence <- getPrecedence e op
    Rebalance.Op (precedence, op, p) <$> extractBinaryOperatorTree l <*> extractBinaryOperatorTree r
    where
        ambiguousE = SemanticE "ambiguous operator binding" $ Just "add parenthesis to resolve the issue"
extractBinaryOperatorTree e = resolveExpression e <&> Rebalance.Val

resolveBinaryOperatorTree :: Monad m => OpExpr -> EntityResolver m Expression
resolveBinaryOperatorTree (Rebalance.Val e) = return e
resolveBinaryOperatorTree (Rebalance.Op (_, op, pos) l r) = do
    l' <- resolveBinaryOperatorTree l
    r' <- resolveBinaryOperatorTree r
    entity <- findEntityByName op
    maybe (throwE pos $ notInScope op) (\ e -> return $ ECall (referenceEntity e) [l', r']) entity

isUnOp :: Abs.Exp -> Bool
isUnOp (Abs.EPrefOp {}) = True
isUnOp (Abs.EPostOp {}) = True
isUnOp _ = False

convertValueToType :: Monad m => Type -> Expression -> EntityResolver m Expression
convertValueToType t value = do
    let valueType = typeOf value
    if (valueType == t) then
        return value
    else if (assignable t valueType) then
        error "internal error: value conversion not supported"
    else lift $ throwError "cannot assign value to given type"

closeCurrentScope :: Monad m => EntityResolverT m ()
closeCurrentScope = modifyScope (& scopeClosed .~ True)

forwardDeclare :: Monad m => String -> Type -> EntityResolver m ()
forwardDeclare name t = do
    entityId <- freshEntityId
    let entity = EUnresolved (name, entityId) t False
    modifyState (& resolverEntities %~ Map.insert entityId entity)
    modifyNameMapping $ Map.insert name entityId

declareEntity :: Monad m => String -> (EntityId -> Entity) -> EntityResolver m EntityId
declareEntity name factory = do
    forwardDeclaration <- findEntityByName name
    case forwardDeclaration of
        Nothing -> do -- insert new entity
            entityId <- freshEntityId
            let entity = factory entityId
            insertEntity entity
            modifyNameMapping $ Map.insert name entityId
            return entityId
        Just (EUnresolved (_, entityId) t _) -> let entity' = factory entityId in do -- complete forward declaration
                when (t /= typeOf entity') $ lift $ throwError "Declaration type does not match the forward declaration"
                insertEntity entity'
                return entityId
        _ -> lift $ throwError "Cannot redeclare the entity"

declareEntity_ :: Monad m => String -> (EntityId -> Entity) -> EntityResolver m ()
declareEntity_ name factory = do
    _ <- declareEntity name factory
    return ()

getPrecedence :: (Abs.HasPosition a, Monad m) => a -> String -> EntityResolver m Int
getPrecedence a name = do
    prec <- getState $ (^.operatorPrecedences.to (Map.lookup name))
    maybe (throwE a $ notInScope name) return prec

insertOperator :: (Abs.HasPosition a, Monad m) => a -> String -> Int -> EntityResolver m ()
insertOperator a name precedence = do
    prec <- getState (^.operatorPrecedences.to (Map.lookup name))
    when (isJust prec) $ throwE a $ SemanticE ("precedence for operator " ++ name ++ " was already defined") Nothing
    modifyState (& operatorPrecedences %~ Map.insert name precedence)

insertEntity :: Monad m => Entity -> EntityResolver m ()
insertEntity entity = let (_, entityId) = entityInfo entity in
    modifyState (& resolverEntities %~ Map.insert entityId entity)

findEntityByName :: Monad m => String -> EntityResolver m (Maybe Entity)
findEntityByName name = do
    target <- getState $ findIdOnStack . _scopeStack
    maybe (return Nothing) findEntityById target
    where
        findIdOnStack :: [Scope] -> Maybe EntityId
        findIdOnStack [] = Nothing
        findIdOnStack (h:t) = case (Map.lookup name $ _nameMapping h) of
            Nothing -> findIdOnStack t
            Just entityId -> Just entityId

findEntityById :: Monad m => EntityId -> EntityResolverT m (Maybe Entity)
findEntityById entityId = getState $ (Map.lookup entityId) . _resolverEntities

freshEntityId :: Monad m => EntityResolverT m Int
freshEntityId = EntityResolverT freshId

newtype IdGeneratorT m a = IdGeneratorT { runIdGeneratorT :: StateT Int m a } deriving (Functor, Applicative, Monad)
instance MonadTrans IdGeneratorT where lift = IdGeneratorT . lift

newtype EntityResolverT m a = EntityResolverT {
    runEntityResolverT :: IdGeneratorT (StateT EntityResolverState m) a
} deriving (Functor, Applicative, Monad)
instance MonadTrans EntityResolverT where
    lift :: Monad m => m a -> EntityResolverT m a
    lift = EntityResolverT . lift . lift

runEntityResolver :: Monad m => Int -> EntityResolverState -> EntityResolverT m a -> m (a, Int, EntityResolverState)
runEntityResolver i s m = do
    ((r, i'), s') <- runStateT ((runStateT . runIdGeneratorT . runEntityResolverT) m i) s
    return (r, i', s')

type EntityResolver m a = EntityResolverT (ExceptT String m) a

throwE :: (Abs.HasPosition a, Monad m) => a -> CodeError -> EntityResolver m b
throwE target err = lift $ throwError $ (maybe "" showPos $ Abs.hasPosition target) ++ show err
    where
        showPos :: (Int, Int) -> String
        showPos (line, col) = "(" ++ show line ++ ":" ++ show col ++ ") "

getState :: Monad m => (EntityResolverState -> a) -> EntityResolverT m a
getState = inResolver . gets

modifyState :: Monad m => (EntityResolverState -> EntityResolverState) -> EntityResolverT m ()
modifyState = inResolver . modify

inResolver :: Monad m => StateT EntityResolverState m a -> EntityResolverT m a
inResolver = EntityResolverT . lift

pushScope :: Monad m => EntityResolverT m ()
pushScope = getsInScope _scopeReturnType >>= pushScopeWithReturnType

pushScopeWithReturnType :: Monad m => Type -> EntityResolverT m ()
pushScopeWithReturnType t = modifyState (& scopeStack %~ ((emptyScope & scopeReturnType .~ t):))

popScope :: Monad m => EntityResolver m Scope
popScope = do
    scope <- inResolver $ state $ \s -> let (h, t) = splitArr $ s ^. scopeStack in (h, s & scopeStack .~ t)
    let toDelete = map snd $ Map.toList $ _nameMapping scope
    modifyState (& resolverEntities %~ (\e -> foldl (flip Map.delete) e toDelete))
    return scope
    where
        splitArr :: [a] -> (a, [a])
        splitArr [] = error "internal error, cannot access head of empty array"
        splitArr (h:t) = (h, t)

popScope_ :: Monad m => EntityResolver m ()
popScope_ = do
    _ <- popScope
    return ()

modifyNameMapping :: Monad m => (Map.Map String EntityId -> Map.Map String EntityId) -> EntityResolverT m ()
modifyNameMapping f = modifyScope (& nameMapping %~ f)

getsInScope :: Monad m => (Scope -> a) -> EntityResolverT m a
getsInScope f = inScope $ \s -> (f s, s)

modifyScope :: Monad m => (Scope -> Scope) -> EntityResolverT m ()
modifyScope f = inScope $ \s -> ((), f s)

inScope :: Monad m => (Scope -> (a, Scope)) -> EntityResolverT m a
inScope = inResolver . state . handler
    where
        handler :: (Scope -> (a, Scope)) -> EntityResolverState -> (a, EntityResolverState)
        handler f r@(EntityResolver _ _ (s:t)) = let (result, s') = f s in (result, r & scopeStack .~ s':t)
        handler f r = let (result, _) = f emptyScope in (result, r)

freshId :: Monad m => IdGeneratorT m Int
freshId = IdGeneratorT $ state (\i -> (i, i + 1))