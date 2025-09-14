module Main where

import Options.Applicative
import System.IO
import qualified Void.Parser
import qualified Void.Analyse
import qualified Void.Compile
import Control.Monad
import Control.Monad.State(MonadTrans(..))
import Control.Monad.Except
import Void.Setup
import Void.Platform
import System.FilePath((<.>))

data Args = Args {
    verbose :: Bool
}

putErrStrLn :: String -> IO ()
putErrStrLn = hPutStrLn stderr

runCatching :: Monad m => (e -> m a) -> ExceptT e m a -> m a
runCatching catch m = runExceptT m >>= either catch return

argsParser :: Parser Args
argsParser = Args
    <$> switch ( long "verbose" <> short 'v' <> help "Enables verbose output" )

data Command
    = Check {
        checkInputFile :: String,
        checkPrintIR :: Bool
    }
    | Build {
        buildInputFile :: String,
        buildType :: LinkType,
        buildOutputFile :: Maybe String
    }
    deriving (Eq, Show)

checkParser :: Parser Command
checkParser = Check
    <$> (argument str $ metavar "FILE")
    <*> switch ( long "ir" <> help "Switches from printing program structure to printing the resulting ir" )

buildParser :: Parser Command
buildParser = Build
    <$> argument str (metavar "FILE" <> help "Source file")
    <*> option readType ( long "type" <> short 't' <> metavar "TYPE" <> help "Build type: app, static, dynamic" <> value App <> showDefault )
    <*> optional (strOption $ long "output" <> short 'o' <> metavar "FILE" <> help "Output file name")
        where
            readType = eitherReader $ \a -> case a of
                "app" -> Right App
                "static" -> Right Static
                "dynamic" -> Right Dynamic
                _ -> Left "Type must be one of: app, static, dynamic"

commandsParser:: Parser Command
commandsParser = hsubparser $
    (command "check" $ info checkParser $ progDesc "Check the correctness of a sigle file") <>
    (command "build" $ info buildParser $ progDesc "Build the project")

opts :: Parser (Args, Command)
opts = (,) <$> argsParser <*> commandsParser <**> helper

printInfo :: String -> ExceptT String IO ()
printInfo = lift . putStrLn

readCodeFile :: String -> ExceptT String IO Void.Parser.Code
readCodeFile file = do
    content <- lift $ readFile file
    Void.Parser.parseCode content

analyseModule :: Void.Parser.Code -> ExceptT String IO Void.Analyse.Module'
analyseModule = (flip Void.Analyse.moduleFromCode) initialState

compileModule :: Void.Analyse.Module' -> ExceptT String IO String
compileModule = return . show . (Void.Compile.compileModule initialState)

runCommand :: Args -> Command -> IO ()
runCommand args (Check file printIr) = runCatching putErrStrLn $ do
    result <- readCodeFile file >>= analyseModule
    when (verbose args) $ printInfo $ if printIr
        then show $ Void.Compile.compileModule initialState result
        else show result
    printInfo "ok"
runCommand _ (Build file lk result) = runCatching putErrStrLn $ do
    resultObjects <- mapM pipeline [file]
    let resultFile = maybe ("out" <.> extFromLink lk) id result
    link resultFile lk resultObjects
    printInfo "done"
    where
        pipeline :: String -> ExceptT String IO String
        pipeline f = readCodeFile f >>= analyseModule >>= compileModule >>= writeObjectFile f

main :: IO ()
main = do
  (args, cmd) <- customExecParser (prefs showHelpOnEmpty) (info opts fullDesc)
  runCommand args cmd
