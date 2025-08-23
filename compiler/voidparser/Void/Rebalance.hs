module Void.Rebalance(rebalance, Assoc(..), Expr(..)) where
import Prelude

data Assoc = LeftA | RightA deriving (Eq, Show)

data Expr o v
    = Val v
    | Op o (Expr o v) (Expr o v)

type AssocFn o = o -> Assoc
type PrecFn o = o -> Int

rotateRight :: Expr o v -> Expr o v
rotateRight (Op o (Op lo ll lr) r) = Op lo ll (Op o lr r)
rotateRight t = t

rotateLeft :: Expr o v -> Expr o v
rotateLeft (Op o l (Op ro rl rr)) = Op ro (Op o l rl) rr
rotateLeft t = t

shouldRotate :: PrecFn o -> AssocFn o -> o -> o -> Assoc -> Bool
shouldRotate prec assoc parent child dir = pPrec > cPrec || (pPrec == cPrec && assoc parent == dir)
    where
        pPrec = prec parent
        cPrec = prec child

rebalance :: PrecFn o -> AssocFn o -> Expr o v -> Expr o v
rebalance = go
    where
        go :: PrecFn o -> AssocFn o -> Expr o v -> Expr o v
        go prec assoc (Op o l r) =
            let l' = go prec assoc l in
            let r' = go prec assoc r in
                fixpoint prec assoc $ Op o l' r'
        go _ _ v = v

        fixpoint :: PrecFn o -> AssocFn o -> Expr o v -> Expr o v
        fixpoint prec assoc t = do
            let (t', changed) = step prec assoc t in
                if changed then fixpoint prec assoc t' else t'
        
        step :: PrecFn o -> AssocFn o -> Expr o v -> (Expr o v, Bool)
        step _ _ v@(Val {}) = (v, False)
        step prec assoc op = case op of
            Op o (Op lo _ _) _ | shouldRotate prec assoc o lo RightA -> (rotateRight op, True)
            Op o _ (Op ro _ _) | shouldRotate prec assoc o ro LeftA -> (rotateLeft op, True)
            _ -> (op, False)