module Vacuum.Models exposing (..)

import RemoteData exposing (WebData)
import Material


type alias Metadata =
    { namespace : String
    , name : String
    }


type alias Vacuum =
    { metadata : Metadata
    , status : VacuumStatus
    }


type alias VacuumStatus =
    { state : String
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
    }


type alias Model =
    { vacuums : WebData (List Vacuum)
    , vacuum : WebData Vacuum
    , cleanings : WebData (List Cleaning)
    , cleaning : WebData Cleaning
    , route : Route
    , mdl : Material.Model
    }


initialModel : Route -> Model
initialModel route =
    { vacuums = RemoteData.Loading
    , vacuum = RemoteData.Loading
    , cleanings = RemoteData.Loading
    , cleaning = RemoteData.Loading
    , route = route
    , mdl = Material.model
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
    | VacuumRoute VacuumId
    | CleaningsRoute --- TODO: reenable namespacing by vacuum VacuumId
    | CleaningRoute Namespace Name
