module Void.Platform(
    writeObjectFile,
    link,
    extFromLink,
    LinkType(..),

) where

import Control.Monad.Trans(lift)
import System.Info(os)
import System.FilePath(dropExtension,(<.>))
import System.Exit(ExitCode(..))
import System.Process(readCreateProcessWithExitCode, callProcess, proc)
import Control.Monad.Except(ExceptT, throwError)
import Data.List(intercalate)

data LinkType = App | Static | Dynamic deriving (Eq, Show)

data Platform = Windows | Linux
platform :: Platform
platform = if os == "mingw32" || os == "windows"
            then Windows
            else Linux

objExt :: String
objExt = case platform of
    Windows -> "obj"
    Linux -> "o"

extFromLink :: LinkType -> String
extFromLink lk = case platform of
    Windows -> case lk of
        App -> "exe"
        Static -> "lib"
        Dynamic -> "dll"
    Linux -> case lk of
        App -> ""
        Static -> "a"
        Dynamic -> "so"

toObjPath :: String -> String
toObjPath file = dropExtension file <.> objExt

writeObjectFile :: String -> String -> ExceptT String IO String
writeObjectFile sourceFile content = do
    let outFile = toObjPath sourceFile
    let cmd = proc "llc" ["-o", outFile, "-filetype=obj"]
    (exitCode, _, stderrOutput) <- lift $ readCreateProcessWithExitCode cmd content
    case exitCode of
        ExitSuccess -> return outFile
        ExitFailure c -> throwError $ intercalate "\n" [
                "llc failed with code " ++ show c,
                stderrOutput
            ]

lldOptions :: String -> LinkType -> [String] -> [String]
lldOptions outFile _ sources = case platform of
    Windows -> [
            "-flavor", "link",
            "/OUT:" ++ outFile
        ] ++ sources ++ [ "libcmt.lib" ]
    Linux -> [
            "-flavor", "gnu",
            "-o", outFile
        ] ++ sources

link :: String -> LinkType -> [String] -> ExceptT String IO ()
link outFile lk sources = do
    case lk of
        App -> lift $ callProcess "lld" $ lldOptions outFile lk sources
        Static -> error "not implemented"
        Dynamic -> error "not implemented"