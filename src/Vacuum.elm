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
            ( initialModel location currentRoute, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen (webSocketUrl model.location "/ws/notify") Vacuum.Msgs.NewNotify


webSocketUrl : Location -> String -> String
webSocketUrl location path =
    case ( location.protocol, location.host ) of
        -- Local development proxy doesn't support Websockets
        ( _, "localhost:3000" ) ->
            "ws://localhost:8812" ++ path

        ( _, "127.0.0.1:3000" ) ->
            "ws://127.0.0.1:8812" ++ path

        -- TLS should use wss
        ( "https:", _ ) ->
            "wss://" ++ location.host ++ path

        -- Non-TLS should use ws
        _ ->
            "ws://" ++ location.host ++ path


main : Program Never Model Msg
main =
    Navigation.program Vacuum.Msgs.OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
