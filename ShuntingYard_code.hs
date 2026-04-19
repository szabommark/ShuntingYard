module Beadprob where
import Data.Either
import Data.Maybe
import Text.Read
import Data.Char

--megvalositasi terv

data Dir = InfixL | InfixR
  deriving (Show, Eq, Ord)

data Tok a = BrckOpen | BrckClose | TokLit a | TokBinOp (a -> a -> a) Char Int Dir

instance Show a => Show (Tok a) where
  show BrckOpen = "BrckOpen"
  show BrckClose = "BrckClose"
  show (TokLit a) = "TokLit " ++ show a
  show (TokBinOp _ op pow dir) = "TokBinOp " ++ show op ++ " " ++ show pow ++ " " ++ show dir

instance Eq a => Eq (Tok a) where
  (==) BrckOpen BrckOpen = True
  (==) BrckClose BrckClose = True
  (==) (TokLit x) (TokLit y) = x == y
  (==) (TokBinOp _ op1 pow1 dir1) (TokBinOp _ op2 pow2 dir2) = op1 == op2 && pow1 == pow2 && dir1 == dir2
  _ == _ = False

--adott

basicInstances = 0 -- Mágikus tesztelőnek kell ez, NE TÖRÖLD!

type OperatorTable a = [(Char, (a -> a -> a, Int, Dir))]

tAdd, tMinus, tMul, tDiv, tPow :: (Floating a) => Tok a
tAdd = TokBinOp (+) '+' 6 InfixL
tMinus = TokBinOp (-) '-' 6 InfixL
tMul = TokBinOp (*) '*' 7 InfixL
tDiv = TokBinOp (/) '/' 7 InfixL
tPow = TokBinOp (**) '^' 8 InfixR

operatorTable :: (Floating a) => OperatorTable a
operatorTable =
    [ ('+', ((+), 6, InfixL))
    , ('-', ((-), 6, InfixL))
    , ('*', ((*), 7, InfixL))
    , ('/', ((/), 7, InfixL))
    , ('^', ((**), 8, InfixR))
    ]

--1. feladat: Operátorrá alakítás

operatorFromChar :: OperatorTable a -> Char -> Maybe (Tok a)
operatorFromChar [] _ = Nothing -- üres az operátortábla -> bármi lehet a karakter nem lesz eredmény
operatorFromChar ((op,(fOp, prec, kot)) : xs) jel
    |  op == jel = Just (TokBinOp fOp op prec kot) -- ha a tábla adott sorában megtalálja az operátort, akkor  visszaadja a hozzá tartozó tokent
    |  otherwise = operatorFromChar xs jel --ha nem akkor pedig megy tovább



getOp :: (Floating a) => Char -> Maybe (Tok a)
getOp = operatorFromChar operatorTable
--2. feladat



parseTokens :: Read a => OperatorTable a -> String -> Maybe [Tok a]
parseTokens t str = sequence (lista t (words str)) -- sequence: kap egy maybe-kből álló tömböt, és visszaad egy nothingot ha talál nothingot egyébként megint a tartalmát, words: szóközönként szavakra bontja
  where
    lista _ [] = [] --üres a words-től megkapott tömb, akkor visszaad üreset
    lista t (x : xs)
      | [y] <- x, Just op <- operatorFromChar t y = Just op : lista t xs -- ha x egy 1 elemű tömb(mivel nem lehet egymás mellett), akkor megkeresi a táblában és visszaadja Just-ként
      | all (`elem` "()") x = token x ++ lista t xs -- ha a tömb minden eleme benne van a "()" stringben, vagyis a két zárójel közül az egyik, akkor egyesével értékelje ki a token függvénnyel
      | Just n <- readMaybe x = Just (TokLit n) : lista t xs -- ha readMaybe be tudja olvasni mint szám, akkor adja vissza
      | otherwise = [Nothing] --ha bármi mást talál akkor nothing



token :: String -> [Maybe (Tok a)]
token [] = []
token (x:xs)
  | x == '(' = Just BrckOpen : token xs
  | x == ')' = Just BrckClose : token xs
  | otherwise = [Nothing]


parse :: String -> Maybe [Tok Double]
parse = parseTokens operatorTable

--3. feladat

isToklit :: Tok a -> Bool --ha szám akkor True értéket fog visszaadni
isToklit (TokLit _) = True
isToklit _ = False

valueFromTok :: Tok a -> a -- ha TokLit akkor visszaadja az értékét számként
valueFromTok (TokLit x) = x

shuntingYardBasic :: [Tok a] -> ([a], [Tok a])
shuntingYardBasic = szet [] [] -- meghívjuk két üres tömbbel, ezzeket fogja folyamatosan feltölteni és visszaadni
  where
    szet szam op [] = (szam, op) -- ha végzett, vagy üres a bemenet, akkor visszatér a két tömmbel egy párban
    szet szam op (x:xs) -- elemenként végigmeny
      | isToklit x = szet (valueFromTok x : szam) op xs -- ha szám akkor számlistáshoz adja
      | isBrckClose x = szet (szamlista (kiertek szam op)) (oplista (kiertek szam op)) xs -- ha ) akkor elindítja a két meglévő listán a kiértékelést (kiertek)
      | otherwise = szet szam ( x : op) xs -- ha bármi mást talál, akkor operátorba kerül


kiertek :: [a] -> [Tok a] -> ([a],  [Tok a]) -- két tömbből egy pár kerül vissza
kiertek [] [] = ([],[]) -- ha üres akkor üres tömböket ad vissza, de ez csak akkor eshet meg ha eleve üres a bemenet
kiertek x (BrckClose:ys) = kiertek x ys -- )-t átugorja de nem kerülhet bele amúgy sem
kiertek x (BrckOpen:ys) = ((x), (ys)) -- ha ( akkor visszadja a két tömböt az eredeti függvénynek, mivel csak eddig kell kiértékelnie
kiertek (x1:x2:xs) ((TokBinOp op _ _ _):ys) = kiertek ((op x2 x1):xs) ys -- minden más esetben levesz két számot illetve kinyeri az operátorból a műveletet és használja a két számra, viszont mivel visszafele haladunk így fordítva avnnak a számok

szamlista :: ([a], [Tok a]) -> [a] --számlista az adott párból az első tömb
szamlista (x,_) = x

oplista :: ([a], [Tok a]) -> [Tok a]--oplista az adott párból a második tömb
oplista (_,y) = y


isBrckClose :: Tok a -> Bool
isBrckClose BrckClose = True
isBrckClose _ = False

parseAndEval :: 
    (String -> Maybe [Tok a]) -> 
     ([Tok a] -> ([a], [Tok a])) -> 
     String -> Maybe ([a], [Tok a]) 
parseAndEval parse eval input = maybe Nothing (Just . eval) (parse input) 
 
syNoEval :: String -> Maybe ([Double], [Tok Double]) 
syNoEval = parseAndEval parse shuntingYardBasic 
 
syEvalBasic :: String -> Maybe ([Double], [Tok Double]) 
syEvalBasic = parseAndEval parse (\t -> shuntingYardBasic $ BrckOpen : (t ++ [BrckClose]))


--4. feladat


shuntingYardPrecedence :: [Tok a] -> ([a], [Tok a])
shuntingYardPrecedence = szet ([], []) -- egy üres tömbökből álló párt kap meg a függvény, ez működött volna az előző feladatra is, csak későn jöttem rá, hogy ezt így lehet
  where
    szet (szam, oper) [] = (szam, oper) -- ha üres a bemeneti [Tok a] tömb, akkor visszaadja a két elkészült tömböt
    szet (szam, oper) (x:xs) = szet (eset (szam, oper) x) xs -- máskülönben részenként kiértékeli a 
      where
        eset (szam, oper) BrckClose = kiertek2 szam oper --ha )-t talál, akkor ugyan úgy jár el mint a basic
        eset (szam, oper) (TokLit y) = (y : szam, oper) -- ha a soron következő rész egy TokLit, vagyis szám, akkor beleteszi a számlistába
        eset (x:y:szam, (TokBinOp op _ ero1 _):oper) elozo@(TokBinOp _ _ ero2 kot)  -- minden megtalált műveleti jelnél megnézi, hogy precedencia és fixitás alapján mehet e tovább, vagy ki kell e értékelnie
          | (ero1 > ero2 || ero1 == ero2) && kot == InfixL = eset ((op y x) : szam, oper) elozo
          | ero1 > ero2 && kot == InfixR = eset ((op y x) : szam, oper) elozo
        eset (szam, oper) op = (szam, op : oper) -- bármilyen más megtalált operátornál csak beleteszi az operátorok tömbjébe, ez lényegében, csak a ( miatt kell, mert ez alapján tudja a zárójelek kiértékelője, hogy meddig kell mennie

kiertek2 :: [a] -> [Tok a] -> ([a],[Tok a])
kiertek2 szam (BrckOpen:xs) = (szam, xs)
kiertek2 (x1:x2:xs) (TokBinOp op _ _ _:ys) = kiertek2 ((op x2 x1):xs) ys




syEvalPrecedence :: String -> Maybe ([Double], [Tok Double]) 
syEvalPrecedence = parseAndEval 
  parse 
  (\t -> shuntingYardPrecedence $ BrckOpen : (t ++ [BrckClose]))



eqError = 0




