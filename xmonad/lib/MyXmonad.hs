module MyXmonad where

import XMonad
import XMonad.Util.EZConfig

entryPoint :: IO ()
entryPoint =
    xmonad $
        def
        `additionalKeys` keybinds

keybinds :: [((KeyMask, KeySym), X ())]
keybinds =
    [ ((mod4Mask, xK_c), xmessage "You are indeed running the custom configuration!")
    ]
