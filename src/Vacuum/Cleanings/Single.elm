module Vacuum.Cleanings.Single exposing (..)

import Html exposing (Html, text)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Models exposing (Cleaning, Path)
import Vacuum.Page
import Vacuum.Map
import RemoteData exposing (WebData)
import Material.Options exposing (css)
import Material.Grid exposing (grid, cell, noSpacing)


view : WebData Cleaning -> Float -> Html Msg
view response zoom =
    Vacuum.Page.body
        "Cleaning"
        (maybeCleaning response zoom)


maybeCleaning : WebData Cleaning -> Float -> Html Msg
maybeCleaning response zoom =
    case response of
        RemoteData.NotAsked ->
            text ""

        RemoteData.Loading ->
            text "Loading..."

        RemoteData.Success cleaning ->
            case cleaning.status.map of
                Just map ->
                    single cleaning map zoom

                Nothing ->
                    text "Cleaning does not contain map"

        RemoteData.Failure error ->
            text (toString error)


single : Cleaning -> Vacuum.Models.Map -> Float -> Html Msg
single cleaning map scale =
    Material.Options.div
        []
        [ Material.Options.div
            []
            [ Html.h4
                []
                [ text (cleaning.metadata.namespace ++ "/" ++ cleaning.metadata.name) ]
            , grid [ noSpacing ]
                [ cell []
                    (Vacuum.Map.view map scale cleaning.status.path cleaning.status.charger Nothing)
                ]
            ]
        ]
