module Void.Analyse.Rebalance(rebalance, Assoc(..), Expr(..)) where
import Prelude
import Control.Monad.Reader(runReader, Reader, asks)
import Data.Functor((<&>))
import Data.Function((&))
import Data.Bool(bool)

data Assoc = LeftA | RightA deriving (Eq, Show)

data Expr o v
    = Val v
    | Op o (Expr o v) (Expr o v)

type AssocFn o = o -> Assoc
type PrecFn o = o -> Int

rebalance :: PrecFn o -> AssocFn o -> Expr o v -> Expr o v
rebalance p a = (flip runReader) (Source p a) . go
    
go :: Expr o v -> Rebalance o (Expr o v)
go (Op o l r) = do
    l' <- go l
    r' <- go r
    fixpoint $ Op o l' r'
go v = return v

fixpoint :: Expr o v -> Rebalance o (Expr o v)
fixpoint t = step t >>= uncurry (flip $ bool return fixpoint)

data Source o = Source {
    precFn :: PrecFn o,
    assocFn :: AssocFn o
}

type Rebalance o a = Reader (Source o) a
prec :: o -> Rebalance o Int
prec v = asks precFn <&> (v&)

assoc :: o -> Rebalance o Assoc
assoc v = asks assocFn <&> (v&)
        
step :: Expr o v -> Rebalance o (Expr o v, Bool)
step v@(Val {}) = return (v, False)
step op@(Op o l r) = try (shouldRotateRight o l) (rotateRight op)
                 ||> try (shouldRotateLeft o r) (rotateLeft op)
                 ||> return (op, False)

shouldRotateRight :: o -> Expr o v -> Rebalance o Bool
shouldRotateRight o (Op lo _ _) = shouldRotate o lo RightA
shouldRotateRight _ _ = return False

shouldRotateLeft :: o -> Expr o v -> Rebalance o Bool
shouldRotateLeft o (Op ro _ _) = shouldRotate o ro LeftA
shouldRotateLeft _ _ = return False

shouldRotate :: o -> o -> Assoc -> Rebalance o Bool
shouldRotate parent child dir = do
    pPrec <- prec parent
    cPrec <- prec child
    if (pPrec > cPrec) then return True
    else do
        pAssoc <- assoc parent
        return $ pPrec == cPrec && pAssoc == dir

rotateRight :: Expr o v -> Expr o v
rotateRight (Op o (Op lo ll lr) r) = Op lo ll (Op o lr r)
rotateRight t = t

rotateLeft :: Expr o v -> Expr o v
rotateLeft (Op o l (Op ro rl rr)) = Op ro (Op o l rl) rr
rotateLeft t = t

try :: Rebalance o Bool -> Expr o v -> Rebalance o (Maybe (Expr o v, Bool))
try cond v = cond <&> \ok -> if ok then Just (v, True) else Nothing

infixr 5 ||>
(||>) :: Monad m => m (Maybe a) -> m a -> m a
ma ||> mb = ma >>= maybe mb return