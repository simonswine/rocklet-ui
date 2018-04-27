module Vacuum.Vacuums.List exposing (..)

import Html exposing (..)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Models exposing (Vacuum)
import Vacuum.Page
import RemoteData exposing (WebData)
import Material.Table as Table


view : WebData (List Vacuum) -> Html Msg
view response =
    Vacuum.Page.body
        "Vacuums"
        (maybeList response)


maybeList : WebData (List Vacuum) -> Html Msg
maybeList response =
    case response of
        RemoteData.NotAsked ->
            text ""

        RemoteData.Loading ->
            text "Loading..."

        RemoteData.Success vacuums ->
            list vacuums

        RemoteData.Failure error ->
            text (toString error)


list : List Vacuum -> Html Msg
list vacuums =
    Table.table []
        [ Table.thead []
            [ Table.tr []
                [ Table.th [ Table.numeric ] [ text "Namespace" ]
                , Table.th [ Table.numeric ] [ text "Name" ]
                , Table.th [ Table.numeric ] [ text "State" ]
                ]
            ]
        , Table.tbody []
            (List.map vacuumRow vacuums)
        ]


vacuumRow : Vacuum -> Html Msg
vacuumRow vacuum =
    Table.tr []
        [ Table.td [] [ text vacuum.metadata.namespace ]
        , Table.td [] [ text vacuum.metadata.name ]
        , Table.td [] [ text vacuum.status.state ]
        , Table.td []
            []
        ]
