module SlepysLexer(Token(..)
                 , plus
                 , minus
                 , mult
                 , division
                 , assign
                 , comma
                 , colon
                 , lPar
                 , rPar
                 , def
                 , if_
                 , else_
                 , eq
                 , lt 
                 , le
                 , gt
                 , ge
                 , semicolon
                 , pass
                 , identifier
                 , integer
                 , str
                 , whitespace
                 , newline
                 , token
                 , tokens
) where
import Parser
import ParsingPrimitives

data Token = Plus Int
           | Minus Int
           | Mult Int
           | Div Int
           | Assign Int
           | Comma Int
           | Colon Int
           | LPar Int
           | RPar Int
           | Def Int
           | If Int
           | Else Int
           | Eq Int
           | Lt Int
           | Le Int
           | Gt Int
           | Ge Int
           | Semicolon Int
           | Pass Int
           | Identifier Int String
           | Integer Int Int
           | Str Int String
           | Whitespace Int Int
           | Newline Int Int
           -- line num, value
    deriving Show

insideString :: Parser Char
insideString = do
              c <- item
              if c == '"' then
                empty
              else if c == '\\' then 
                item
              else
                return c


quotedString :: Parser String
quotedString = do
               char '"'
               str <- many insideString
               char '"'
               return str

ident :: Parser String
ident = (:) <$> identFirstLetter <*> many identNextLetter

identFirstLetter :: Parser Char
identFirstLetter = lowerCase <|> char '_'

identNextLetter :: Parser Char
identNextLetter = letter <|> char '_' <|> digit 

plus = char '+' >> return Plus
minus = char '-' >> return Minus
mult = char '*' >> return Mult
division = char '/' >> return Div
assign = char '=' >> return Assign
comma = char ',' >> return Comma
colon = char ':' >> return Colon
lPar = char '(' >> return LPar
rPar = char ')' >> return RPar
def = string "def" >> return Def
if_ = string "if" >> return If
else_ = string "else" >> return Else
eq = string "==" >> return Eq
lt = string "<" >> return Lt
le = string "<=" >> return Le
gt = string ">" >> return Gt
ge = string ">=" >> return Ge
semicolon = char ';' >> return Semicolon
pass = string "pass" >> return Pass
identifier = ident >>= \n -> return $ Identifier n
integer = int >>= \n -> return $ Integer n
str = quotedString >>= \s -> return $ Str s
whitespace = spaces >>= \n -> return $ Whitespace n
newline = eols >>= \n -> return $ Newline n

token :: Parser Token
token = plus
    <|> minus
    <|> mult
    <|> division
    <|> assign
    <|> comma
    <|> colon
    <|> lPar
    <|> rPar
    <|> def
    <|> if_
    <|> else_
    <|> eq
    <|> lt
    <|> le
    <|> gt
    <|> ge
    <|> semicolon
    <|> pass
    <|> identifier
    <|> integer
    <|> str
    <|> whitespace
    <|> newline

tokens :: Parser [Token]
tokens = many token
