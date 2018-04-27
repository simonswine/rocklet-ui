module Vacuum.Update exposing (..)

import Vacuum.Commands exposing (fetchVacuums, fetchCleanings, fetchCleaning)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Models exposing (Model)
import Vacuum.Routing exposing (parseLocation)
import Navigation exposing (Location)
import Material


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Vacuum.Msgs.Mdl msg_ ->
            Material.update Vacuum.Msgs.Mdl msg_ model

        Vacuum.Msgs.OnFetchVacuums response ->
            ( { model | vacuums = response }, Cmd.none )

        Vacuum.Msgs.OnFetchVacuum response ->
            ( { model | vacuum = response }, Cmd.none )

        Vacuum.Msgs.OnFetchCleanings response ->
            ( { model | cleanings = response }, Cmd.none )

        Vacuum.Msgs.OnFetchCleaning response ->
            ( { model | cleaning = response }, Cmd.none )

        Vacuum.Msgs.OnLocationChange location ->
            handleLocationChange location ( model, Cmd.none )

        Vacuum.Msgs.NewNotify key ->
            handleNotify key ( model, Cmd.none )


handleNotify : String -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
handleNotify key ( model, cmd ) =
    case key of
        "vacuums" ->
            ( model, Cmd.batch ([ fetchVacuums, cmd ]) )

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
                ( { model | route = newRoute }, Cmd.batch ([ fetchVacuums, cmd ]) )

            Vacuum.Models.CleaningsRoute ->
                ( { model | route = newRoute }, Cmd.batch ([ fetchCleanings, cmd ]) )

            Vacuum.Models.CleaningRoute namespace name ->
                ( { model | route = newRoute }, Cmd.batch ([ (fetchCleaning namespace name), cmd ]) )

            _ ->
                ( { model | route = newRoute }, cmd )
