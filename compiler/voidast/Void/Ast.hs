{-# LANGUAGE UndecidableInstances #-}
module Void.Ast where

import Data.List
import qualified Data.Set as Set

type TypeId = Int
type EntityId = Int

type EntityInfo = (String, Int)
instance EntityData a => Named a where nameOf = fst . entityInfo
instance EntityData a => Identifiable a where idOf = snd . entityInfo

class EntityData a where entityInfo :: a -> EntityInfo
class Named a where nameOf :: a -> String
class Identifiable a where idOf :: a -> Int
class Typed a where typeOf :: a -> Type
class (Typed a) => Typeish a where
    isType :: a -> Bool
    asType :: a -> Maybe Type
    asType a = if isType a then Just $ typeOf a else Nothing
class Mangled a where mangle :: a -> String

data StructTypeMember = TStructMember String Type deriving (Eq, Ord)
instance Show StructTypeMember where show (TStructMember n t) = n ++ ": " ++ show t

data Type
    = TVoid
    | TBool
    | TInt
    | TString
    | TOptional Type
    | TUnion (Set.Set Type)
    | TArray Type
    | TName TypeId
    | TStruct [StructTypeMember]
    | TFunction Type [Type]
    | TTuple [Type]
    deriving (Eq, Ord)
instance Show Type where
    show t = case t of
        TVoid               -> "void"
        TBool               -> "bool"
        TInt                -> "int"
        TString             -> "string"
        TOptional t'        -> show t' ++ "?"
        TUnion members      -> join " | " show $ Set.toList members
        TArray t'           -> show t' ++ "[]"
        TName name          -> show name
        TStruct members     -> "struct {" ++ (join ", " ((" " ++) . show) members) ++ " }"
        TFunction ret args  -> "(" ++ (joinL args) ++ ") -> " ++ show ret
        TTuple members      -> "(" ++ (joinL members) ++ ")"
        where
            join :: String -> (a -> String) -> [a] -> String
            join s f = (intercalate s) . (map f)

            joinL :: Show a => [a] -> String
            joinL = join ", " show
instance Mangled Type where
    mangle t = case t of
        TVoid -> "v"
        TBool -> "b"
        TInt -> "i"
        TString -> "s"
        TOptional t' -> "O" ++ mangle t'
        TUnion members -> "U" ++ join (map mangle $ Set.toList members) ++ "E"
        TName name -> "$" ++ show name ++ "$"
        TArray t' -> "A" ++ mangle t'
        TStruct {} -> error "cannot mangle structs" --TODO: handle this case
        TFunction ret args -> "F" ++ join (map mangle $ ret:args) ++ "E"
        TTuple members -> "T" ++ join (map mangle members) ++ "E"
        where
            join :: [String] -> String
            join = intercalate ""

tupleTypes :: Type -> [Type]
tupleTypes (TTuple m) = m
tupleTypes t = [t]

unionTypes :: Type -> Set.Set Type
unionTypes (TUnion m) = m
unionTypes t = Set.singleton t

assignable :: Type -> Type -> Bool
assignable a (TUnion m) = all (assignable a) m
assignable (TUnion m) a' = any ((flip assignable) a') m
assignable (TOptional a) (TOptional a') = assignable a a'
assignable (TOptional a) a' = assignable a a'
assignable a a' = a == a'

data Arg = Arg EntityInfo Type (Maybe Expression)
instance Typed Arg where typeOf (Arg _ t _) = t
instance Show Arg where
    show (Arg info t v) = entityDebugName info ++ ": " ++ show t ++ (maybe "" ((" = " ++) . show) v)
instance EntityData Arg where entityInfo (Arg info _ _) = info

data Entity
    = EFunction EntityInfo Type [Arg] Statement
    | EClass EntityInfo [(String, Type)] --TODO: add bodies to methods
    | EVariable EntityInfo Type
    | EExternal EntityInfo Type
    | EUnresolved EntityInfo Type Bool
instance Typed Entity where
    typeOf (EFunction _ ret args _) = TFunction ret $ map typeOf args
    typeOf (EClass _ members) = TStruct $ map (uncurry TStructMember) members
    typeOf (EVariable _ t) = t
    typeOf (EExternal _ t) = t
    typeOf (EUnresolved _ t _) = t
instance Typeish Entity where
    isType (EUnresolved _ _ isT) = isT
    isType (EClass _ _) = True
    isType _ = False
instance Show Entity where
    show f@(EFunction _ ret args b) =
        let argList = intercalate ", " $ map show args in
        intercalate "\n" [
            "fun " ++ debugName f ++ "(" ++ argList ++ "): " ++ show ret,
            show b
        ]
    show e = entityPrefix ++ " " ++ debugName e ++ ": " ++ (show $ typeOf e)
        where
            entityPrefix :: String
            entityPrefix = case e of
                EClass {} -> "class"
                EVariable {} -> "var"
                EExternal {} -> "external"
                EUnresolved _ _ True -> "unresolved type"
                EUnresolved _ _ False -> "unresolved"
instance EntityData Entity where
    entityInfo (EFunction info _ _ _) = info
    entityInfo (EClass info _) = info
    entityInfo (EVariable info _) = info
    entityInfo (EExternal info _) = info
    entityInfo (EUnresolved info _ _) = info

entityDebugName :: EntityInfo -> String
entityDebugName (n, i) = n ++ "@" ++ show i

debugName :: EntityData a => a -> String
debugName = entityDebugName . entityInfo

type StatementBlock = [Statement]

data Statement
    = SBlock StatementBlock Bool
    | SReturn (Maybe Expression)
    | SExpression Expression
instance Show Statement where
    show (SBlock statements _) = unlines [ "{", indent . intercalate "\n" $ map show statements, "}" ]
        where
            indent :: String -> String
            indent s = intercalate "\n" $ map ((++) "    ") $ lines s
    show (SReturn (Just e)) = "return " ++ show e
    show (SReturn Nothing) = "return"
    show (SExpression e) = show e
instance Typed Statement where
    typeOf e@(SExpression {}) = typeOf e
    typeOf _ = TVoid

ensureClosedBlock :: Statement -> Statement
ensureClosedBlock (SBlock statements False) = SBlock (statements ++ [ SReturn Nothing ]) True
ensureClosedBlock s = s

data Expression
    = EBool Bool
    | EInt Int
    | EString String
    | ENamed EntityInfo Type
    | ECall Expression [Expression]
instance Typed Expression where
    typeOf :: Expression -> Type
    typeOf (EBool _) = TBool
    typeOf (EInt _) = TInt
    typeOf (EString _) = TString
    typeOf (ENamed _ t) = t
    typeOf (ECall e _) = case typeOf e of
        (TFunction ret _) -> ret
        _ -> error "internal error: value not callable"
instance Show Expression where
    show (EBool v) = show v
    show (EInt v) = show v
    show (EString v) = show (escapeString v)
        where
            escapeString :: String -> String
            escapeString = concatMap escapeChar
                where
                    escapeChar :: Char -> String
                    escapeChar '\n' = "\\n"
                    escapeChar '\t' = "\\t"
                    escapeChar '\r' = "\\r"
                    escapeChar '\\' = "\\\\"
                    escapeChar '\"' = "\\\""
                    escapeChar '\'' = "\\\'"
                    escapeChar c = [c]
    show (ENamed info _) = entityDebugName info
    show (ECall target args) = show target ++ "(" ++ join args ++ ")"
        where
            join :: [Expression] -> String
            join = (intercalate ", ") . (map show)

referenceEntity :: Entity -> Expression
referenceEntity e = ENamed (entityInfo e) $ typeOf e