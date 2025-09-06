{-# LANGUAGE TemplateHaskell #-}
module Void.Analyse.Module (moduleFromCode, Module(..)) where

import Void.Ast
import qualified Void.Analyse.Rebalance as Rebalance
import qualified Data.Map as Map
import qualified Data.Set as Set
import qualified Data.List.NonEmpty as NE
import Control.Monad.State(gets, modify)
import Control.Monad.Except(ExceptT, MonadError(throwError))
import Data.Maybe(isJust)
import Control.Monad
import Data.Functor((<&>))
import Control.Lens((^.), (&), (%~), to)
import qualified Void.Parser as Abs
import Void.Analyse.Context
import qualified Void.Analyse.Setup as Setup
import Void.Analyse.Error

notInScope :: String -> CodeError
notInScope name = semanticErr ("could not find " ++ name) Nothing

data Module = Code (Map.Map EntityId Entity)
instance Show Module where
    show (Code e) = unlines $ map (("\n" ++) . show . snd) $ Map.toList e

stateFromSetup :: Setup.SetupState -> AnalyserState
stateFromSetup s = AnalyserState 1 entities precedences $ NE.singleton globalScope
    where
        entities = Setup._resolverEntities s
        precedences = Setup._operatorPrecedences s
        globalScope = Setup._globalScope s

moduleFromCode :: Monad m => Abs.Code -> Setup.SetupState -> ExceptT String m Module
moduleFromCode (Abs.Void _ defs) s = do
    let result = execAnalyser (stateFromSetup s) $ do
            mapM_ forwardDeclareTopEntity defs
            mapM_ resolveTopEntity defs
    either throwError (return . Code . (^. resolverEntities)) result

forwardDeclareTopEntity :: Abs.TopDef -> Analyser ()
forwardDeclareTopEntity (Abs.FunDef _ (Abs.Ident name) params ret _) = do
    argTypes <- mapM (\(Abs.ArgDef _ _ t) -> resolveType t) params
    returnType <- resolveType ret
    forwardDeclare name $ TFunction returnType argTypes

resolveTopEntity :: Abs.TopDef -> Analyser ()
resolveTopEntity (Abs.FunDef _ (Abs.Ident name) params ret body) = do
    returnType <- resolveType ret
    pushScopeWithReturnType returnType
    params' <- mapM resolveArgDef params
    body' <- case body of --TODO: switch from type equality to type assignability
        Abs.BlockBody _ block -> do
            block' <- resolveBlock block
            case block' of
                SBlock _ closed ->
                    when (not closed && returnType /= TVoid) $ throwE $ semanticErr "not all paths return a value" Nothing
                _ -> error "internal error, resolveBlock did not return a block"
            return $ ensureClosedBlock block'
        Abs.ExpBody _ stmt -> do
            stmt' <- resolveStatement stmt
            case stmt' of
                SExpression exp' -> do
                    when (typeOf exp' /= returnType) $ throwE $ typeErr "return type does not match" Nothing
                    return $ SBlock [SReturn $ Just exp'] True
                _ -> throwE $ semanticErr "this statement is not a valid function body" Nothing
    void popScope
    void $ declareEntity name $ \entityId -> EFunction (name, entityId) returnType params' body'

resolveBlock :: Abs.StmtBlock -> Analyser Statement
resolveBlock (Abs.Block _ stmts) = do
    pushScope
    stmts' <- mapM resolveStatement stmts
    closed <- popScope <&> (^.scopeClosed)
    when closed closeCurrentScope
    return $ SBlock stmts' closed


resolveArgDef :: Abs.ArgumentDef -> Analyser Arg
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

resolveType :: Abs.Type -> Analyser Type
resolveType (Abs.TVoid _) = return TVoid
resolveType (Abs.TBool _) = return TBool
resolveType (Abs.TInt _) = return TInt
resolveType (Abs.TString _) = return TString
resolveType n@(Abs.TNamed _ (Abs.Ident name)) = do
    target <- findEntityByName name
    let t = maybe Nothing asType target
    maybe (at n throwE $ notInScope name) return t
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

resolveStatement :: Abs.Stmt -> Analyser Statement
resolveStatement (Abs.SBlock _ block) = resolveBlock block
resolveStatement (Abs.SExp _ e) = resolveExpression e <&> SExpression
resolveStatement (Abs.SReturn _ e) = do
    e' <- resolveExpression e
    t' <- scoped gets _scopeReturnType
    when (typeOf e' /= t') $ throwE $ typeErr "type does not match" Nothing
    closeCurrentScope
    return $ SReturn $ Just e'
resolveStatement (Abs.SVoidReturn _) = do
    closeCurrentScope
    return $ SReturn Nothing

resolveExpression :: Abs.Exp -> Analyser Expression
resolveExpression (Abs.ETrue _) = return $ EBool True
resolveExpression (Abs.EFalse _) = return $ EBool False
resolveExpression (Abs.EInt _ v) = return $ EInt $ fromInteger v
resolveExpression (Abs.EString _ v) = return $ EString v
resolveExpression e@(Abs.EVar _ (Abs.Ident name)) = do
    target <- findEntityByName name
    maybe (at e throwE $ notInScope name) (return . referenceEntity) target
resolveExpression (Abs.ECall _ target (Abs.ETuple _ args)) = do
    target' <- resolveExpression target
    args' <- mapM resolveExpression args
    case typeOf target' of
        TFunction _ argTypes -> do
            when (length argTypes /= length args') $ throwE $ semanticErr "mismatched amount of arguments" Nothing
            (mapM (uncurry convertValueToType) $ zip argTypes args') <&> ECall target'
        _ -> throwE $ semanticErr "expression not callable" Nothing
resolveExpression (Abs.ECall {}) = error "internal error: function call without arguments"
resolveExpression e@(Abs.EBinOp {}) = do
    tree <- extractBinaryOperatorTree e
    let result = Rebalance.rebalance (\(p, _, _) -> p) (const Rebalance.LeftA) tree
    resolveBinaryOperatorTree result
resolveExpression (Abs.EPrefOp {}) = throwE $ semanticErr "prefops not supported" Nothing
resolveExpression (Abs.EPostOp {}) = throwE $ semanticErr "postops not supported" Nothing
resolveExpression (Abs.ETuple {}) = throwE $ semanticErr "tuples not supported" Nothing

type OpExpr = Rebalance.Expr (Int, String, Abs.BNFC'Position) Expression

extractBinaryOperatorTree :: Abs.Exp -> Analyser OpExpr
extractBinaryOperatorTree e@(Abs.EBinOp p l (Abs.Op op) r) = do
    when (isUnOp l) $ at l throwE ambiguousE
    when (isUnOp r) $ at r throwE ambiguousE
    precedence <- getPrecedence e op
    Rebalance.Op (precedence, op, p) <$> extractBinaryOperatorTree l <*> extractBinaryOperatorTree r
    where
        ambiguousE = semanticErr "ambiguous operator binding" $ Just "add parenthesis to resolve the issue"
extractBinaryOperatorTree e = resolveExpression e <&> Rebalance.Val

resolveBinaryOperatorTree :: OpExpr -> Analyser Expression
resolveBinaryOperatorTree (Rebalance.Val e) = return e
resolveBinaryOperatorTree (Rebalance.Op (_, op, p) l r) = do
    l' <- resolveBinaryOperatorTree l
    r' <- resolveBinaryOperatorTree r
    entity <- findEntityByName op
    maybe (at p throwE $ notInScope op) (\ e -> return $ ECall (referenceEntity e) [l', r']) entity

isUnOp :: Abs.Exp -> Bool
isUnOp (Abs.EPrefOp {}) = True
isUnOp (Abs.EPostOp {}) = True
isUnOp _ = False

convertValueToType :: Type -> Expression -> Analyser Expression
convertValueToType t value = do
    let valueType = typeOf value
    if (valueType == t) then
        return value
    else if (assignable t valueType) then
        error "internal error: value conversion not supported"
    else throwE $ typeErr "cannot assign value to a given type" Nothing

forwardDeclare :: String -> Type -> Analyser ()
forwardDeclare name t = do
    entityId <- freshId
    let entity = EUnresolved (name, entityId) t False
    global modify (& resolverEntities %~ Map.insert entityId entity)
    modifyNameMapping $ Map.insert name entityId

declareEntity :: String -> (EntityId -> Entity) -> Analyser EntityId
declareEntity name factory = do
    forwardDeclaration <- findEntityByName name
    case forwardDeclaration of
        Nothing -> do -- insert new entity
            entityId <- freshId
            let entity = factory entityId
            insertEntity entity
            modifyNameMapping $ Map.insert name entityId
            return entityId
        Just (EUnresolved (_, entityId) t _) -> let entity' = factory entityId in do -- complete forward declaration
                when (t /= typeOf entity') $ throwE $ typeErr "Declaration type does not match the forward declaration" Nothing
                insertEntity entity'
                return entityId
        _ -> throwE $ semanticErr "Cannot redeclare the entity" Nothing

getPrecedence :: Positional a => a -> String -> Analyser Int
getPrecedence a name = do
    prec <- global gets (^.operatorPrecedences.to (Map.lookup name))
    maybe (at a throwE $ notInScope name) return prec

insertOperator :: Positional a => a -> String -> Int -> Analyser ()
insertOperator a name precedence = do
    prec <- global gets (^.operatorPrecedences.to (Map.lookup name))
    when (isJust prec) $ at a throwE $ semanticErr ("precedence for operator " ++ name ++ " was already defined") Nothing
    global modify (& operatorPrecedences %~ Map.insert name precedence)

insertEntity :: Entity -> Analyser ()
insertEntity entity = let (_, entityId) = entityInfo entity in
    global modify (& resolverEntities %~ Map.insert entityId entity)

findEntityByName :: String -> Analyser (Maybe Entity)
findEntityByName name = do
    target <- global gets $ findIdOnStack . NE.toList . _scopeStack
    maybe (return Nothing) findEntityById target
    where
        findIdOnStack :: [Scope] -> Maybe EntityId
        findIdOnStack [] = Nothing
        findIdOnStack (h:t) = case (Map.lookup name $ _nameMapping h) of
            Nothing -> findIdOnStack t
            Just entityId -> Just entityId

findEntityById :: EntityId -> Analyser (Maybe Entity)
findEntityById entityId = global gets $ (Map.lookup entityId) . _resolverEntities