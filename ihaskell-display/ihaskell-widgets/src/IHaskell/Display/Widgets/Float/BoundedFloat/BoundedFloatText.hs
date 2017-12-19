{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeSynonymInstances #-}

module IHaskell.Display.Widgets.Float.BoundedFloat.BoundedFloatText (
-- * The BoundedFloatText
-- Widget
BoundedFloatText, 
                  -- * Constructor
                  mkBoundedFloatText) where

-- To keep `cabal repl` happy when running from the ihaskell repo
import           Prelude

import           Data.Aeson
import qualified Data.HashMap.Strict as HM
import           Data.IORef (newIORef)
import qualified Data.Scientific as Sci
import           Data.Text (Text)

import           IHaskell.Display
import           IHaskell.Eval.Widgets
import           IHaskell.IPython.Message.UUID as U

import           IHaskell.Display.Widgets.Types
import           IHaskell.Display.Widgets.Common

-- | 'BoundedFloatText' represents an BoundedFloatText widget from IPython.html.widgets.
type BoundedFloatText = IPythonWidget BoundedFloatTextType

-- | Create a new widget
mkBoundedFloatText :: IO BoundedFloatText
mkBoundedFloatText = do
  -- Default properties, with a random uuid
  uuid <- U.random

  let widgetState = WidgetState $ defaultBoundedFloatWidget "FloatTextView" "FloatTextModel"

  stateIO <- newIORef widgetState

  let widget = IPythonWidget uuid stateIO

  -- Open a comm for this widget, and store it in the kernel state
  widgetSendOpen widget $ toJSON widgetState

  -- Return the widget
  return widget

instance IHaskellDisplay BoundedFloatText where
  display b = do
    widgetSendView b
    return $ Display []

instance IHaskellWidget BoundedFloatText where
  getCommUUID = uuid
  comm widget (Object dict1) _ = do
    let key1 = "sync_data" :: Text
        key2 = "value" :: Text
        Just (Object dict2) = HM.lookup key1 dict1
        Just (Number value) = HM.lookup key2 dict2
    setField' widget FloatValue (Sci.toRealFloat value)
    triggerChange widget
