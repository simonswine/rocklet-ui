module Vacuum.Models exposing (..)

import RemoteData exposing (WebData)
import Navigation exposing (Location)
import Material


type alias Metadata =
    { namespace : String
    , name : String
    }


type alias Map =
    { left : Int
    , top : Int
    , width : Int
    , height : Int
    , data : String
    }


type alias Vacuum =
    { metadata : Metadata
    , status : VacuumStatus
    }


type alias Path =
    List Position


type alias Position =
    { x : Float
    , y : Float
    }


type alias VacuumStatus =
    { state : String
    , mac : String
    , duration : String
    , area : Int
    , batteryLevel : Int
    , fanPower : Int
    , errorCode : Int
    , doNotDisturb : Bool
    , map : Maybe Map
    , path : Path
    , charger : Maybe Position
    }


type alias Cleaning =
    { metadata : Metadata
    , status : CleaningStatus
    }


type alias CleaningStatus =
    { area : Int
    , code : Int
    , complete : Bool
    , duration : String
    , path : Path
    , map : Maybe Map
    , charger : Maybe Position
    , beginTime : Maybe String
    , endTime : Maybe String
    }


type alias Model =
    { vacuums : WebData (List Vacuum)
    , vacuum : WebData Vacuum
    , cleanings : WebData (List Cleaning)
    , cleaning : WebData Cleaning
    , route : Route
    , location : Location
    , mdl : Material.Model
    , mapZoom : Float
    , goto : Maybe Position
    }


initialModel : Location -> Route -> Model
initialModel location route =
    { vacuums = RemoteData.Loading
    , vacuum = RemoteData.Loading
    , cleanings = RemoteData.Loading
    , cleaning = RemoteData.Loading
    , route = route
    , location = location
    , mdl = Material.model
    , mapZoom = 2.0
    , goto = Nothing
    }


type alias VacuumId =
    String


type alias Namespace =
    String


type alias Name =
    String


type Route
    = HomeRoute
    | NotFoundRoute
    | VacuumsRoute
    | VacuumRoute Namespace Name
    | CleaningsRoute --- TODO: reenable namespacing by vacuum VacuumId
    | CleaningRoute Namespace Name
