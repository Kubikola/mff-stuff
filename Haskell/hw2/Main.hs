import SlepysLexer
import Parser

main :: IO ()
main = do
       inp <- getContents
       let res = parse tokens inp
       let parsed = fst . head $ res
       let out = foldl (\a v -> a ++ "\n" ++ show v) "" parsed
       putStr out
       return ()

