module Vacuum exposing (..)

import Vacuum.Commands exposing (fetchVacuums)
import Vacuum.Models exposing (Model, initialModel)
import Vacuum.Msgs exposing (Msg)
import Navigation exposing (Location)
import Vacuum.Routing
import Vacuum.Update exposing (update, handleLocationChange)
import Vacuum.View exposing (view)
import WebSocket


init : Location -> ( Model, Cmd Msg )
init location =
    let
        currentRoute =
            Vacuum.Routing.parseLocation location
    in
        handleLocationChange location
            ( initialModel currentRoute, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen "ws://localhost:8812/ws/notify" Vacuum.Msgs.NewNotify


main : Program Never Model Msg
main =
    Navigation.program Vacuum.Msgs.OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
