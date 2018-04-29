module Vacuum.Vacuums.Single exposing (..)

import Html exposing (Html, text)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Models exposing (Vacuum, Path)
import Vacuum.Page
import Vacuum.Map
import RemoteData exposing (WebData)
import Material.Options exposing (css)
import Material.Grid exposing (grid, cell, noSpacing)


view : WebData Vacuum -> Float -> Html Msg
view response zoom =
    Vacuum.Page.body
        "Vacuum"
        (maybeVacuum response zoom)


maybeVacuum : WebData Vacuum -> Float -> Html Msg
maybeVacuum response zoom =
    case response of
        RemoteData.NotAsked ->
            text ""

        RemoteData.Loading ->
            text "Loading..."

        RemoteData.Success vacuum ->
            case vacuum.status.map of
                Just map ->
                    single vacuum map zoom

                Nothing ->
                    text "Vacuum does not contain map"

        RemoteData.Failure error ->
            text (toString error)


single : Vacuum -> Vacuum.Models.Map -> Float -> Html Msg
single vacuum map scale =
    Material.Options.div
        []
        [ Material.Options.div
            []
            [ Html.h4
                []
                [ text (vacuum.metadata.namespace ++ "/" ++ vacuum.metadata.name) ]
            , grid [ noSpacing ]
                [ cell []
                    (Vacuum.Map.view map scale vacuum.status.path vacuum.status.charger)
                ]
            ]
        ]
