module ParsingPrimitives where

import Parser
import Data.Char

item :: Parser Char
item = makeParser $ \inp -> case inp of
                (x : xs) -> [(x, xs)]
                [] -> []

sat :: (Char -> Bool) -> Parser Char
sat p = do
        c <- item
        if p c then
            return c
        else 
            empty

upperCase :: Parser Char
upperCase = sat isUpper

lowerCase :: Parser Char
lowerCase = sat isLower

letter :: Parser Char
letter = lowerCase <|> upperCase

digit :: Parser Char
digit = sat isDigit

char :: Char -> Parser Char
char c = sat (==c)

string :: String -> Parser String
string [] = pure []
string (x : xs) = (:) <$> char x <*> string xs

nat :: Parser Int
nat = fmap read (some digit)

neg :: Parser Int
neg = do
      char '-'
      n <- nat
      return (-n)

int :: Parser Int
int = neg <|> nat

space :: Parser Char
space = sat (== ' ')

spaces :: Parser Int
spaces = length <$> some space

junk :: Parser ()
junk = many space >> return ()

eol :: Parser Char
eol = sat (== '\n')

eols :: Parser Int
eols = length <$> some eol

-- token :: Parser a -> Parser a
-- token p = do
--           junk
--           x <- p
--           junk
--           return x

-- character :: Char -> Parser Char
-- character = token . char