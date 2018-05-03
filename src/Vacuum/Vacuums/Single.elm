module Vacuum.Vacuums.Single exposing (..)

import Html exposing (Html, text)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Models exposing (Vacuum, Path, Map, Position, Model)
import Vacuum.Page
import Vacuum.Map
import RemoteData exposing (WebData)
import Material.Options exposing (css)
import Material.Grid exposing (grid, cell, noSpacing, offset, size, Device(..))
import Material.Button as Button
import Material.Options as Options


view : Model -> Html Msg
view model =
    Vacuum.Page.body
        "Vacuum"
        (maybeVacuum model)


maybeVacuum : Model -> Html Msg
maybeVacuum model =
    case model.vacuum of
        RemoteData.NotAsked ->
            text ""

        RemoteData.Loading ->
            text "Loading..."

        RemoteData.Success vacuum ->
            single model vacuum

        RemoteData.Failure error ->
            text (toString error)


single : Model -> Vacuum -> Html Msg
single model vacuum =
    Material.Options.div
        []
        [ Material.Options.div
            []
            [ Html.h4
                []
                [ text (vacuum.metadata.namespace ++ "/" ++ vacuum.metadata.name) ]
            , grid [ noSpacing ]
                ([ Just
                    (cell
                        [ size All 3 ]
                        [ Button.render Vacuum.Msgs.Mdl
                            [ 0 ]
                            model.mdl
                            [ Button.raised
                            , Button.ripple
                            , Options.css "margin" "5px"
                            , Options.css "height" "40px"
                            , Options.onClick (Vacuum.Msgs.SendCommand "app_start")
                            ]
                            [ text "Start" ]
                        ]
                    )
                 , Just
                    (cell
                        [ size All 3 ]
                        [ Button.render Vacuum.Msgs.Mdl
                            [ 1 ]
                            model.mdl
                            [ Button.raised
                            , Button.ripple
                            , Options.css "margin" "5px"
                            , Options.css "height" "40px"
                            , Options.onClick (Vacuum.Msgs.SendCommand "app_stop")
                            ]
                            [ text "Stop" ]
                        ]
                    )
                 , Just
                    (cell
                        [ size All 3 ]
                        [ Button.render Vacuum.Msgs.Mdl
                            [ 2 ]
                            model.mdl
                            [ Button.raised
                            , Button.ripple
                            , Options.css "margin" "5px"
                            , Options.css "height" "40px"
                            , Options.onClick (Vacuum.Msgs.SendCommand "app_pause")
                            ]
                            [ text "Pause" ]
                        ]
                    )
                 , Just
                    (cell
                        [ size All 3 ]
                        [ Button.render Vacuum.Msgs.Mdl
                            [ 3 ]
                            model.mdl
                            [ Button.raised
                            , Button.ripple
                            , Options.css "margin" "5px"
                            , Options.css "height" "40px"
                            , Options.onClick (Vacuum.Msgs.SendCommand "app_charge")
                            ]
                            [ text "Dock" ]
                        ]
                    )
                 , (case vacuum.status.map of
                        Just map ->
                            Just
                                (cell
                                    [ size All 12
                                    , Options.css "margin-top" "20px"
                                    ]
                                    (Vacuum.Map.view map model.mapZoom vacuum.status.path vacuum.status.charger model.goto)
                                )

                        _ ->
                            Nothing
                   )
                 ]
                    |> List.filterMap identity
                )
            ]
        ]
