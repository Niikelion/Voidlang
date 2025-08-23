{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# HLINT ignore "Use lambda-case" #-}
module Void.Trans(ensureSSA) where

import qualified Void.IR as IR
import Void.IR(($=))
import Control.Monad.State
import qualified Data.Map as Map
import Data.Map((!))
import qualified Data.Set as Set
import Data.Maybe
import Data.List
import Control.Monad
import Control.Monad.Identity
import Data.Functor((<&>))
import Prelude hiding (exp)
import Data.Generics.Uniplate.Operations (transformBiM)

data BlockData = BlockData {
    liveLocals :: Set.Set IR.Val,
    modifiedLocals :: Set.Set IR.Val,
    sourceBlocks :: Set.Set Int,
    localRemappedIds :: Map.Map Int Int,
    localRemapSources :: Map.Map Int Int
}

data RemapState = RemapState {
    nextRemapId :: Int,
    blocksData :: Map.Map Int BlockData
}

second :: (b -> b') -> (a, b) -> (a, b')
second f (a, b) = (a, f b)

secondM :: Monad m => (b -> m b') -> (a, b) -> m (a, b')
secondM f (a, b) = f b <&> (a,)

createArgMap :: [Int] -> Map.Map Int Int
createArgMap args = let n = length args in Map.fromList $ zip args [0..n - 1]

emptyRemapState :: [Int] -> RemapState
emptyRemapState args = RemapState (length args) Map.empty

type RemapMonad a = State RemapState a

insertJumpSource :: Int -> Int -> RemapMonad ()
insertJumpSource source destination = modify (\s ->
    s{blocksData = Map.adjust (\b ->
        b{ sourceBlocks = Set.insert source (sourceBlocks b) }) destination $ blocksData s})

getFreshRemapId :: RemapMonad Int
getFreshRemapId = state op
    where op s = let freshId = nextRemapId s in (freshId, s{nextRemapId = freshId + 1} )

getRemapData :: Int -> RemapMonad BlockData
getRemapData blockId = gets (fromJust . Map.lookup blockId . blocksData)

putRemapData :: Int -> BlockData -> RemapMonad ()
putRemapData blockId blockData = modify (\s -> s{blocksData = Map.insert blockId blockData $ blocksData s})

type RemapBlockMonadT m a = StateT BlockData (StateT RemapState m) a
type RemapBlockMonad a = RemapBlockMonadT Identity a

inBlock :: Int -> RemapBlockMonad a -> RemapMonad a
inBlock blockId m = do
    block <- getRemapData blockId
    (ret, block') <- runStateT m block
    putRemapData blockId block'
    return ret

remapLocalId :: Int -> Int -> RemapMonad Int
remapLocalId blockId sourceId = inBlock blockId $ do
        newId <- lift getFreshRemapId
        modify (\b -> b{localRemappedIds = Map.insert sourceId newId $ localRemappedIds b, localRemapSources = Map.insert newId sourceId $ localRemapSources b})
        return newId

type RemapIdState = (Int, Map.Map Int Int)

type RemapIdMonadT m a = StateT RemapIdState (StateT RemapState m) a
type RemapIdMonad a = RemapIdMonadT Identity a

emptyRemapIdState :: Int -> Map.Map Int Int -> RemapIdState
emptyRemapIdState blockId mappings = (blockId, mappings)

ensureSSA :: [Int] -> [IR.Block] -> [IR.Block]
ensureSSA funArgs originalBlocks = runIdentity $ do
    evalStateT (remapNames originalBlocks) $ emptyRemapState funArgs
    where
        remapNames :: [IR.Block] -> RemapMonad [IR.Block]
        remapNames blocks =  do
            let extractSteps = [insertLiveData, insertJumpData, propagateLiveData . IR.blockId]
            let applySteps = [
                    mapM insertMappingData,
                    mapM remapIds,
                    return . removeAliasing,
                    return . optimize
                    ]
            mapM_ ((flip mapM_) blocks) extractSteps
            foldl (>>=) (return blocks) applySteps
        remapIds :: IR.Block -> RemapMonad IR.Block
        remapIds (IR.Block blkId instrs) = do
            evalStateT (mapM remapInstr instrs) (emptyRemapIdState blkId $ createArgMap funArgs) <&> IR.Block blkId
            
        inCurrentBlock :: RemapBlockMonad a -> RemapIdMonad a
        inCurrentBlock m = do
            currentId <- gets fst
            lift $ inBlock currentId m

        remapInstr :: IR.Instr -> RemapIdMonad IR.Instr
        remapInstr instr = do
            instr' <- transformBiM remapVal instr >>= transformBiM remapSource
            case instr' of
                IR.IAssign loc _ -> restoreIdMapping loc
                _ -> return ()
            return instr'

        remapSource :: (Int, IR.Val) -> RemapIdMonad (Int, IR.Val)
        remapSource (blockId, IR.VLocal t oldId) = do
            blockData <- lift $ getRemapData blockId
            newId <- lift $ evalStateT (resolveId oldId) $ emptyRemapIdState blockId $ localRemappedIds blockData
            return (blockId, IR.VLocal t newId)
        remapSource v = return v

        remapVal :: IR.Val -> RemapIdMonad IR.Val
        remapVal (IR.VLocal t l) = resolveId l <&> IR.VLocal t
        remapVal v = return v

        restoreIdMapping :: Int -> RemapIdMonad ()
        restoreIdMapping newId = do
            mapping <- inCurrentBlock $ gets localRemapSources
            let oldId = fromJust $ Map.lookup newId mapping
            modify $ second (Map.insert oldId newId)

        resolveId :: Int -> RemapIdMonad Int
        resolveId varId = do
            (blockId, localId) <- gets (second (Map.lookup varId))
            case localId of
                Just resolvedId -> return resolvedId
                Nothing -> do
                    blockData <- lift $ getRemapData blockId
                    let sources = Set.elems $ sourceBlocks blockData
                    let source = case sources of
                            h : _ -> h
                            _ -> error $ "cannot resolve id " ++ show varId ++ " defined in block " ++ show blockId ++ " due to a missing source blocks"
                    blockData' <- lift $ getRemapData source
                    lift $ evalStateT (resolveId varId) $ emptyRemapIdState source $ localRemappedIds blockData'

        insertLiveData :: IR.Block -> RemapMonad ()
        insertLiveData block@(IR.Block blockId _) = do
            let live = extractLive block
            let modified = extractModified block
            modify (\s -> s{blocksData = Map.insert blockId (BlockData live modified Set.empty (createArgMap funArgs) Map.empty) $ blocksData s})
            where
                extractLive (IR.Block _ instrs) = foldr stepLive Set.empty instrs
                    where stepLive instr = IR.extractUsedLocals Set.insert instr . IR.extractModifiedValues Set.delete instr
                extractModified (IR.Block _ instrs) = foldr stepModified Set.empty instrs
                    where stepModified = IR.extractModifiedValues Set.insert

        insertJumpData :: IR.Block -> RemapMonad ()
        insertJumpData block@(IR.Block blockId _) = do
            let jumpData = IR.blockJumpTargets block
            mapM_ (insertJumpSource blockId) jumpData

        propagateLiveData :: Int -> RemapMonad ()
        propagateLiveData blockId = do
            remapData <- getRemapData blockId
            let live = liveLocals remapData
            mapM_ (propagateStep live) $ Set.elems $ sourceBlocks remapData
            where
                diff :: Ord a => Set.Set a -> Set.Set a -> Set.Set a
                diff = Set.difference
                
                propagateStep :: Set.Set IR.Val -> Int -> RemapMonad ()
                propagateStep live prevBlockId = do
                    remapData <- getRemapData prevBlockId
                    let live' = liveLocals remapData
                    let missingLive = live `diff` live' `diff` modifiedLocals remapData
                    when (not $ null missingLive) $ do
                        putRemapData prevBlockId $ remapData{liveLocals = Set.union live' missingLive}
                        propagateLiveData prevBlockId

        insertMappingData :: IR.Block -> RemapMonad IR.Block
        insertMappingData (IR.Block blockId instrs) = do
            b <- getRemapData blockId
            IR.Block blockId <$> (mapM stepMappingData =<< if length (sourceBlocks b) < 2
                then return instrs -- entry block and block with only one entry does not need phi functions
                else do -- we have more than one entry, add dummy phi functions to fill them later
                    let live = Set.elems $ liveLocals b
                    let sources = Set.elems $ sourceBlocks b
                    phis <- mapM (\l -> return $ l $= IR.EPhi (IR.typeOf l) (map (, l) sources)) live
                    return $ phis ++ instrs)
            where
                stepMappingData :: IR.Instr -> RemapMonad IR.Instr
                stepMappingData instr = case instr of
                    IR.IAssign loc e -> do
                        loc' <- remapLocalId blockId loc
                        return $ IR.IAssign loc' e
                    _ -> return instr





data Resolvable a b = Resolved a | Unresolved b

type RemoveAliasingMonad a = State (Map.Map Int (Resolvable IR.Val IR.Val)) a

removeAliasing :: [IR.Block] -> [IR.Block]
removeAliasing blocks = evalState (mapM_ extractMapping blocks >> mapM applyMapping blocks) Map.empty
    where
        extractMapping :: IR.Block -> RemoveAliasingMonad ()
        extractMapping block = mapM_ extractMappingFromInstr $ IR.blockInstrs block
        applyMapping :: IR.Block -> RemoveAliasingMonad IR.Block
        applyMapping block = flip IR.mapBlockM block $ const $ fmap catMaybes . mapM applyMappingForInstr

        putRemappedValue :: Int -> Resolvable IR.Val IR.Val -> RemoveAliasingMonad ()
        putRemappedValue i v = modify $ Map.insert i v

        extractMappingFromInstr :: IR.Instr -> RemoveAliasingMonad ()
        extractMappingFromInstr instr = case instr of
            IR.IAssign l (IR.EVal v@(IR.VLocal _ _)) -> putRemappedValue l $ Unresolved v
            IR.IAssign l (IR.EVal v) -> putRemappedValue l $ Resolved v
            _ -> return ()

        applyMappingForInstr :: IR.Instr -> RemoveAliasingMonad (Maybe IR.Instr)
        applyMappingForInstr instr = case instr of
            IR.IRet (Just v) -> getRemappedValue v <&> (Just . IR.IRet . Just)
            IR.ICond v l1 l2 -> getRemappedValue v <&> \v' -> Just $ IR.ICond v' l1 l2
            IR.IAssign _ (IR.EVal _) -> return Nothing
            IR.IAssign l exp -> applyMappingForExp exp <&> (Just . IR.IAssign l)
            IR.IExp exp -> applyMappingForExp exp <&> (Just . IR.IExp)
            IR.IStore val addr -> IR.IStore <$> getRemappedValue val <*> getRemappedValue addr <&> Just
            _ -> return $ Just instr

        applyMappingForExp :: IR.Exp -> RemoveAliasingMonad IR.Exp
        applyMappingForExp exp = case exp of
            IR.EPhi t sources -> mapM (secondM getRemappedValue) sources <&> IR.EPhi t
            _ -> transformBiM getRemappedValue exp

        getRemappedValue :: IR.Val -> RemoveAliasingMonad IR.Val
        getRemappedValue val = case val of
            IR.VLocal _ i -> do
                looked <- gets $ Map.lookup i
                case looked of
                    Nothing -> return val
                    Just (Resolved value) -> return value
                    Just (Unresolved value) -> do
                        value' <- case value of
                            IR.VLocal _ _ -> getRemappedValue value
                            _ -> return value
                        putRemappedValue i $ Resolved value'
                        return value'
            _ -> return val

data PhiData = Phi {
    phiLocal :: IR.Val,
    phiSources :: [IR.Val],
    affectedPhis :: [Int]
}

type ReducePhisMonad a = State (Map.Map Int (Resolvable IR.Val PhiData)) a
type ReducePhisInnerMonad a = State (Map.Map Int PhiData) a

reducePhis :: [IR.Block] -> [IR.Block]
reducePhis blocks = let
    extractedData = execState (do
        mapM_ extractPhisFromBlock blocks
        phis <- gets Map.keys
        mapM_ propagateAffectedPhis phis
        ) Map.empty
    in evalState (do
    phis <- gets Map.keys
    mapM_ resolvePhi phis
    mapM applyMappingInBlock blocks <&> removeAliasing
    ) $ Map.map Unresolved extractedData
    where
        extractPhisFromBlock :: IR.Block -> ReducePhisInnerMonad ()
        extractPhisFromBlock block = mapM_ extractPhiFromInstr $ IR.blockInstrs block
        extractPhiFromInstr :: IR.Instr -> ReducePhisInnerMonad ()
        extractPhiFromInstr instr = case instr of
            IR.IAssign l (IR.EPhi t sources) ->
                modify $ Map.insert l $ Phi (IR.VLocal t l) (map snd sources) []
            _ -> return ()

        propagateAffectedPhis :: Int -> ReducePhisInnerMonad ()
        propagateAffectedPhis i = do
            phi <- gets $ flip (!) i
            mapM_ (propagateSingleSource i) $ phiSources phi

        propagateSingleSource :: Int -> IR.Val -> ReducePhisInnerMonad ()
        propagateSingleSource targetId source = case source of
            IR.VLocal _ sourceId ->
                modify $ Map.adjust (\phi -> phi{ affectedPhis = targetId : affectedPhis phi }) sourceId
            _ -> return ()

        resolvePhi :: Int -> ReducePhisMonad ()
        resolvePhi i = do
            d <- gets $ flip (!) i
            case d of
                Resolved _ -> return ()
                Unresolved phi ->
                    case Set.toList $ Set.delete (phiLocal phi) $ Set.fromList $ phiSources phi of
                        [v] -> do
                            modify $ Map.insert i $ Resolved v
                            mapM_ resolvePhi $ affectedPhis phi
                        _ -> return ()

        applyMappingInBlock = IR.mapBlockM $ const $ mapM applyMappingForInstr

        applyMappingForInstr :: IR.Instr -> ReducePhisMonad IR.Instr
        applyMappingForInstr instr = case instr of
            IR.IAssign l (IR.EPhi t sources) -> do
                d <- gets $ flip (!) l
                case d of
                    Resolved val -> return $ IR.IAssign l $ IR.EVal val
                    Unresolved _ -> mapM getResolved sources <&> IR.IAssign l . (IR.EPhi t)
            _ -> return instr
        getResolved :: (Int, IR.Val) -> ReducePhisMonad (Int, IR.Val)
        getResolved (s, v) = do
            v' <- case v of
                IR.VLocal _ l -> do
                    d <- gets $ Map.lookup l
                    return $ case d of
                        Just (Resolved val) -> val
                        _ -> v
                _ -> return v
            return (s, v')

optimize :: [IR.Block] -> [IR.Block]
optimize = foldl (flip (.)) id [reducePhis, removeAliasing]