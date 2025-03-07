{-# LANGUAGE RankNTypes #-}

module Lets.Lens (
  fmapT
, over
, fmapTAgain
, Set
, sets
, mapped
, set
, foldMapT
, foldMapOf
, foldMapTAgain
, Fold
, folds
, folded
, Get
, get
, Traversal
, both
, traverseLeft
, traverseRight
, Traversal'
, Lens
, Prism
, _Left
, _Right
, prism
, _Just
, _Nothing
, setP
, getP
, Prism'
, modify
, (%~)
, (.~)
, fmodify
, (|=)
, fstL
, sndL
, mapL
, setL
, compose
, (|.)
, identity
, product
, (***)
, choice
, (|||)
, Lens'
, cityL
, stateL
, countryL
, streetL
, suburbL
, localityL
, ageL
, nameL
, addressL
, intAndIntL
, intAndL
, getSuburb
, setStreet
, getAgeAndCountry
, setCityAndLocality
, getSuburbOrCity
, setStreetOrState
, modifyCityUppercase
, modifyIntAndLengthEven
, traverseLocality
, intOrIntP
, intOrP
, intOrLengthEven
) where

import Control.Applicative(Applicative((<*>), pure))
import Data.Char(toUpper)
import Data.Foldable(Foldable(foldMap))
import Data.Functor((<$>))
import Data.Map(Map)
import qualified Data.Map as Map(insert, delete, lookup)
import Data.Monoid(Monoid)
import qualified Data.Set as Set(Set, insert, delete, member)
import Data.Traversable(Traversable(traverse))
import Lets.Data(AlongsideLeft(AlongsideLeft, getAlongsideLeft), AlongsideRight(AlongsideRight, getAlongsideRight), Identity(Identity, getIdentity), Const(Const, getConst), Tagged(Tagged, getTagged), IntOr(IntOrIs, IntOrIsNot), IntAnd(IntAnd), Person(Person), Locality(Locality), Address(Address))
import Lets.Choice(Choice(left, right))
import Lets.Profunctor(Profunctor(dimap))
import Prelude hiding (product)

-- $setup
-- >>> import qualified Data.Map as Map(fromList)
-- >>> import qualified Data.Set as Set(fromList)
-- >>> import Data.Bool(bool)
-- >>> import Data.Char(ord)
-- >>> import Lets.Data

-- Let's remind ourselves of Traversable, noting Foldable and Functor.
--
-- class (Foldable t, Functor t) => Traversable t where
--   traverse ::
--     Applicative f => 
--     (a -> f b)
--     -> t a
--     -> f (t b)

-- | Observe that @fmap@ can be recovered from @traverse@ using @Identity@.
--
-- /Reminder:/ fmap :: Functor t => (a -> b) -> t a -> t b
fmapT ::
  Traversable t =>
  (a -> b)
  -> t a
  -> t b
fmapT f = getIdentity . traverse (Identity . f)


-- | Let's refactor out the call to @traverse@ as an argument to @fmapT@.
over :: 
  ((a -> Identity b) -> s -> Identity t)
  -> (a -> b)
  -> s
  -> t
over f g s = getIdentity $ f (Identity . g) s
  --error "todo: over"

-- | Here is @fmapT@ again, passing @traverse@ to @over@.
fmapTAgain ::
  Traversable t =>
  (a -> b)
  -> t a
  -> t b
fmapTAgain = over traverse
  --error "todo: fmapTAgain"

-- | Let's create a type-alias for this type of function.
type Set s t a b =
  (a -> Identity b)
  -> s
  -> Identity t

-- | Let's write an inverse to @over@ that does the @Identity@ wrapping &
-- unwrapping.
sets ::
  ((a -> b) -> s -> t)
  -> Set s t a b  
sets f g s = Identity $ f (getIdentity . g) s
  --error "todo: sets"

mapped ::
  Functor f =>
  Set (f a) (f b) a b -- (a -> Id b) -> f a -> Id (f b)
mapped g x =
  let g' = getIdentity . g
      r  = g' <$> x
  in Identity $ r
  --error "todo: mapped"

set ::
  Set s t a b  -- (a -> Identity b) -> s -> Identity t
  -> s
  -> b
  -> t
set k s b = getIdentity$  k (const $ Identity b) s



----

-- | Observe that @foldMap@ can be recovered from @traverse@ using @Const@.
--
-- /Reminder:/ foldMap :: (Foldable t, Monoid b) => (a -> b) -> t a -> b
foldMapT ::
  (Traversable t, Monoid b) =>
  (a -> b)
  -> t a
  -> b
foldMapT f = getConst . traverse (Const . f)
  --error "todo: foldMapT"

-- | Let's refactor out the call to @traverse@ as an argument to @foldMapT@.
foldMapOf ::
  ((a -> Const r b) -> s -> Const r t)
  -> (a -> r)
  -> s
  -> r
foldMapOf tr f = getConst . tr (Const . f)
  --error "todo: foldMapOf"

-- | Here is @foldMapT@ again, passing @traverse@ to @foldMapOf@.
foldMapTAgain ::
  (Traversable t, Monoid b) =>
  (a -> b)
  -> t a
  -> b
foldMapTAgain = foldMapOf traverse
  --error "todo: foldMapTAgain"

-- | Let's create a type-alias for this type of function.
type Fold s t a b =
  forall r.
  Monoid r =>
  (a -> Const r b)
  -> s
  -> Const r t

-- | Let's write an inverse to @foldMapOf@ that does the @Const@ wrapping &
-- unwrapping.
folds ::
  ((a -> b) -> s -> t)
  -> (a -> Const b a)
  -> s
  -> Const t s
folds f g s =
  let g' = getConst . g
  in Const $ f g' s
  --error "todo: folds"

folded ::
  Foldable f =>
  Fold (f a) (f a) a a -- (a -> Const r a) -> (f a) -> Const r (f a)
folded g f =
  let
    g' = getConst . g
    r = foldMap g' f
  in Const r

  --error "todo: folded"

----

-- | @Get@ is like @Fold@, but without the @Monoid@ constraint.
type Get r s a =
  (a -> Const r a)
  -> s
  -> Const r s

get ::
  Get a s a  -- (a -> Const a a) -> s -> Const a s
  -> s
  -> a
get g s =
  let r = g Const s
  in getConst r



----

-- | Let's generalise @Identity@ and @Const r@ to any @Applicative@ instance.
type Traversal s t a b =
  forall f.
  Applicative f =>
  (a -> f b)
  -> s
  -> f t

-- | Traverse both sides of a pair.
both ::
  Traversal (a, a) (b, b) a b  -- forall f. Applicative f => (a -> f b) -> (a, a) -> f (b, b)
both k (f,s) =
  let f' = k f
      s' = k s
  in (,) <$> f' <*> s'


-- | Traverse the left side of @Either@.
traverseLeft ::
  Traversal (Either a x) (Either b x) a b -- forall f. Applicative f => (a -> f b) -> Either a x -> f Either b x
traverseLeft k (Left e) =
  let r = k e
  in Left <$> r
traverseLeft _ (Right x) = pure $ Right x



-- | Traverse the right side of @Either@.
traverseRight ::
  Traversal (Either x a) (Either x b) a b -- forall f. Applicative f => (a -> f b) -> Either x a -> f Either x b
traverseRight k (Right v)=
  let r = k v
  in Right <$> k v

traverseRight _ (Left x) = pure . Left $ x

type Traversal' a b =
  Traversal a a b b -- forall f . Applicative f => (b -> f b) -> a -> f a

----

-- | @Const r@ is @Applicative@, if @Monoid r@, however, without the @Monoid@
-- constraint (as in @Get@), the only shared abstraction between @Identity@ and
-- @Const r@ is @Functor@.
--
-- Consequently, we arrive at our lens derivation:
type Lens s t a b =
  forall f.
  Functor f =>
  (a -> f b)
  -> s
  -> f t

----

-- | A prism is a less specific type of traversal.
type Prism s t a b =
  forall p f.
  (Choice p, Applicative f) =>
  p a (f b)
  -> p s (f t)

_Left ::
  Prism (Either a x) (Either b x) a b -- forall p f . (Choice p, Applicative f) => p a (f b) -> p (Either a x) (f Either b x)
_Left ch =
  let r = left ch
      r' = dimap id k r
      k (Right v) = pure (Right v)
      k (Left  fe) = Left <$> fe 
  in r'
  

_Right ::
  Prism (Either x a) (Either x b) a b -- forall p f . (Choice p, Applicative f) => p a (f b) -> p (Either x a) (f Either x b)
_Right ch =
  let r = right ch
      r' = dimap id k r
      k (Right fx) = Right <$> fx
      k (Left e) = pure (Left e)
  in r'  
  

prism ::
  (b -> t)
  -> (s -> Either t a)
  -> Prism s t a b  -- forall p f . (Choice p, Applicative f) => p a (f b) -> p s (f t)
prism f g p =
  let   
    --p' = _Right p
    --r' = dimap g 
    g' s = either (error "???") (id) (g s)            
    r = dimap g' (f <$>) p
  in r


_Just ::
  Prism (Maybe a) (Maybe b) a b -- forall p f . (Choice p, Applicative f) => p a (f b) -> p (Maybe a) (f (Maybe b))
_Just = dimap m (Just <$>)
   where m (Just x) = x
         m Nothing  = error "???"


_Nothing ::
  Prism (Maybe a) (Maybe a) () () -- forall p f . (Choice p, Applicative f) => p () (f ()) -> p (Maybe a) (f (Maybe a))
_Nothing = dimap (const ()) (const Nothing <$>) 


setP ::
  Prism s t a b  --(Choice p, Applicative f) => p a (f b) -> p s (f t)
  -> s
  -> Either t a
setP p s = undefined

  --error "todo: setP"

getP ::
  Prism s t a b
  -> b
  -> t
getP _ _ =
  error "todo: getP"

type Prism' a b =
  Prism a a b b

----

-- |
--
-- >>> modify fstL (+1) (0 :: Int, "abc")
-- (1,"abc")
--
-- >>> modify sndL (+1) ("abc", 0 :: Int)
-- ("abc",1)
--
-- prop> let types = (x :: Int, y :: String) in modify fstL id (x, y) == (x, y)
--
-- prop> let types = (x :: Int, y :: String) in modify sndL id (x, y) == (x, y)
modify ::
  Lens s t a b
  -> (a -> b)
  -> s
  -> t
modify l k s = getIdentity $ l (Identity . k) s


-- | An alias for @modify@.
(%~) ::
  Lens s t a b
  -> (a -> b)
  -> s
  -> t
(%~) =
  modify

infixr 4 %~

-- |
--
-- >>> fstL .~ 1 $ (0 :: Int, "abc")
-- (1,"abc")
--
-- >>> sndL .~ 1 $ ("abc", 0 :: Int)
-- ("abc",1)
--
-- prop> let types = (x :: Int, y :: String) in set fstL (x, y) z == (fstL .~ z $ (x, y))
--
-- prop> let types = (x :: Int, y :: String) in set sndL (x, y) z == (sndL .~ z $ (x, y))
(.~) ::
  Lens s t a b
  -> b
  -> s
  -> t
(.~) l b s = getIdentity $ l (Identity . const b) s 


infixl 5 .~

-- |
--
-- >>> fmodify fstL (+) (5 :: Int, "abc") 8
-- (13,"abc")
--
-- >>> fmodify fstL (\n -> bool Nothing (Just (n * 2)) (even n)) (10, "abc")
-- Just (20,"abc")
--
-- >>> fmodify fstL (\n -> bool Nothing (Just (n * 2)) (even n)) (11, "abc")
-- Nothing
fmodify ::
  Functor f =>
  Lens s t a b
  -> (a -> f b)
  -> s
  -> f t 
fmodify l k s = l k s


-- |
--
-- >>> fstL |= Just 3 $ (7, "abc")
-- Just (3,"abc")
--
-- >>> (fstL |= (+1) $ (3, "abc")) 17
-- (18,"abc")
(|=) ::
  Functor f =>
  Lens s t a b
  -> f b
  -> s
  -> f t
(|=) l fb s = l (const fb) s


infixl 5 |=

-- |
--
-- >>> modify fstL (*10) (3, "abc")
-- (30,"abc")
fstL ::
  Lens (a, x) (b, x) a b
fstL k (x,y)= 
  let x' = k x
  in (\v -> (v,y)) <$> x'


-- |
--
-- >>> modify sndL (++ "def") (13, "abc")
-- (13,"abcdef")
sndL ::
  Lens (x, a) (x, b) a b
sndL k (x,y) =
  let y' = k y
  in (\v -> (x,v))<$> y'


-- |
--
-- To work on `Map k a`:
--   Map.lookup :: Ord k => k -> Map k a -> Maybe a
--   Map.insert :: Ord k => k -> a -> Map k a -> Map k a
--   Map.delete :: Ord k => k -> Map k a -> Map k a
--
-- >>> get (mapL 3) (Map.fromList (map (\c -> (ord c - 96, c)) ['a'..'d']))
-- Just 'c'
--
-- >>> get (mapL 33) (Map.fromList (map (\c -> (ord c - 96, c)) ['a'..'d']))
-- Nothing
--
-- >>> set (mapL 3) (Map.fromList (map (\c -> (ord c - 96, c)) ['a'..'d'])) (Just 'X')
-- fromList [(1,'a'),(2,'b'),(3,'X'),(4,'d')]
--
-- >>> set (mapL 33) (Map.fromList (map (\c -> (ord c - 96, c)) ['a'..'d'])) (Just 'X')
-- fromList [(1,'a'),(2,'b'),(3,'c'),(4,'d'),(33,'X')]
--
-- >>> set (mapL 3) (Map.fromList (map (\c -> (ord c - 96, c)) ['a'..'d'])) Nothing
-- fromList [(1,'a'),(2,'b'),(4,'d')]
--
-- >>> set (mapL 33) (Map.fromList (map (\c -> (ord c - 96, c)) ['a'..'d'])) Nothing
-- fromList [(1,'a'),(2,'b'),(3,'c'),(4,'d')]
mapL ::
  Ord k =>
  k
  -> Lens (Map k v) (Map k v) (Maybe v) (Maybe v) -- Functor f => (Maybe v -> f Maybe v) -> Map k v -> f (Map k v)
mapL k f m = maybe (Map.delete k m) (\v -> Map.insert k v m) <$> (f  $ Map.lookup k m)


-- |
--
-- To work on `Set a`:
--   Set.insert :: Ord a => a -> Set a -> Set a
--   Set.member :: Ord a => a -> Set a -> Bool
--   Set.delete :: Ord a => a -> Set a -> Set a
--
-- >>> get (setL 3) (Set.fromList [1..5])
-- True
--
-- >>> get (setL 33) (Set.fromList [1..5])
-- False
--
-- >>> set (setL 3) (Set.fromList [1..5]) True
-- fromList [1,2,3,4,5]
--
-- >>> set (setL 3) (Set.fromList [1..5]) False
-- fromList [1,2,4,5]
--
-- >>> set (setL 33) (Set.fromList [1..5]) True
-- fromList [1,2,3,4,5,33]
--
-- >>> set (setL 33) (Set.fromList [1..5]) False
-- fromList [1,2,3,4,5]
setL ::
  Ord k =>
  k
  -> Lens (Set.Set k) (Set.Set k) Bool Bool -- Functor f => (Bool -> f Bool) -> (Set.Set k) -> f (Set.Set k)
setL k f s =
  let v = f (Set.member k s)
      g True = Set.insert k s
      g False = Set.delete k s
  in g <$> v


-- |
--
-- >>> get (compose fstL sndL) ("abc", (7, "def"))
-- 7
--
-- >>> set (compose fstL sndL) ("abc", (7, "def")) 8
-- ("abc",(8,"def"))
compose ::
  Lens s t a b     -- Functor f => (a -> f b) -> s -> f t
  -> Lens q r s t  -- Functor f => (s -> f t) -> q -> f r
  -> Lens q r a b  -- Functor f => (a -> f b) -> q -> f r
compose l1 l2 k q =  l2 (l1 k) q


-- | An alias for @compose@.
(|.) ::
  Lens s t a b
  -> Lens q r s t
  -> Lens q r a b
(|.) =
  compose

infixr 9 |.

-- |
--
-- >>> get identity 3
-- 3
--
-- >>> set identity 3 4
-- 4
identity ::
  Lens a b a b  -- Functor f => (a -> f b) -> a -> f b
identity k a = k a

-- |
--
-- >>> get (product fstL sndL) (("abc", 3), (4, "def"))
-- ("abc","def")
--
-- >>> set (product fstL sndL) (("abc", 3), (4, "def")) ("ghi", "jkl")
-- (("ghi",3),(4,"jkl"))
product ::
  Lens s t a b                          -- Functor f => (a -> f b) -> s -> f t
  -> Lens q r c d                       -- Functor f => (c -> f d) -> q -> f r
  -> Lens (s, q) (t, r) (a, c) (b, d)   -- Functor f => ((a,c) -> f (b,d)) -> (s,q) -> f(t,r)
product l1 l2 k (s,q) =
  getAlongsideRight (l2 (\b2 -> AlongsideRight(
  getAlongsideLeft  (l1 (\b1 -> AlongsideLeft(
    k (b1, b2)
  )) s )
  )) q)


-- | An alias for @product@.
(***) ::
  Lens s t a b
  -> Lens q r c d
  -> Lens (s, q) (t, r) (a, c) (b, d)
(***) =
  product

infixr 3 ***

-- |
--
-- >>> get (choice fstL sndL) (Left ("abc", 7))
-- "abc"
--
-- >>> get (choice fstL sndL) (Right ("abc", 7))
-- 7
--
-- >>> set (choice fstL sndL) (Left ("abc", 7)) "def"
-- Left ("def",7)
--
-- >>> set (choice fstL sndL) (Right ("abc", 7)) 8
-- Right ("abc",8)
choice ::
  Lens s t a b                           -- Functor f => (a -> f b) -> s -> f t
  -> Lens q r a b                        -- Functor f => (a -> f b) -> q -> f r
  -> Lens (Either s q) (Either t r) a b  -- Functor f => (a -> f b) -> Either s q -> f Either t r
choice l1 l2 k = either (fmap Left . l1 k) (fmap Right . l2 k)  



-- | An alias for @choice@.
(|||) ::
  Lens s t a b
  -> Lens q r a b
  -> Lens (Either s q) (Either t r) a b
(|||) =
  choice

infixr 2 |||

----

type Lens' a b =
  Lens a a b b

cityL ::
  Lens' Locality String
cityL p (Locality c t y) =
  fmap (\c' -> Locality c' t y) (p c)

stateL ::
  Lens' Locality String
stateL p (Locality c t y) =
  fmap (\t' -> Locality c t' y) (p t)

countryL ::
  Lens' Locality String
countryL p (Locality c t y) =
  fmap (\y' -> Locality c t y') (p y)

streetL ::
  Lens' Address String
streetL p (Address t s l) =
  fmap (\t' -> Address t' s l) (p t)

suburbL ::
  Lens' Address String
suburbL p (Address t s l) =
  fmap (\s' -> Address t s' l) (p s)

localityL ::
  Lens' Address Locality
localityL p (Address t s l) =
  fmap (\l' -> Address t s l') (p l)

ageL ::
  Lens' Person Int
ageL p (Person a n d) =
  fmap (\a' -> Person a' n d) (p a)

nameL ::
  Lens' Person String
nameL p (Person a n d) =
  fmap (\n' -> Person a n' d) (p n)

addressL ::
  Lens' Person Address
addressL p (Person a n d) =
  fmap (\d' -> Person a n d') (p d)

intAndIntL ::
  Lens' (IntAnd a) Int
intAndIntL p (IntAnd n a) =
  fmap (\n' -> IntAnd n' a) (p n)

-- lens for polymorphic update
intAndL ::
  Lens (IntAnd a) (IntAnd b) a b
intAndL p (IntAnd n a) =
  fmap (\a' -> IntAnd n a') (p a)

-- |
--
-- >>> getSuburb fred
-- "Fredville"
--
-- >>> getSuburb mary
-- "Maryland"
getSuburb ::
  Person
  -> String
getSuburb = get $ suburbL |. addressL


-- |
--
-- >>> setStreet fred "Some Other St"
-- Person 24 "Fred" (Address "Some Other St" "Fredville" (Locality "Fredmania" "New South Fred" "Fredalia"))
--
-- >>> setStreet mary "Some Other St"
-- Person 28 "Mary" (Address "Some Other St" "Maryland" (Locality "Mary Mary" "Western Mary" "Maristan"))
setStreet ::
  Person
  -> String
  -> Person
setStreet = set $ streetL |. addressL

-- |
--
-- >>> getAgeAndCountry (fred, maryLocality)
-- (24,"Maristan")
--
-- >>> getAgeAndCountry (mary, fredLocality)
-- (28,"Fredalia")
getAgeAndCountry ::
  (Person, Locality)
  -> (Int, String)
getAgeAndCountry =  get (ageL *** countryL)
  --error "todo: getAgeAndCountry"

-- |
--
-- >>> setCityAndLocality (fred, maryAddress) ("Some Other City", fredLocality)
-- (Person 24 "Fred" (Address "15 Fred St" "Fredville" (Locality "Some Other City" "New South Fred" "Fredalia")),Address "83 Mary Ln" "Maryland" (Locality "Fredmania" "New South Fred" "Fredalia"))
--
-- >>> setCityAndLocality (mary, fredAddress) ("Some Other City", maryLocality)
-- (Person 28 "Mary" (Address "83 Mary Ln" "Maryland" (Locality "Some Other City" "Western Mary" "Maristan")),Address "15 Fred St" "Fredville" (Locality "Mary Mary" "Western Mary" "Maristan"))
setCityAndLocality ::
  (Person, Address) -> (String, Locality) -> (Person, Address)
setCityAndLocality = set $ cityL |. localityL |. addressL *** localityL
  --error "todo: setCityAndLocality"
  
-- |
--
-- >>> getSuburbOrCity (Left maryAddress)
-- "Maryland"
--
-- >>> getSuburbOrCity (Right fredLocality)
-- "Fredmania"
getSuburbOrCity ::
  Either Address Locality
  -> String
getSuburbOrCity = get (suburbL ||| cityL)
  

-- |
--
-- >>> setStreetOrState (Right maryLocality) "Some Other State"
-- Right (Locality "Mary Mary" "Some Other State" "Maristan")
--
-- >>> setStreetOrState (Left fred) "Some Other St"
-- Left (Person 24 "Fred" (Address "Some Other St" "Fredville" (Locality "Fredmania" "New South Fred" "Fredalia")))
setStreetOrState ::
  Either Person Locality
  -> String
  -> Either Person Locality
setStreetOrState = set $ (streetL |. addressL) ||| stateL
  

-- |
--
-- >>> modifyCityUppercase fred
-- Person 24 "Fred" (Address "15 Fred St" "Fredville" (Locality "FREDMANIA" "New South Fred" "Fredalia"))
--
-- >>> modifyCityUppercase mary
-- Person 28 "Mary" (Address "83 Mary Ln" "Maryland" (Locality "MARY MARY" "Western Mary" "Maristan"))
modifyCityUppercase ::
  Person
  -> Person
modifyCityUppercase =
  (cityL |. localityL |. addressL) %~ (toUpper <$>)
  

-- |
--
-- >>> modifyIntAndLengthEven (IntAnd 10 "abc")
-- IntAnd 10 False
--
-- >>> modifyIntAndLengthEven (IntAnd 10 "abcd")
-- IntAnd 10 True
modifyIntAndLengthEven ::
  IntAnd [a]
  -> IntAnd Bool
modifyIntAndLengthEven =
  error "todo: modifyIntAndLengthEven"

----

-- |
--
-- >>> over traverseLocality (map toUpper) (Locality "abc" "def" "ghi")
-- Locality "ABC" "DEF" "GHI"
traverseLocality ::
  Traversal' Locality String
traverseLocality =
  error "todo: traverseLocality"

-- |
--
-- >>> over intOrIntP (*10) (IntOrIs 3)
-- IntOrIs 30
--
-- >>> over intOrIntP (*10) (IntOrIsNot "abc")
-- IntOrIsNot "abc"
intOrIntP ::
  Prism' (IntOr a) Int
intOrIntP =
  error "todo: intOrIntP"

intOrP ::
  Prism (IntOr a) (IntOr b) a b
intOrP =
  error "todo: intOrP"

-- |
--
-- >> intOrLengthEven (IntOrIsNot "abc")
-- IntOrIsNot False
--
-- >>> intOrLengthEven (IntOrIsNot "abcd")
-- IntOrIsNot True
--
-- >>> intOrLengthEven (IntOrIs 10)
-- IntOrIs 10
intOrLengthEven ::
  IntOr [a]
  -> IntOr Bool
intOrLengthEven =
  error "todo: intOrLengthEven"
