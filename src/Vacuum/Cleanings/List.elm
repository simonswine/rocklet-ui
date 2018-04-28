module Vacuum.Cleanings.List exposing (..)

import Html exposing (..)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Models exposing (Cleaning)
import Vacuum.Page
import RemoteData exposing (WebData)
import Material.Layout exposing (link, href)
import Material.Table as Table
import Material.Icon as Icon


view : WebData (List Cleaning) -> Html Msg
view response =
    Vacuum.Page.body
        "Cleanings"
        (maybeList response)


maybeList : WebData (List Cleaning) -> Html Msg
maybeList response =
    case response of
        RemoteData.NotAsked ->
            text ""

        RemoteData.Loading ->
            text "Loading..."

        RemoteData.Success cleanings ->
            cleanings |> List.sortBy (\x -> x.metadata.name) |> List.sortBy (\x -> x.metadata.name) |> list

        RemoteData.Failure error ->
            text (toString error)


list : List Cleaning -> Html Msg
list cleanings =
    Table.table []
        [ Table.thead []
            [ Table.tr []
                [ Table.th [] [ text "Namespace" ]
                , Table.th [] [ text "Name" ]
                , Table.th [ Table.numeric ] [ text "Complete" ]
                , Table.th [ Table.numeric ] [ text "Area" ]
                , Table.th [ Table.numeric ] [ text "Duration" ]
                , Table.th [] []
                ]
            ]
        , Table.tbody []
            (List.map cleaningRow cleanings)
        ]


cleaningRow : Cleaning -> Html Msg
cleaningRow cleaning =
    tr []
        [ td [] [ text cleaning.metadata.namespace ]
        , td [] [ text cleaning.metadata.name ]
        , td [] [ text (toString cleaning.status.complete) ]
        , td [] [ ((toFloat (cleaning.status.area) / 1000.0 / 1000.0) |> toString) ++ "m²" |> text ]
        , td [] [ text cleaning.status.duration ]
        , td [] [ link [ href ("#cleaning/" ++ cleaning.metadata.namespace ++ "/" ++ cleaning.metadata.name) ] [ Icon.i "map" ] ]
        ]
