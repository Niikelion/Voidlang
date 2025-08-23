module Main where

import Options.Applicative
import System.IO
import Void.Parser
import Void.Compile
import Control.Monad
import Control.Monad.State(MonadTrans(..))
import Control.Monad.Except

data Args = Args {
    verbose :: Bool
}

putErrStrLn :: String -> IO ()
putErrStrLn = hPutStrLn stderr

runCatching :: Monad m => (e -> m a) -> ExceptT e m a -> m a
runCatching catch m = runExceptT m >>= either catch return

argsParser :: Parser Args
argsParser = Args
    <$> switch ( long "verbose" <> help "Enables verbose output" )

data Command
    = Check String
    | Build String
    deriving (Eq, Show)

checkParser :: Parser Command
checkParser = Check <$> (argument str $ metavar "FILE")

buildParser :: Parser Command
buildParser = Build <$> (argument str $ metavar "FILE")

commandsParser:: Parser Command
commandsParser = hsubparser $
    (command "check" $ info checkParser $ progDesc "Check the correctness of a sigle file") <>
    (command "build" $ info buildParser $ progDesc "Build the project")

opts :: Parser (Args, Command)
opts = (,) <$> argsParser <*> commandsParser <**> helper

printInfo :: String -> ExceptT String IO ()
printInfo = lift . putStrLn

runCommand :: Args -> Command -> IO ()
runCommand args (Check file) = runCatching putErrStrLn $ do
    fileContent <- lift $ readFile file
    code <- parseCode fileContent
    result <- moduleFromCode code
    when (verbose args) $ printInfo $ show result
    printInfo "ok"
runCommand _ (Build file) = runCatching putErrStrLn $ do
    fileContent <- lift $ readFile file
    code <- parseCode fileContent
    result <- moduleFromCode code
    let ir = compileModule result
    printInfo $ show ir
    printInfo "ok"

main :: IO ()
main = do
  (args, cmd) <- customExecParser (prefs showHelpOnEmpty) (info opts fullDesc)
  runCommand args cmd
