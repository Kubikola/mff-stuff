module MainBrick
  ( mainBrick
  ) where

import Brick
import Brick.BChan
import qualified Brick.Types as T
import Brick.Util (bg, fg, on)
import Brick.Widgets.Border (border)
import Brick.Widgets.Center (center)
import Control.Concurrent (forkIO, killThread, threadDelay)
import qualified Control.Exception as E
import Control.Monad (forever, void)
import Control.Monad.IO.Class (liftIO)
import Data.Maybe (fromJust)
import Data.Set (empty)
import qualified Graphics.Vty as V
import qualified Graphics.Vty.Attributes as Color
import Network.Socket
import System.IO

import Game
import GameTypes

data Tick =
  Tick

{- this is for creating the initial state -}
initState :: ScreenState
initState =
  ScreenState
    { _curPos = (0, 0)
    , _curHighlighted = True
    , _cells = empty
    , _width = defaultWidth
    , _height = defaultHeight
    , _writer = DummyWriter
    , _reader = DummyReader
    }

putWriterReader :: Writer -> Reader -> ScreenState -> ScreenState
putWriterReader w r s = s & writer .~ w & reader .~ r

sendMsg :: ScreenState -> String -> IO ()
sendMsg s = write $ s ^. writer

receiveMsg :: ScreenState -> IO (Maybe String)
receiveMsg s = lastMsg $ s ^. reader

quitBricks :: ScreenState -> EventM () (Next ScreenState)
quitBricks s = liftIO (sendMsg s "quit") >> halt s

{- This function converts the state to a list of widget layers to be drawn,
 - we only draw a single layer. -}
renderApp :: ScreenState -> [Widget n]
renderApp s = [center (title <=> mainLayer s)]

{- Operator <=> combines widgets vertically (as seen above),
 - operator <+> combines them horizontally. -}
-- mainLayer s = foldr1 (<+>) $ map (letter s) [0 .. 10]
mainLayer :: ScreenState -> Widget n
mainLayer s =
  border $
  foldr1
    (<+>)
    [ line2widget s [(x, y) | y <- [0 .. s ^. height - 1]]
    | x <- [0 .. s ^. width - 1]
    ]

line2widget :: ScreenState -> [Pos] -> Widget n
line2widget s xs = foldr1 (<=>) $ map (pos2widget s) xs

pos2widget :: ScreenState -> Pos -> Widget n
pos2widget s pos
  | isAlive s pos =
    if s ^. curHighlighted && pos == s ^. curPos
      then withAttr cursorHl $ str "X"
      else str "X"
  | otherwise =
    if s ^. curHighlighted && pos == s ^. curPos
      then withAttr cursorHl $ str " "
      else str " "

title :: Widget n
title = border $ str "Game of Life"

cursorHl :: AttrName
cursorHl = attrName "cursorHl"

{- 
 - Event handlers that modify the state. They should in fact return a monad,
 - but that is vastly simplified by the helper functions:
 -
 - halt newstate   -- halts the app
 - continue newstate    -- continues executing the app with the supplied state
 -
 - The record update syntax is used as such:
 - originalItem{modifiedField = new value}
 -}
handleEvent :: ScreenState -> BrickEvent () Tick -> EventM () (Next ScreenState)
handleEvent s (AppEvent Tick) = do
  msgM <- liftIO $ receiveMsg s
  case words <$> msgM of
    Just ws ->
      if head ws == "board"
        then continue $ s & cells .~ conv s (ws !! 1)
        else continue s
    Nothing -> continue s
handleEvent s (T.VtyEvent (V.EvKey k [])) =
  case k of
    V.KEsc -> quitBricks s
    V.KLeft -> move L s
    V.KRight -> move R s
    V.KUp -> move U s
    V.KDown -> move D s
    V.KChar 'q' -> quitBricks s
    V.KChar 'h' -> move L s
    V.KChar 'j' -> move D s
    V.KChar 'k' -> move U s
    V.KChar 'l' -> move R s
    V.KChar 'v' -> continue $ s & curHighlighted %~ not
    V.KChar 'x' -> do
      liftIO . sendMsg s $ "flip " ++ show (s ^. curPosX) ++ " " ++
        show (s ^. curPosY)
      continue s
    V.KChar ' ' -> liftIO (sendMsg s "step") >> continue s
    _ -> continue s --ignore all other keys
handleEvent s _ = continue s --also ignore all other events

move :: Dir -> ScreenState -> EventM () (Next ScreenState)
move d s
  | d == L = continue $ s & curPosX .~ max 0 (x - 1)
  | d == R = continue $ s & curPosX .~ min w1 (x + 1)
  | d == U = continue $ s & curPosY .~ max 0 (y - 1)
  | d == D = continue $ s & curPosY .~ min h1 (y + 1)
  where
    x = s ^. curPos . _1
    y = s ^. curPos . _2
    w1 = s ^. width - 1
    h1 = s ^. height - 1

{- This constructs the Brick app from the available functions -}
app :: App ScreenState Tick ()
app =
  App
    { appDraw = renderApp
    , appChooseCursor = showFirstCursor
    , appHandleEvent = handleEvent
    , appStartEvent = return
    , appAttrMap =
        const $ attrMap V.defAttr [(cursorHl, Color.black `on` Color.cyan)]
    }

{- main just starts Brick main and discards (using void) the final state -}
mainBrick :: Socket -> IO ()
mainBrick sck = do
  h <- socketToHandle sck ReadWriteMode
  hSetBuffering h (BlockBuffering Nothing) --we will flush manually
  chan <- newBChan 10
  timerTId <-
    forkIO . forever $ do
      writeBChan chan Tick
      threadDelay 100000 --100ms
  initVty <- V.mkVty V.defaultConfig
  E.bracket
              --acquire resources
    (do w <- initWriter h
        rInf <- initReader h
        return (w, rInf))
    (\(w, rInf)
         --release resources
      -> do
       killThread timerTId
       stopWriter w
       killThread $ snd rInf
       hClose h)
    (\(w, rInf) ->
       void $
       customMain
         initVty
         (V.mkVty V.defaultConfig)
         (Just chan)
         app
         (putWriterReader w (fst rInf) initState))
