module Vacuum.Msgs exposing (..)

import Vacuum.Models exposing (Vacuum, Cleaning, Position)
import Navigation exposing (Location)
import RemoteData exposing (WebData)
import Material


type Msg
    = Mdl (Material.Msg Msg)
    | OnFetchVacuums (WebData (List Vacuum))
    | OnFetchCleanings (WebData (List Cleaning))
    | OnFetchVacuum (WebData Vacuum)
    | OnFetchCleaning (WebData Cleaning)
    | OnLocationChange Location
    | NewNotify String
    | MapZoomSliderMsg Float
    | GoToPosition Position
    | SendCommand String
    | SendCommandStatus (WebData String)
