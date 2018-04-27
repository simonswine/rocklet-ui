module Vacuum.Page exposing (..)

import Html exposing (text, Html)
import Vacuum.Msgs exposing (Msg)
import Material.Color
import Material.Options exposing (css)
import Material.Grid exposing (grid, cell, noSpacing)


boxed : List (Material.Options.Property a b)
boxed =
    [ css "margin" "auto"
    , css "padding-left" "8%"
    , css "padding-right" "8%"
    , css "text-align" "left"
    ]


title : String -> Html a
title t =
    Material.Options.styled Html.h1
        [ Material.Color.text Material.Color.primary ]
        [ text t ]


body : String -> Html Msg -> Html Msg
body t content =
    Material.Options.div
        []
        [ Material.Options.div
            boxed
            [ title t
            , grid [ noSpacing ]
                [ cell [] [ content ]
                ]
            ]
        ]
