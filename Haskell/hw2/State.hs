module State(state, get, put) where

newtype State s a = S { runState :: s -> (a, s) }

state :: (s -> (a, s)) -> State s a
state = S

get :: State s s
get = state $ \s -> (s, s)

put :: s -> State s ()
put newState = S $ \x -> ((), newState)

instance Functor (State s) where
-- fmap :: (a -> b) -> State s a -> State s b
   fmap g st = g <$> st
   
instance Applicative (State s) where
-- pure :: a -> ST a
   pure x = S $ \s -> (x,s)
   
-- (<*>) :: ST (a -> b) -> ST a -> ST b
   stf <*> stx = do
                 f <- stf
                 x <- stx
                 return $ f x
   
instance Monad (State s) where
-- (>>=) :: ST a -> (a -> ST b) -> ST b
   st >>= f = S (\s -> let (x,s') = runState st s in runState (f x) s')