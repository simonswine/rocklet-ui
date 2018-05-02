module Vacuum.View exposing (..)

import Html exposing (Html, div, text)
import Vacuum.Models exposing (Model, VacuumId)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Vacuums.List
import Vacuum.Vacuums.Single
import Vacuum.Cleanings.List
import Vacuum.Cleanings.Single
import Vacuum.Page


-- material design lite

import Material.Layout
import Material.Options exposing (css)
import Material.Icon as Icon


header : Model -> List (Html Msg)
header model =
    [ Material.Layout.row
        []
        [ Material.Layout.title []
            [ text
                "Vacuum on Kubernetes"
            ]
        , Material.Layout.link
            [ Material.Layout.href "#vacuums" ]
            [ Icon.i "android"
            , Material.Options.span [ css "padding-left" "4px" ]
                [ text "Vacuums"
                ]
            ]
        , Material.Layout.link
            [ Material.Layout.href "#cleanings" ]
            [ Icon.i "polymer"
            , Material.Options.span [ css "padding-left" "4px" ]
                [ text "Cleanings"
                ]
            ]
        , Material.Layout.spacer
        , Material.Layout.navigation []
            [ Material.Layout.link
                [ Material.Layout.href "https://github.com/simonswine/rocklet-ui" ]
                [ Html.span [] [ text "github" ] ]
            , Material.Layout.link
                [ Material.Layout.href "https://twitter.com/simonswine" ]
                [ text "twitter" ]
            ]
        ]
    ]


view : Model -> Html Msg
view model =
    Material.Layout.render Vacuum.Msgs.Mdl
        model.mdl
        [ Material.Layout.fixedHeader
        ]
        { header = (header model)
        , drawer = []
        , tabs = ( [], [] )
        , main = [ page model ]
        }


page : Model -> Html Msg
page model =
    case model.route of
        Vacuum.Models.VacuumsRoute ->
            Vacuum.Vacuums.List.view model.vacuums

        Vacuum.Models.VacuumRoute _ _ ->
            Vacuum.Vacuums.Single.view model

        Vacuum.Models.CleaningsRoute ->
            Vacuum.Cleanings.List.view model.cleanings

        Vacuum.Models.CleaningRoute _ _ ->
            Vacuum.Cleanings.Single.view model.cleaning model.mapZoom

        Vacuum.Models.NotFoundRoute ->
            notFoundView

        _ ->
            notFoundView


notFoundView : Html Msg
notFoundView =
    Vacuum.Page.body
        "Not found"
        (text "The requested page could not be found")
