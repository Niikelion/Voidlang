{-# LANGUAGE FlexibleInstances #-}
module Void.IR where

import Data.List
import Prelude hiding (exp, id)
import Data.Generics.Uniplate.Direct(Uniplate(..), Biplate(..), plate, (|-), (|*), (||*), (|+))

type FunName = String
type Loc = Int

data Instr
  = IRet (Maybe Val)
  | ICond Val Int Int
  | IJump Int
  | IAssign Loc Exp
  | IExp Exp
  | IStore Val Val
  | IComment String

instance Show Instr where
    show instr = case instr of
        IRet val -> "ret " ++ maybe (show Void) (\v -> show (typeOf v) ++ ' ' : show v) val
        IAssign v exp -> show (VLocal (typeOf exp) v) ++ " = " ++ show exp
        ICond val trueLabel falseLabel -> "br i1 " ++ show val ++ ", " ++ labelRef trueLabel ++ ", " ++ labelRef falseLabel
        IJump l -> "br " ++ labelRef l
        IExp exp -> show exp
        IStore val addr -> "store " ++ valArg val ++ ", " ++ valArg addr
        IComment msg -> ';' : msg
instance Biplate Instr Val where
    biplate (IRet Nothing) = plate IRet |- (Nothing :: Maybe Val)
    biplate (IRet (Just v)) = plate (IRet . Just) |* v
    biplate (ICond v t f) = plate ICond |* v |- t |- f
    biplate (IJump l) = plate IJump |- l
    biplate (IAssign loc e) = plate IAssign |- loc |+ e
    biplate (IExp e) = plate IExp |+ e
    biplate (IStore a b) = plate IStore |* a |* b
    biplate (IComment s) = plate IComment |- s
instance Biplate Instr (Int, Val) where
    biplate (IRet Nothing) = plate IRet |- (Nothing :: Maybe Val)
    biplate (IRet (Just v)) = plate (IRet . Just) |- v
    biplate (ICond v t f) = plate ICond |- v |- t |- f
    biplate (IJump l) = plate IJump |- l
    biplate (IAssign loc e) = plate IAssign |- loc |+ e
    biplate (IExp e) = plate IExp |+ e
    biplate (IStore a b) = plate IStore |- a |- b
    biplate (IComment s) = plate IComment |- s
instance Uniplate Instr where
    uniplate (IRet v) = plate IRet |- v
    uniplate (ICond v t f) = plate ICond |- v |- t |- f
    uniplate (IJump l) = plate IJump |- l
    uniplate (IAssign loc e) = plate IAssign |- loc |- e
    uniplate (IExp e) = plate IExp |- e
    uniplate (IStore a b) = plate IStore |- a |- b
    uniplate (IComment s) = plate IComment |- s
instance Uniplate [Instr] where
    uniplate = plate

blockName :: Int -> String
blockName n = 'b' : show n

labelDef :: Int -> String
labelDef l = blockName l ++ ":"

labelRef :: Int -> String
labelRef l = "label %" ++ blockName l

extractUsedLocals :: (Val -> a -> a) -> Instr -> a -> a
extractUsedLocals f i locals = case i of
    IRet (Just v) -> extractFromVal v locals
    ICond v _ _ -> extractFromVal v locals
    IAssign _ e -> extractFromExp e
    IExp e -> extractFromExp e
    IStore val addr -> fromVals [val, addr]
    _ -> locals
    where
        extractFromVal v acc = case v of
            VLocal _ _ -> f v acc
            _ -> acc
        fromVals = foldr extractFromVal locals
        fromVal v = extractFromVal v locals
        extractFromExp e = case e of
            EOp _ val1 val2 -> fromVals [val1, val2]
            EComp _ val1 val2 -> fromVals [val1, val2]
            ECall _ _ vals -> fromVals vals
            EPhi _ sources -> fromVals $ map snd sources
            EVal v -> fromVal v
            ECast v _ -> fromVal v
            EArrAcc p o -> fromVals [p, o]
            EStructAcc p _ _ -> fromVal p
            EPtrToInt p _ -> fromVal p
            ELoad p -> fromVal p
            EEmpty -> locals

extractModifiedValues :: (Val -> a -> a) -> Instr -> a -> a
extractModifiedValues f i locals = case i of
    IAssign l e -> f (VLocal (typeOf e) l) locals
    _ -> locals

data Type = Int Int | Void | Pointer Type | Array Int Type | Fun Type [Type] | Struct [Type] | Class String
    deriving (Eq, Ord)

class Typed a where
    typeOf :: a -> Type

intType :: Type
intType = Int 32

boolType :: Type
boolType = Int 1

charType :: Type
charType = Int 8

stringType :: Type
stringType = Pointer charType

voidPointerType :: Type
voidPointerType = stringType

constantStringType :: Int -> Type
constantStringType n = Array n charType

arrayType :: Type -> Type
arrayType t = Pointer $ Struct [Pointer t, intType]

typeOfString :: String -> Type
typeOfString s = constantStringType $ 1 + length s

isPointer :: Type -> Bool
isPointer (Pointer _) = True
isPointer _ = False

stripPointer :: Type -> Type
stripPointer (Pointer t) = t
stripPointer _ = error "not a pointer type"

instance Show Type where
    show t = case t of
        Void -> "void"
        Int n -> 'i' : show n
        Pointer t' -> show t' ++ "*"
        Array n t' -> '[' : show n ++ " x " ++ show t' ++ "]"
        Fun r a -> show r ++ " (" ++ intercalate ", " (map show a) ++ ")"
        Struct m -> '{' : intercalate ", " (map show m) ++ "}"
        Class n -> "%cls." ++ n

data ComputationOperator = Plus | Minus | Multiply | Divide | Modulo | And | Or | Xor deriving Eq
data ComparisonOperator = Leq | Lth | Geq | Gth | Equ | Neq deriving Eq

data Exp
        = EOp ComputationOperator Val Val
        | EComp ComparisonOperator Val Val
        | ECall Type Val [Val]
        | EPhi Type [(Int, Val)]
        | EVal Val
        | ECast Val Type
        | EArrAcc Val Val
        | EStructAcc Val Type Int
        | EPtrToInt Val Int
        | ELoad Val
        | EEmpty
    deriving Eq

instance Typed Exp where
    typeOf exp = case exp of
        EOp _ v _ -> typeOf v
        EComp {} -> boolType
        ECall t _ _ -> t
        EPhi t _ -> t
        EVal v -> typeOf v
        ECast _ t -> t
        EArrAcc p _ -> typeOf p
        EStructAcc _ t _ -> Pointer t
        EPtrToInt _ n -> Int n
        ELoad v -> stripPointer $ typeOf v
        EEmpty -> Void

valArg :: Val -> String
valArg v = show (typeOf v) ++ ' ' : show v

instance Show Exp where
    show exp = case exp of
        EOp op val1 val2 -> instr ++ ' ' : valArg val1 ++ ", " ++ show val2
            where instr = case op of
                    Plus -> "add"
                    Minus -> "sub"
                    Multiply -> "mul"
                    Divide -> "sdiv"
                    Modulo -> "srem"
                    And -> "and"
                    Or -> "or"
                    Xor -> "xor"
        EComp op val1 val2 -> "icmp " ++ instr ++ ' ' : valArg val1 ++ ", " ++ show val2
            where instr = case op of
                    Leq -> "sle"
                    Lth -> "slt"
                    Geq -> "sge"
                    Gth -> "sgt"
                    Equ -> "eq"
                    Neq -> "ne"
        ECall retType name args -> "call " ++ show retType ++ " " ++ show name ++ '(' : arguments ++ ")"
            where
                arguments = intercalate ", " $ map (\a -> show (typeOf a) ++ ' ' : show a) args
        EVal v -> show v
        EPhi t sources -> "phi " ++ show t ++ ' ' : intercalate ", " (map (\(l, v) -> "[" ++ show v ++ ", %b" ++ show l ++ "]") sources)
        ECast fromValue toType -> "bitcast " ++ show (typeOf fromValue) ++ " " ++ show fromValue ++ " to " ++ show toType
        EArrAcc ptr offset -> "getelementptr " ++ show (stripPointer $ typeOf ptr) ++ ", " ++ valArg ptr ++ ", " ++ valArg offset
        EStructAcc ptr _ member -> "getelementptr " ++ show (stripPointer $ typeOf ptr) ++ ", " ++ valArg ptr ++ ", i32 0, i32 " ++ show member
        EPtrToInt v i -> "ptrtoint " ++ valArg v ++ " to " ++ show (Int i)
        ELoad v -> "load " ++ show (stripPointer $ typeOf v) ++ ", " ++ valArg v
        EEmpty -> "empty instructions not supported"
instance Biplate Exp Val where
    biplate (EOp op x y) = plate EOp |- op |* x |* y
    biplate (EComp op x y) = plate EComp |- op |* x |* y
    biplate (ECall ty f args) = plate ECall |- ty |* f ||* args
    biplate (EPhi ty sources) = plate EPhi |- ty |- sources
    biplate (EVal v) = plate EVal |* v
    biplate (ECast v ty) = plate ECast |* v |- ty
    biplate (EArrAcc a i) = plate EArrAcc |* a |* i
    biplate (EStructAcc v ty i) = plate EStructAcc |* v |- ty |- i
    biplate (EPtrToInt v n) = plate EPtrToInt |* v |- n
    biplate (ELoad p) = plate ELoad |* p
    biplate EEmpty = plate EEmpty
instance Biplate Exp (Int, Val) where
    biplate (EOp op x y) = plate EOp |- op |- x |- y
    biplate (EComp op x y) = plate EComp |- op |- x |- y
    biplate (ECall ty f args) = plate ECall |- ty |- f |- args
    biplate (EPhi ty sources) = plate EPhi |- ty ||* sources
    biplate (EVal v) = plate EVal |- v
    biplate (ECast v ty) = plate ECast |- v |- ty
    biplate (EArrAcc a i) = plate EArrAcc |- a |- i
    biplate (EStructAcc v ty i) = plate EStructAcc |- v |- ty |- i
    biplate (EPtrToInt v n) = plate EPtrToInt |- v |- n
    biplate (ELoad p) = plate ELoad |- p
    biplate EEmpty = plate EEmpty

data Val
    = VConst Type Int
    | VLocal Type Int
    | VGlobal Type String
    | VNull Type
    deriving (Eq, Ord)
instance Typed Val where
    typeOf :: Val -> Type
    typeOf val = case val of
        VConst t _ -> t
        VLocal t _ -> t
        VGlobal t _ -> t
        VNull t -> t
instance Show Val where
    show val = case val of
        VConst _ n -> show n
        VLocal _ version -> "%l." ++ show version
        VGlobal _ name -> '@' : name
        VNull _ -> "null"
instance Uniplate Val where
    uniplate (VConst ty n) = plate VConst |- ty |- n
    uniplate (VLocal ty n) = plate VLocal |- ty |- n
    uniplate (VGlobal ty n) = plate VGlobal |- ty |- n
    uniplate (VNull ty) = plate VNull |- ty
instance Uniplate (Int, Val) where
    uniplate v = plate v

int :: Int -> Val
int = VConst intType

char :: Int -> Val
char = VConst charType

bool :: Bool -> Val
bool v = VConst boolType $ if v then 1 else 0

($+) :: Val -> Val -> Exp
($+) = EOp Plus
infixl 7 $+

($*) :: Val -> Val -> Exp
($*) = EOp Multiply
infixl 8 $*

($=) :: Val -> Exp -> Instr
($=) (VLocal _ l) = IAssign l
($=) _ = error "can assign only to local variables"
infixl 6 $=

($@) :: Val -> Type -> Exp
($@) = ECast
infixl 9 $@

($$) :: Exp -> Instr
($$) = IExp

data Vis = Public | Private | Internal
    deriving (Eq, Ord)

instance Show Vis where
    show v = case v of
        Public -> "public"
        Private -> "private"
        Internal -> "internal"

data ConstVal = CString String | CInt Int

instance Show ConstVal where
        show v = case v of
            CString s -> let s' = show s; (b, e) = splitAt (length s' - 1) s' in 'c' : b ++ "\\00" ++ e
            CInt n -> show n

data Global = Global String Vis Bool Type ConstVal

instance Typed Global where
    typeOf (Global _ _ _ t _) = Pointer t

instance Show Global where
    show (Global name vis isConst t val) = unwords [show $ VGlobal t name, "=", show vis, if isConst then "constant" else "global", show t, show val]

data Block = Block {
    blockId :: Int,
    blockInstrs :: [Instr]
}

instance Show Block where
    show (Block name instrs) = intercalate "\n" $ labelDef name : map (("    " ++) . show) instrs
instance Biplate Block [Instr] where
    biplate (Block bId instrs) = plate Block |- bId |* instrs
instance Biplate Block Instr where
    biplate (Block bId instrs) = plate Block |- bId ||* instrs

mapBlockM :: Monad m => (Int -> [Instr] -> m [Instr]) -> Block -> m Block
mapBlockM f (Block id instrs) = do
    instrs' <- f id instrs
    return $ Block id instrs'

blockJumpTargets :: Block -> [Int]
blockJumpTargets block = case reverse $ blockInstrs block of
    ICond _ trueTarget falseTarget:_ -> [trueTarget, falseTarget]
    IJump target:_ -> [target]
    _ -> []

data Def = FunDef {
    funType :: Type,
    funArgs :: [Int],
    funName :: FunName,
    funBody :: [Block]
} | ExtDef {
    extType :: Type,
    extName :: String
}

instance Show Def where
    show (FunDef (Fun retType argTypes) args name blocks) = intercalate "\n" content
        where
            arguments = intercalate ", " $ zipWith (\ a t -> show t ++ ' ' : show (VLocal t a)) args argTypes
            signature = "define " ++ show retType ++ " @" ++ name ++ '(' : arguments ++ ") {"
            content = signature : map show blocks ++ [ "}" ]
    show (FunDef {}) = error "internal error: type of the function is not a function type"
    show (ExtDef (Fun retType argTypes) name) = signature
        where
            signature = "declare " ++ show retType ++ " @" ++ name ++ '(' : arguments ++ ")"
            arguments = intercalate ", " $ map show argTypes
    show (ExtDef t name) = "@" ++ name ++ " = external global " ++ show t

data Module = Module [Def]

instance Show Module where
    show (Module definitions) = intercalate "\n\n" $ map show definitions

secondM :: Monad m => (b -> m b') -> (a, b) -> m (a, b')
secondM f (a, b) = f b >>= return . (a,)