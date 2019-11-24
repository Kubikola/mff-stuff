module Writer
  ( Writer(DummyWriter)
  , initWriter
  , write
  , stopWriter
  ) where

import Control.Concurrent
import Control.Concurrent.MVar (MVar)
import System.IO (Handle, hFlush, hPutStr)

data Writer
  = Writer (MVar WriteCmd)
  | DummyWriter

data WriteCmd
  = Message String
  | Stop (MVar ())

initWriter :: Handle -> IO Writer
initWriter h = do
  m <- newEmptyMVar
  let w = Writer m
  forkIO $ writer h w
  return w

writer :: Handle -> Writer -> IO ()
writer h (Writer m) = loop
  where
    loop = do
      cmd <- takeMVar m
      case cmd of
        Message msg -> do
          hPutStr h $ msg ++ "\r\n"
          hFlush h
          loop
        Stop s -> putMVar s ()

write :: Writer -> String -> IO ()
write (Writer m) msg = do
  forkIO $ putMVar m (Message msg)
  return ()

stopWriter :: Writer -> IO ()
stopWriter (Writer m) = do
  s <- newEmptyMVar
  putMVar m (Stop s)
  takeMVar s
