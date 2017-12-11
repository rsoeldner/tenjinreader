{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell #-}
module Handler.WebSocketHandler.Utils where

import Import
import Control.Lens
import qualified Data.Text as T
import Data.Char
import Common
import Model
import Text.Pretty.Simple
import Yesod.WebSockets
import Text.MeCab
import KanjiDB
import NLP.Romkan
import NLP.Japanese.Utils

type WsHandlerM = ReaderT WsHandlerEnv Handler

data WsHandlerEnv = WsHandlerEnv
  { kanjiSearchResult :: IORef ([KanjiId], Int)
  , kanjiVocabResult  :: IORef ([VocabId], Int)
  , vocabSearchResult :: IORef ([VocabId], Int)
  , currentUserId :: Int64
  }

-- Convert Kanji to furigana (hiragana)
getKana :: Text -> Handler (Text)
getKana t = do
  m <- asks appMecabPtr
  nodes <- liftIO $ parseToNodes m t
  let feats = map nodeFeature nodes
      -- get the last part of the mecab output, this will include '*'
      readings :: [Text]
      readings = catMaybes $ map (headMay . reverse . (T.splitOn ",")) feats
      -- convert valid characters to hiragana
      f = map katakanaToHiragana $ filter hasKanaOrKanji readings

  return $ mconcat f
