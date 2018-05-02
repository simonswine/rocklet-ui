module Vacuum.Update exposing (..)

import Vacuum.Commands exposing (fetchVacuums, fetchVacuum, fetchCleanings, fetchCleaning)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Models exposing (Model)
import Vacuum.Routing exposing (parseLocation)
import Navigation exposing (Location)
import RemoteData
import Material
import Array
import Maybe


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Vacuum.Msgs.Mdl msg_ ->
            Material.update Vacuum.Msgs.Mdl msg_ model

        Vacuum.Msgs.OnFetchVacuums response ->
            ( { model | vacuums = response }, Cmd.none )

        Vacuum.Msgs.OnFetchVacuum response ->
            ( { model | vacuum = response, goto = Nothing }, Cmd.none )

        Vacuum.Msgs.OnFetchCleanings response ->
            ( { model | cleanings = response }, Cmd.none )

        Vacuum.Msgs.OnFetchCleaning response ->
            ( { model | cleaning = response, goto = Nothing }, Cmd.none )

        Vacuum.Msgs.OnLocationChange location ->
            handleLocationChange location ( model, Cmd.none )

        Vacuum.Msgs.NewNotify key ->
            handleNotify key ( model, Cmd.none )

        Vacuum.Msgs.MapZoomSliderMsg factor ->
            ( { model | mapZoom = factor }, Cmd.none )

        Vacuum.Msgs.SendCommand _ ->
            ( model, Cmd.none )

        Vacuum.Msgs.GoToPosition pos ->
            case model.route of
                Vacuum.Models.VacuumRoute namespace name ->
                    ( { model | goto = Just pos }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


handleNotify : String -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
handleNotify key ( model, cmd ) =
    let
        parts =
            String.split "/" key |> Array.fromList
    in
        case ( Array.get 0 parts, Array.get 1 parts, Array.get 2 parts, model.route ) of
            ( Just "vacuums", _, _, Vacuum.Models.VacuumsRoute ) ->
                ( model, Cmd.batch ([ fetchVacuums, cmd ]) )

            ( Just "vacuums", Just namespace, Just name, Vacuum.Models.VacuumRoute rnamespace rname ) ->
                if rnamespace == namespace && rname == name then
                    ( model, Cmd.batch ([ fetchVacuum namespace name, cmd ]) )
                else
                    ( model, cmd )

            ( Just "cleanings", _, _, Vacuum.Models.CleaningsRoute ) ->
                ( model, Cmd.batch ([ fetchCleanings, cmd ]) )

            ( Just "cleanings", Just namespace, Just name, Vacuum.Models.CleaningRoute rnamespace rname ) ->
                if rnamespace == namespace && rname == name then
                    ( model, Cmd.batch ([ fetchCleaning namespace name, cmd ]) )
                else
                    ( model, cmd )

            _ ->
                ( model, cmd )


handleLocationChange : Location -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
handleLocationChange location ( model, cmd ) =
    let
        newRoute =
            parseLocation location
    in
        case newRoute of
            Vacuum.Models.VacuumsRoute ->
                ( { model | route = newRoute, location = location }, Cmd.batch ([ fetchVacuums, cmd ]) )

            Vacuum.Models.VacuumRoute namespace name ->
                ( { model | route = newRoute, location = location }, Cmd.batch ([ (fetchVacuum namespace name), cmd ]) )

            Vacuum.Models.CleaningsRoute ->
                ( { model | route = newRoute, location = location }, Cmd.batch ([ fetchCleanings, cmd ]) )

            Vacuum.Models.CleaningRoute namespace name ->
                ( { model | route = newRoute, location = location }, Cmd.batch ([ (fetchCleaning namespace name), cmd ]) )

            _ ->
                ( { model | route = newRoute, location = location }, cmd )
