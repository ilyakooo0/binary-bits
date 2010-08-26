module Main where

import Data.Binary ( encode )
import Data.Binary.Get ( runGet )
import Data.Binary.Put ( runPut )

import Data.Bits
import Data.Word
import System.Random

import BitsGet
import BitsPut

import Test.QuickCheck

main = do
  quickCheck prop_Bools
  quickCheck prop_SimpleCase
  quickCheck prop_Word8_putget
  quickCheck prop_Word8_putget_list
  quickCheck prop_Word16be_putget 
  quickCheck prop_Word16be_putget_list_simple
  quickCheck prop_Word16be_putget_list

  -- these tests use the R structure
  --
  -- quickCheck prop_Word32_from_2_Word16
  -- quickCheck prop_Word32_from_Word8_and_Word16
 
prop_Word8_putget :: Word8 -> Property
prop_Word8_putget w = property $
  -- write all words with as many bits as it's required
  let p = putWord8 (bitreq w) w
      g = getWord8 (bitreq w)
      lbs = runPut (runBitPut p)
      w' = runGet (runBitGetSimple g) lbs
  in w == w'

prop_Word16be_putget :: Word16 -> Property
prop_Word16be_putget w = property $
  -- write all words with as many bits as it's required
  let p = putWord16be (bitreq w) w
      g = getWord16be (bitreq w)
      lbs = runPut (runBitPut p)
      w' = runGet (runBitGetSimple g) lbs
  in w == w'

prop_Word8_putget_list :: [Word8] -> Property
prop_Word8_putget_list ws = property $
  -- write all word8s with as many bits as it's required
  let p = mapM_ (\v -> putWord8 (bitreq v) v) ws
      g = mapM getWord8 bitlist
      lbs = runPut (runBitPut p)
      Right ws' = runGet (runBitGet g) lbs
  in ws == ws'
  where
    bitlist = map bitreq ws

prop_Word16be_putget_list_simple :: [Word16] -> Property
prop_Word16be_putget_list_simple ws = property $
  let p = mapM_ (\v -> putWord16be 16 v) ws
      g = mapM (const (getWord16be 16)) ws
      lbs = runPut (runBitPut p)
      ws' = runGet (runBitGetSimple g) lbs
  in ws == ws'
  where
    bitlist = map bitreq ws

prop_Word16be_putget_list :: [Word16] -> Property
prop_Word16be_putget_list ws = property $
  -- write all words with as many bits as it's required
  let p = mapM_ (\v -> putWord16be (bitreq v) v) ws
      g = mapM getWord16be bitlist
      lbs = runPut (runBitPut p)
      ws' = runGet (runBitGetSimple g) lbs
  in ws == ws'
  where
    bitlist = map bitreq ws

-- number of bits required to write 'v'
bitreq :: (Num b, Bits a, Ord a) => a -> b
bitreq v = fromIntegral . head $ [ req | (req, top) <- bittable, v <= top ]

bittable :: Bits a => [(Integer, a)]
bittable = [ (fromIntegral x, (1 `shiftL` x) - 1) | x <- [1..64] ]

prop_Bools :: [Bool] -> Property
prop_Bools bs = property $
  let p = sequence . replicate (length bs) $ getBool
      Right bs' = runGet (runBitGet p) lbs
  in bs == bs'
  where lbs = runPut $ runBitPut (mapM_ putBool bs)

prop_SimpleCase :: Bool -> Word16 -> Property
prop_SimpleCase b w = w < 0x8000 ==>
  let p = do putBool b
             putWord16be 15 w
      g = do v <- getBool
             case v of
              True -> getWord16be 15
              False -> do
                msb <- getWord8 7
                lsb <- getWord8 8
                return ((fromIntegral msb `shiftL` 8) .|. fromIntegral lsb)
      lbs = runPut (runBitPut p)
      w' = runGet (runBitGetSimple g) lbs
  in w == w'
  where


{-
prop_Word32_from_Word8_and_Word16 :: Word8 -> Word16 -> Property
prop_Word32_from_Word8_and_Word16 w8 w16 = property $
  let p = RWord32be 24
      w' = runGet (get p) lbs
  in w0 == w'
  where
    lbs = runPut (putWord8 w8 >> putWord16be w16)
    w0 = ((fromIntegral w8) `shiftL` 16) .|. fromIntegral w16

prop_Word32_from_2_Word16 :: Word16 -> Word16 -> Property
prop_Word32_from_2_Word16 w1 w2 = property $
  let p = RWord32be 32
      w' = runGet (get p) lbs
  in w0 == w'
  where
    lbs = encode w0
    w0 = ((fromIntegral w1) `shiftL` 16) .|. fromIntegral w2
-}

instance Arbitrary Word8 where
    arbitrary       = choose (minBound, maxBound)
    shrink 0        = []
    shrink n        = [ n - 1 ]

instance Arbitrary Word16 where
    arbitrary       = choose (minBound, maxBound)
    shrink 0        = []
    shrink n        = [ n - 10000, n - 1000, n - 100, n - 1 ]

instance Arbitrary Word32 where
    arbitrary       = choose (minBound, maxBound)

instance Arbitrary Word64 where
    arbitrary       = choose (minBound, maxBound)


integralRandomR :: (Integral a, RandomGen g) => (a,a) -> g -> (a,g)
integralRandomR  (a,b) g = case randomR (fromIntegral a :: Integer,
                                         fromIntegral b :: Integer) g of
                            (x,g) -> (fromIntegral x, g)

instance Random Word where
  randomR = integralRandomR
  random = randomR (minBound,maxBound)

instance Random Word8 where
  randomR = integralRandomR
  random = randomR (minBound,maxBound)

instance Random Word16 where
  randomR = integralRandomR
  random = randomR (minBound,maxBound)

instance Random Word32 where
  randomR = integralRandomR
  random = randomR (minBound,maxBound)

instance Random Word64 where
  randomR = integralRandomR
  random = randomR (minBound,maxBound)
