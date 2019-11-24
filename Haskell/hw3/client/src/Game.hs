module Game
  ( isAlive
  , conv
  ) where

import Data.Set (Set, empty, insert, member)

import GameTypes

isAlive :: ScreenState -> Pos -> Bool
isAlive s pos = pos `member` (s ^. cells)

conv :: ScreenState -> String -> Set Pos
conv s b =
  foldl
    (\a (i, v) ->
       if v == 'x'
         then insert (i `mod` w, i `div` h) a
         else a)
    empty
    (zip [0 ..] b)
  where
    w = s ^. width
    h = s ^. height
