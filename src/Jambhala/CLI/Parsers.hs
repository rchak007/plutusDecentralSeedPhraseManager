{-# LANGUAGE FlexibleContexts #-}

module Jambhala.CLI.Parsers (commandParser, contractsPretty) where

import Cardano.Ledger.BaseTypes (Network (..))
import Control.Monad.Reader (MonadReader (..))
import Data.List (unlines)
import Data.Map.Strict qualified as M
import Jambhala.CLI.Types
import Options.Applicative

commandParser :: MonadReader JambContracts m => m (ParserInfo Command)
commandParser = do
  pw <- parseWrite
  pa <- parseAddress
  ph <- parseHash
  pt <- parseTest
  let p = parseList <|> pa <|> ph <|> pt <|> pw <|> parseUpdate
  pure . info (helper <*> p) $ mconcat [fullDesc, progDesc "Jambhala Plutus Development Suite"]

parseList :: Parser Command
parseList = flag' List (long "list" <> short 'l' <> help "List the available contracts")

parseAddress :: (MonadReader JambContracts m) => m (Parser Command)
parseAddress =
  fmap ((<*> parseNetwork) . fmap Addr) . parseContractName $
    mconcat
      [ long "address",
        short 'a',
        metavar "CONTRACT",
        help "Display CONTRACT address with optional mainnet flag (default is testnet)"
      ]

parseNetwork :: Parser Network
parseNetwork =
  flag Testnet Mainnet $
    mconcat
      [ long "main",
        short 'm',
        help "Use mainnet address instead of testnet"
      ]

parseHash :: MonadReader JambContracts m => m (Parser Command)
parseHash =
  fmap (fmap Hash) . parseContractName $
    mconcat
      [ long "hash",
        short 's',
        metavar "CONTRACT",
        help "Hash validator for CONTRACT"
      ]

parseTest :: MonadReader JambContracts m => m (Parser Command)
parseTest =
  fmap (fmap Test) . parseContractName $
    mconcat
      [ long "test",
        short 't',
        metavar "CONTRACT",
        help "Test CONTRACT with emulator"
      ]

parseWrite :: MonadReader JambContracts m => m (Parser Command)
parseWrite =
  fmap ((<*> parseNetwork) . (<*> parseFName) . fmap Write) . parseContractName $
    mconcat
      [ long "write",
        short 'w',
        metavar "CONTRACT",
        help "Write CONTRACT to file with optional FILENAME (default is CONTRACT.plutus) and mainnet flag"
      ]
  where
    parseFName = optional $ argument str (metavar "FILENAME")

parseUpdate :: Parser Command
parseUpdate =
  flag'
    Update
    ( mconcat
        [ long "update",
          short 'u',
          help "Update plutus-apps to optional TAG or COMMIT (default is latest commit)"
        ]
    )
    <*> optional (argument str $ metavar "TAG/COMMIT")

parseContractName :: MonadReader JambContracts m => Mod OptionFields String -> m (Parser String)
parseContractName fields = do
  contracts <- ask
  let readMName = eitherReader $ \c ->
        if c `M.member` contracts
          then Right c
          else
            Left $
              "Error: contract not found - choose one of the contracts below:\n\n"
                ++ contractsPretty contracts
  pure $ option readMName fields

contractsPretty :: JambContracts -> String
contractsPretty = unlines . map ('\t' :) . M.keys