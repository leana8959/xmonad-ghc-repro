module MyXmonad where

import XMonad
import XMonad.Util.EZConfig

entryPoint :: IO ()
entryPoint =
    xmonad $ def
        { startupHook = do
                xmessage "You are indeed running the custom configuration!"
        }
