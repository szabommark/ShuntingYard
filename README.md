# Infix kifejezések parse-olása Shunting Yard algoritmussal (Kötelező feladatok)

Mind a matematikában, mind a programozási nyelvek során találkozhatunk aritmetikai kifejezésekkel, amelyek infix módon alkalmazott operátorokat tartalmaznak. Az ilyen infix kifejezéseknek viszont a kiértékelése nem feltétlenül egyértelmű. Habár az alap aritmetikai műveleteknél ismerjük az operátorok sorrendjét, mert azt mindenkinek meg kellett általános iskolában tanulnia, de ismeretlen operátorok esetén ez nem feltétlenül egyértelmű:

a ⊕ b ⊘ c ∧ (d ⊎ e) ∨ f
(1) Hogyan kellene ezt az ismeretlen operátorokat tartalmazó kifejezést zárójelezni?

Az ilyen problémák megoldásáért szokás a programozási nyelvek megvalósítása során az operátorokat egy fixitási annotációval ellátni, amely eltárolja, hogy milyen sorrendben (precedencia) és milyen irányba (kötési irány) kell egy olyan adott kifejezést zárójelezni. Rengeteg algoritmus létezik, ami ezen információk ismeretében ki tud értékelni kifejezéseket. Ebben a feladatban egy ilyen módszert, a Shunting Yard algoritmust fogjuk megvalósítani.

## Megvalósítási terv

A `String` alapú kifejezések kiértékelését két lépésben fogjuk implementálni. Először a `String`-eket átalakítjuk egy strukturáltabb formára, amit tokeneknek hívnak (és ezt a folyamatot tokenizálásnak nevezik). A tokenek csak az algoritmushoz szükséges értékeket fogják tartalmazni: literálokat, operátorokat és zárójeleket. Az operátorokhoz szükséges információt egy előre definiált táblázatból fogjuk kinyerni. Ezután erre a strukturált tokensorozatra fogjuk alkalmazni a Shunting Yard algoritmust.

Definiáljuk a `Dir` adattípust, amely a kötési irányt reprezentálja. Két nulla paraméteres konstruktora legyen:
* `InfixL :: Dir`, amely a balra kötést reprezentálja.
* `InfixR :: Dir`, amely a jobbra kötést reprezentálja.

Kérjük meg a fordítót, hogy automatikusan példányosítsa a `Show`, `Eq` és `Ord` típusosztályokat a típusra.

Definiáljuk a `Tok` adattípust, amely a tokenek lehetséges értékeit reprezentálja. A típusnak egy típusparamétere legyen, amely azt reprezentálja, hogy milyen típus fölött végezzük majd el a műveleteket. A típusnak négy konstruktora legyen:
* `BrckOpen :: Tok a`, amely a nyitó zárójelet reprezentálja.
* `BrckClose :: Tok a`, amely a záró zárójelet reprezentálja.
* `TokLit :: a -> Tok a`, amely egy literált (az esetek nagyrészében számot) reprezentál.
* `TokBinOp :: (a -> a -> a) -> Char -> Int -> Dir -> Tok a`; a paraméterek az alábbiakat reprezentálják:
  * Az `(a -> a -> a)` típusú paraméter az operátort reprezentálja.
  * A `Char` típusú paraméter a kifejezésekben használt operátor szimbólumát (műveleti jelét) reprezentálja.
  * Az `Int` típusú paraméter, amely a kötési erősséget reprezentálja.
  * A `Dir` típusú paraméter, amely a kötési irányt reprezentálja.

A típusra írjunk manuálisan `Show` és `Eq` példányt, amelyek az operátor konstruktor függvényparaméterén kívül minden mást kiírnak/összehasonlítanak. Tesztek a működésre:

```haskell
show BrckOpen == "BrckOpen" 
show BrckClose == "BrckClose" 
show (TokLit 1) == "TokLit 1" 
show (TokLit True) == "TokLit True" 
show (TokBinOp (+) '+' 6 InfixL) == "TokBinOp '+' 6 InfixL" 
show (TokBinOp (**) '^' 8 InfixR) == "TokBinOp '^' 8 InfixR" 
TokBinOp (+) '+' 6 InfixL /= TokBinOp (-) '-' 6 InfixL 
TokBinOp (-) '-' 6 InfixL == TokBinOp (+) '-' 6 InfixL
```

Másoljuk az alábbi kódrészletet a megoldásunkba (ha nem a skeleton fájlból indultunk ki).

```haskell
basicInstances = 0 -- Ez a tesztelőnek szükséges!  

type OperatorTable a = [(Char, (a -> a -> a, Int, Dir))]  

tAdd, tMinus, tMul, tDiv, tPow :: Floating a => Tok a 
tAdd = TokBinOp (+) '+' 6 InfixL 
tMinus = TokBinOp (-) '-' 6 InfixL 
tMul = TokBinOp (*) '*' 7 InfixL 
tDiv = TokBinOp (/) '/' 7 InfixL 
tPow = TokBinOp (**) '^' 8 InfixR  

operatorTable :: Floating a => OperatorTable a 
operatorTable = [   
    ('+', ((+), 6, InfixL)),  
    ('-', ((-),  6, InfixL)),  
    ('*', ((*), 7, InfixL)),   
    ('/', ((/), 7, InfixL)),  
    ('^', ((**), 8, InfixR))   
    ]
```

## Operátorrá alakítás

Definiáljuk az `operatorFromChar` függvényt, amely egy adott operátortáblából megpróbálja kinyerni egy adott szimbólumhoz tartozó információt. Ha a táblázat tartalmaz a karakter által meghatározott művelethez információt, akkor adjuk vissza az eredményt a korábban megadott reprezentációval (`TokBinOp`) egy `Just` konstruktorba csomagolva. Ha nincs rendelkezésre álló információ, akkor az eredmény legyen `Nothing`.

```haskell
operatorFromChar :: OperatorTable a -> Char -> Maybe (Tok a)
```

Az egyszerűség kedvéért a tesztekben az alábbi függvényt fogjuk használni (Ezt a függvényt a megoldásban ne használjuk fel)! Másoljuk az alábbi kódrészletet a megoldásunkba (ha nem a skeleton fájlból indultunk ki).

```haskell
getOp :: Floating a => Char -> Maybe (Tok a) 
getOp = operatorFromChar operatorTable
```

Tesztek a működésre:

```haskell
getOp '+' == Just tAdd 
getOp '-' == Just tMinus 
getOp '^' == Just tPow 
getOp '#' == Nothing 
operatorFromChar [] '+' == Nothing 
operatorFromChar [('+', ((/), 7, InfixL))] '+' == Just (TokBinOp (/) '+' 7 InfixL)
```

## String-ek tokenizálása

Már egyes operátorokat tudunk karakterből tokenné alakítani, ezért innentől már tetszőleges `String`-et is megpróbálhatunk tokensorozattá alakítani. Definiáljuk a `parseTokens` függvényt, amely egy `String`-et egy adott operátortábla segítségével egy tokenek listájává alakít. Hasonlóan az előző feladathoz, itt is előfordulhat, hogy nem tudjuk értelmezni a kifejezést. Amennyiben olyan elemeket tartalmaz, ami nem értelmezhető, akkor a függvény `Nothing` értéket adjon eredményül. 

Az elemzés első lépéseként a `String`-et felbontjuk szavakra a szóközök mentén. Ügyeljünk arra, hogy a szóközök csak elválasztók, így az ne legyen probléma, ha a `String` esetleg szóközökkel kezdődik, szóközökkel végződik, illetve több szóköz van a tokenek között. A felesleges szóközök ne okozzanak fennakadást! Az így kapott szavakat próbáljuk meg tokenek sorozatává alakítani. Ennek lépései a következők:

* Ha nyitó/csukó zárójel(ek)ből áll a szó, akkor annyi darab nyitó/csukó zárójel tokent adjunk vissza.
* Ha egy karakterből áll a szó, akkor nézzük meg, hogy olyan nevű operátor létezik-e. Ha igen, akkor a megadott reprezentációban adjuk azt vissza, különben próbáljuk meg a `readMaybe` függvénnyel (a `Text.Read` modulból) literállá alakítani azt. Amennyiben a `readMaybe` függvény `Nothing`-ot adna vissza, a teljes tokenizálás folyamata álljon meg és `Nothing` legyen az eredmény.

Segítség a `readMaybe` használathoz, hogy annak használata ne okozzon fennakadást: A `readMaybe` eredményének típusa (tekintve hogy az Ad-hoc polimorf) a környezetből derül ki, így azt nem mindegy hogy milyen kontextusban használjuk. A legjobb, ha csak egyszer használjuk és azt a függvény törzsében tesszük (nem guardban). Amennyiben mégis szeretnénk a `readMaybe` eredményét több helyen is hivatkozni (pl. őrfeltételben is), akkor lokális definícióként rendeljük egy konstanshoz a függvény alkalmazás eredményét. Egy példa, mire is gondolunk pontosan:

```haskell
f :: String -> Integer 
f str   
  | ... rd ... = ... rd ...   
  | otherwise  = ...   
  where     
    rd = readMaybe str
```

A függvény típusa:

```haskell
parseTokens :: Read a => OperatorTable a -> String -> Maybe [Tok a]
```

Az egyszerűség kedvéért a tesztekben az alábbi függvényeket fogjuk használni. Másoljuk az alábbi kódrészletet a megoldásunkba (ha nem a skeleton fájlból indultunk ki):

```haskell
parse :: String -> Maybe [Tok Double] 
parse = parseTokens operatorTable
```

Tesztek a működésre:

```haskell
parse "1 + 2" == Just [TokLit 1, tAdd, TokLit 2] 
parse "+ +" == Just [tAdd, tAdd] 
parse "1 - ( 2 / 3 )" == Just [TokLit 1, tMinus, BrckOpen, TokLit 2, tDiv, TokLit 3, BrckClose] 
parse "((" == Just [BrckOpen, BrckOpen] 
parse "1 12 + )" == Just [TokLit 1, TokLit 12, tAdd, BrckClose] 
parse "1 # 2" == Nothing 
parse "almafa" == Nothing 
parse "1.5 + 2" == Just [TokLit 1.5, tAdd, TokLit 2] 
parse "  1.5     +  2   " == Just [TokLit 1.5, tAdd, TokLit 2]
```

## Alap Shunting Yard algoritmus - kötési erősség és irányok figyelmen kívül hagyása

Az algoritmust inkrementálisan fogjuk felépíteni, először az operátorok kötési irányát és erősségét ignoráljuk, majd későbbi feladatokban kiegészítjük az algoritmust.

Az algoritmus megvalósításához két segédlistát veszünk fel paraméterül: egy literál- és egy operátorlistát. A tokensorozat feldolgozása során az alábbi műveleteket végezzük el:
* Ha literál tokent kapunk, akkor azt szúrjuk be a literál lista elejére kicsomagolva, és azzal folytassuk az algoritmust.
* Ha nyitó zárójel vagy operátor tokent kapunk, akkor azt szúrjuk be az operátor lista elejére, és azzal folytassuk az algoritmust.
* Ha csukózárójel tokent kapunk, akkor keressük meg az első nyitó zárójel tokent az operátor listában és vegyük le az előtte lévő operátorokat. Ezeket az operátorokat sorban kiértékeljük a literál lista elemeivel, úgy, hogy mindig leveszünk két elemet a literál lista elejéről, kombináljuk a függvény segítségével, majd visszarakjuk az eredményt a lista elejére. Fontos, hogy az operátor paraméterei a literál listában fordított sorrendben vannak, ezért az operátorokat a paramétereire fordítva kell alkalmazni.

Ezzel a módszerrel minden operátor jobbra köt és a kötési erősségük azonos. Egy szemléltető példa az algoritmus működésre az `1 + 2 ∗ (3 − 4)∕5` kifejezésre:

| Tokensorozat | Operátor Lista | Literál Lista |
| :--- | :--- | :--- |
| 1 + 2 ∗ (3 − 4)∕5 | ∅ | ∅ |
| + 2 ∗ (3 − 4)∕5 | ∅ | 1 |
| 2 ∗ (3 − 4)∕5 | + | 1 |
| ∗ (3 − 4)∕5 | + | 2, 1 |
| (3 − 4)∕5 | ∗, + | 2, 1 |
| 3 − 4)∕5 | (, ∗, + | 2, 1 |
| − 4)∕5 | (, ∗, + | 3, 2, 1 |
| 4)∕5 | −, (, ∗, + | 3, 2, 1 |
| )∕5 | −, (, ∗, + | 4, 3, 2, 1 |
| ∕5 | (, ∗, + | −1, 2, 1 |
| 5 | ∕, ∗, + | −1, 2, 1 |
| ∅ | ∕, ∗, + | 5, −1, 2, 1 |

Mivel kiértékelést csak csukó zárójel esetén végzünk, ezért az algoritmus maradhat ”félig kész” állapotban. Továbbá feltehető, hogy ha `)` jellel találkozunk, akkor mindig van egy hozzátartozó `(` is.

Definiáljuk a `shuntingYardBasic` függvényt, amely egy token sorozat alapján visszaadja egy rendezett párban a kiértékeletlen literál és operátor tokenek listáját. Az olyan esetekkel, amelyek fent nincsenek definiálva (például, ha nincs literál a listában, de egy operátort akarnánk alkalmazni) még nem kell foglalkozni.

```haskell
shuntingYardBasic :: [Tok a] -> ([a], [Tok a])
```

Másoljuk az alábbi kódrészletet a megoldásunkba (ha nem a skeleton fájlból indultunk ki).

```haskell
parseAndEval ::     
    (String -> Maybe [Tok a]) ->      
    ([Tok a] -> ([a], [Tok a])) ->      
    String -> Maybe ([a], [Tok a]) 
parseAndEval parse eval input = maybe Nothing (Just . eval) (parse input)  

syNoEval :: String -> Maybe ([Double], [Tok Double]) 
syNoEval = parseAndEval parse shuntingYardBasic  

syEvalBasic :: String -> Maybe ([Double], [Tok Double]) 
syEvalBasic = parseAndEval parse (\t -> shuntingYardBasic $ BrckOpen : (t ++ [BrckClose]))
```

Tesztek a működésre:

```haskell
syNoEval "1 + 2" == Just ([2.0,1.0],[tAdd]) 
syEvalBasic "1 + 2" == Just ([3.0],[]) 
syNoEval "10 * 10 * 12" == Just ([12.0,10.0,10.0],[tMul, tMul]) 
syEvalBasic "10 * 10 * 12" == Just ([1200.0],[]) 
syNoEval "10 * 10 - 12" == Just ([12.0,10.0,10.0],[tMinus, tMul]) 
syEvalBasic "10 * 10 - 12" == Just ([-20.0],[]) 
syNoEval "( 10 * 10 ) - 12" == Just ([12.0,100.0],[tMinus]) 
syEvalBasic "( 10 * 10 ) - 12" == Just ([88.0],[]) 
syNoEval "1 + 2 * 3 - 4" == Just ([4.0,3.0,2.0,1.0],[tMinus,tMul,tAdd]) 
syEvalBasic "1 + 2 * 3 - 4" == Just ([-1.0],[])
```

## Az algoritmus javítása - kötési erősségek és irányok figyelembevétele

Egészítsük ki az algoritmust, hogy figyelembe vegye a kötési erősségeket és irányokat is. A korábban megadott algoritmus működése csak az operátor tokenek olvasása során változik:

* Operátor beszúrása esetén először vegyük le azokat az operátorokat a lista elejéről, amelyek kötési erőssége nagyobb, mint a beszúrandó operátoré (a csukó zárójel kötési erőssége legyen 0) vagy ha a beszúrandó operátor balra kötő, akkor azokat vegyük le a listában lévő operátorok közül, amelyek kötési erőssége nagyobb egyenlők a beszúrandónál. A kivett operátorokat értékeljük ki a literál listán ugyanazon a módon, mint a csukó zárójel token esetén tettük. Az új operátorlista a maradék, nem kiértékelt operátorok listája legyen, amelynek az elejére illesszük be az aktuálisan beszúrandó operátort.

Egy szemléltető példa az `1 + 2 ∗ 3 − 4` kifejezésre:

| Tokensorozat | Operátor Lista | Literál Lista | Magyarázat |
| :--- | :--- | :--- | :--- |
| 1 + 2 ∗ 3 − 4 | ∅ | ∅ | |
| + 2 ∗ 3 − 4 | ∅ | 1 | |
| 2 ∗ 3 − 4 | + | 1 | Nincs kiértékelendő operátor |
| ∗ 3 − 4 | + | 2, 1 | |
| 3 − 4 | ∗, + | 2, 1 | ∗ kötési erőssége nagyobb, nincs kiértékelendő operátor |
| − 4 | ∗, + | 3, 2, 1 | |
| 4 | − | 7 | a − operátor kötési erőssége kisebb egyenlő mint, a ∗-é és a +-é, ezért a ∗-gal kiértékeljük a literál lista első két elemét, majd annak az eredmény és a literál lista 3. elemét az +-al. |
| ∅ | − | 4, 7 | |

Definiáljuk a `shuntingYardPrecedence` függvényt, amely a fent leírtaknak megfelelően egészíti ki az alap Shunting Yard algoritmust. A megoldáshoz ajánlott az előző megoldás kódját felhasználni. Mivel a zárójelek között ki is kell értékelni, ezért feltehető, hogy ha `)` jellel találkozunk, akkor mindig van egy hozzátartozó `(` is.

```haskell
shuntingYardPrecedence :: [Tok a] -> ([a], [Tok a])
```

Másoljuk az alábbi kódrészletet a megoldásunkba (ha nem a skeleton fájlból indultunk ki).

```haskell
syEvalPrecedence :: String -> Maybe ([Double], [Tok Double]) 
syEvalPrecedence = parseAndEval   
  parse   
  (\t -> shuntingYardPrecedence $ BrckOpen : (t ++ [BrckClose]))
```

Tesztek a működésre:

```haskell
syEvalPrecedence "1 + 2" == Just ([3.0],[]) 
syEvalPrecedence "1 + 2 * 3 + 4" == Just ([11.0],[]) 
syEvalPrecedence "( 1 + 2 ) * 3 + 4" == Just ([13.0],[]) 
syEvalPrecedence "( 1 + 2 ) * ( 3 + 4 )" == Just ([21.0],[]) 
syEvalPrecedence "1 + 2 * 3 - 4 / 5" == Just ([6.2],[]) 
syEvalPrecedence "2 ^ 2 * 3" == Just ([12.0],[]) 
syEvalPrecedence "1 - 2 - 3" == Just ([-4.0],[]) 
syEvalPrecedence "+ 1 2" == Just ([3.0],[]) 
syEvalPrecedence "    + 1 2   " == Just ([3.0],[]) 
syEvalPrecedence " +   1   2     " == Just ([3.0],[])
```
