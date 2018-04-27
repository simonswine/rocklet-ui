module Vacuum.Cleanings.Single exposing (..)

import Html exposing (..)
import Html.Attributes exposing (src)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Models exposing (Cleaning)
import Vacuum.Page
import Vacuum.Commands exposing (fetchCleaningUrl)
import RemoteData exposing (WebData)
import Material.Options exposing (css)
import Material.Grid exposing (grid, cell, noSpacing)


view : WebData Cleaning -> Html Msg
view response =
    Vacuum.Page.body
        "Cleaning"
        (maybeCleaning response)


maybeCleaning : WebData Cleaning -> Html Msg
maybeCleaning response =
    case response of
        RemoteData.NotAsked ->
            text ""

        RemoteData.Loading ->
            text "Loading..."

        RemoteData.Success cleanings ->
            single cleanings

        RemoteData.Failure error ->
            text (toString error)


single : Cleaning -> Html Msg
single cleaning =
    Material.Options.div
        []
        [ Material.Options.div
            []
            [ Html.h4
                []
                [ text (cleaning.metadata.namespace ++ "/" ++ cleaning.metadata.name) ]
            , grid [ noSpacing ]
                [ cell []
                    [ text "content"
                    , img
                        [ src ((fetchCleaningUrl cleaning.metadata.namespace cleaning.metadata.name) ++ "/map") ]
                        []
                    ]
                ]
            ]
        ]
