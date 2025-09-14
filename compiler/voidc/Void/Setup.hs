{-# LANGUAGE TypeFamilies, DataKinds, PatternSynonyms #-}
module Void.Setup(initialState) where

import qualified Void.Analyse.Setup as Setup
import qualified Void.IR as IR
import Void.Ast
import Void.Trans
import Control.Monad.State
import Data.Generics.Uniplate.Operations(transformBi)
import qualified Data.Kind
import Data.Foldable
import Data.Functor
import Data.Typeable(Typeable)

data Nat = Z | S Nat deriving (Eq, Typeable)

type FList :: Nat -> Data.Kind.Type -> Data.Kind.Type
data FList n x where
    FEnd :: FList Z x
    (:&) :: x -> FList n x -> FList (S n) x
infixr 5 :&

pattern (:$) :: x -> x -> FList (S (S Z)) x
pattern (:$) a b = a :& b :& FEnd
infixr 6 :$

{-# COMPLETE FEnd, (:$) #-}
{-# COMPLETE FEnd, (:&) #-}

instance Foldable (FList n) where
    foldr _ acc FEnd = acc
    foldr f acc (h :& t) = f h $ foldr f acc t
instance Functor (FList n) where
    fmap _ FEnd = FEnd
    fmap f (h :& t) = f h :& fmap f t
instance Traversable (FList n) where
    sequenceA FEnd = pure FEnd
    sequenceA (h :& t) = liftA2 (:&) h (sequenceA t)

initialState :: Setup.SetupState
initialState = Setup.execSetup setup

setup :: Setup.Setup ()
setup = do
    addition <- implement "$plus" TInt (TInt :$ TInt) $ \(a :$ b) -> do
        v <- var TInt
        v #= a #+ b
        ret $ Just v

    Setup.makeOperator "+" 5 addition
    Setup.exposeEntity addition "+"

    extern "putchar" TInt [TInt]

data ImplementState = ImplementState {
    implementationNextLocalId :: Int,
    implementationNextBlockId :: Int,
    implementationBlocks :: [IR.Block]
}
type Implement a = State ImplementState a

ret :: Maybe IR.Val -> Implement ()
ret v = ir $ IR.IRet v

var :: Type -> Implement IR.Val
var t = freshLocalId <&> IR.VLocal (IR.typeOf t)

infix 2 #=
(#=) :: IR.Val -> IR.Exp -> Implement ()
(#=) (IR.VLocal _ loc) e = ir $ IR.IAssign loc e
(#=) _ _ = error "cannot assign to constant"

infix 5 #+
(#+) :: IR.Val -> IR.Val -> IR.Exp
(#+) a b = IR.EOp IR.Plus a b

freshLocalId :: Implement Int
freshLocalId = state $ \s -> (implementationNextLocalId s, s { implementationNextLocalId = implementationNextLocalId s + 1 })

freshBlockId :: Implement Int
freshBlockId = state $ \s -> (implementationNextBlockId s, s { implementationNextBlockId = implementationNextBlockId s + 1 })

startBlock :: Int -> Implement ()
startBlock blockId = modify $ \s -> s { implementationBlocks = IR.Block blockId [] : implementationBlocks s }

ir :: IR.Instr -> Implement ()
ir instr = modify $ \s -> s { implementationBlocks = insertIntoTopBlock $ implementationBlocks s }
    where
        insertIntoTopBlock :: [IR.Block] -> [IR.Block]
        insertIntoTopBlock [] = []
        insertIntoTopBlock (h:t) = (transformBi prependInstrs h):t

        prependInstrs :: [IR.Instr] -> [IR.Instr]
        prependInstrs = (instr:)

implement :: String -> Type -> FList n Type -> (FList n IR.Val -> Implement a) -> Setup.Setup Entity
implement name retT args implementation = do
    let sig = TFunction retT $ toList args
    let s = execState (traverse makeArg args >>= implementation) $ ImplementState 0 1 [ IR.Block 0 [] ]
    entity <- Setup.makeEntity $ \i -> EExternal (name ++ mangle sig, i) sig
    Setup.implementFunction entity $ ensureSSA [0..length args-1] $ IR.fixBlocks $ implementationBlocks s
    return entity
    where
        makeArg :: Type -> Implement IR.Val
        makeArg t = freshLocalId <&> (IR.VLocal $ IR.typeOf t)

extern :: String -> Type -> [Type] -> Setup.Setup ()
extern name retT args = do
    entity <- Setup.makeEntity $ \i -> EExternal (name, i) $ TFunction retT args
    Setup.exposeEntity entity name