module Parser(Parser(parse), makeParser, (<|>), empty, some, many, fail) where

import Control.Applicative

newtype Parser a = P { parse :: String -> [(a, String)] }

makeParser :: (String -> [(a, String)]) -> Parser a
makeParser = P

instance Functor Parser where
 -- fmap :: (a -> b) -> Parser a -> Parser b
    fmap f (P p) = P $ \inp -> p inp >>= \(x, out) -> return (f x, out)

instance Applicative Parser where
 -- pure :: a -> Parser a
    pure x = P $ \out -> [(x, out)]

 -- (<*>) :: Parser (a -> b) -> Parser a -> Parser b
    P pf <*> p = P $ \inp -> pf inp >>= \(f, inp2) -> parse (fmap f p) inp2

instance Monad Parser where
 -- return = pure
 
 -- (>>=) :: Parser a -> (a -> Parser b) -> Parser b
    P p >>= f = P $ \inp -> p inp >>= \(x, inp2) -> parse (f x) inp2

instance Alternative Parser where
 -- empty :: Parser a
    empty = P $ \_ -> []

 -- (<|>) :: Parser a -> Parser a -> Parser a
    P p1 <|> P p2 = P $ \inp -> case p1 inp of 
                                    [(x, out)] -> [(x, out)]
                                    [] -> p2 inp

 -- many :: Parser a -> Parser [a]
    many p = some p <|> pure []

 -- some :: Parser a -> Parser [a]
    some p = (:) <$> p <*> many p

