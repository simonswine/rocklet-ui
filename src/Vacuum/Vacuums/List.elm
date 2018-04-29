module Vacuum.Vacuums.List exposing (..)

import Html exposing (..)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Models exposing (Vacuum)
import Vacuum.Page
import RemoteData exposing (WebData)
import Material.Layout exposing (link, href)
import Material.Table as Table
import Material.Icon as Icon


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
            vacuums |> List.sortBy (\x -> x.metadata.name) |> List.sortBy (\x -> x.metadata.name) |> list

        RemoteData.Failure error ->
            text (toString error)


list : List Vacuum -> Html Msg
list vacuums =
    Table.table []
        [ Table.thead []
            [ Table.tr []
                [ Table.th [] [ text "Namespace" ]
                , Table.th [] [ text "Name" ]
                , Table.th [] [ text "State" ]
                , Table.th [ Table.numeric ] [ text "Battery Level" ]
                , Table.th [ Table.numeric ] [ text "Fan Speed" ]
                , Table.th [] []
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
        , Table.td [ Table.numeric ] [ vacuum.status.batteryLevel |> toString |> text ]
        , Table.td [ Table.numeric ] [ vacuum.status.fanPower |> toString |> text ]
        , Table.td [] [ link [ href ("#vacuum/" ++ vacuum.metadata.namespace ++ "/" ++ vacuum.metadata.name) ] [ Icon.i "map" ] ]
        , Table.td []
            []
        ]
