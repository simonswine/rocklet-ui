module Vacuum.Map exposing (..)

import Json.Decode as Decode
import Html exposing (Html, div, text, p)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Models exposing (Map, Path, Position)
import MouseEvents exposing (onClick, MouseEvent, relPos)
import Svg
import Html.Attributes exposing (style)
import Svg.Attributes exposing (viewBox, x, y, version, width, height, stroke, strokeWidth, fill, points, transform, opacity, r, cx, cy)
import Material.Slider as Slider
import Material.Options as Options


view : Map -> Float -> Path -> Maybe Position -> Maybe Position -> List (Html Msg)
view map scale path charger goto =
    [ Slider.view
        [ Slider.onChange Vacuum.Msgs.MapZoomSliderMsg
        , Slider.value scale
        , Slider.max 8
        , Slider.min 0.1
        , Slider.step 0.1
        , Options.css "margin-bottom" "20px"
        , Options.css "width" "400px"
        ]
    , div
        [ style
            [ ( "width", (scale * toFloat (map.width) |> round |> toString) ++ "px" )
            , ( "height", (scale * toFloat (map.height) |> round |> toString) ++ "px" )
            , ( "position", "relative" )
            ]
        ]
        [ p
            [ style
                [ ( "width", (scale * toFloat (map.width) |> round |> toString) ++ "px" )
                , ( "height", (scale * toFloat (map.height) |> round |> toString) ++ "px" )
                , ( "z-index", "100" )
                ]
            , onClick (\x -> Vacuum.Msgs.GoToPosition (mouseEventToPosition x scale map))
            ]
            []
        , Svg.svg
            [ version "1.1"
            , x "0"
            , y "0"
            , scale * toFloat (map.width) |> round |> toString |> width
            , scale * toFloat (map.height) |> round |> toString |> height
            , style
                [ ( "position", "absolute" )
                , ( "top", "0" )
                , ( "left", "0" )

                --, ( "top", (scale * toFloat (map.height) * -1 |> round |> toString) ++ "px" )
                , ( "z-index", "-1" )
                ]
            ]
            (svgContent
                map
                scale
                path
                charger
                goto
            )
        ]
    ]


mouseEventToPosition : MouseEvent -> Float -> Map -> Position
mouseEventToPosition x scale map =
    let
        pos =
            relPos x
    in
        { x =
            toFloat pos.x / scale
        , y =
            toFloat pos.y / scale
        }


pathToPoints : Path -> String
pathToPoints path =
    List.map (\p -> toString (p.x) ++ "," ++ toString (p.y)) path
        |> String.join " "


lastElem : List a -> Maybe a
lastElem =
    List.foldl (Just >> always) Nothing


svgContent : Map -> Float -> Path -> Maybe Position -> Maybe Position -> List (Svg.Svg Msg)
svgContent map scale path charger goto =
    [ Just
        (Svg.image
            [ Svg.Attributes.xlinkHref ("data:image/png;base64," ++ map.data)
            , x "0"
            , y "0"
            , map.width |> toString |> width
            , map.height |> toString |> height
            , "scale(" ++ (toString scale) ++ ")" |> transform
            ]
            []
        )
    , Just
        (Svg.polyline
            [ fill "none"
            , stroke "orange"
            , strokeWidth "0.7"
            , opacity "0.7"
            , path |> pathToPoints |> points
            , "scale(" ++ (toString scale) ++ ")" |> transform
            ]
            []
        )
    , case (lastElem path) of
        Just last ->
            Just
                (Svg.circle
                    [ fill "red"
                    , stroke "black"
                    , strokeWidth "0.8"
                    , opacity "0.7"
                    , r "3"
                    , cx (toString last.x)
                    , cy (toString last.y)
                    , "scale(" ++ (toString scale) ++ ")" |> transform
                    ]
                    []
                )

        _ ->
            Nothing
    , case goto of
        Just goto ->
            Just
                (Svg.circle
                    [ fill "purple"
                    , stroke "black"
                    , strokeWidth "0.8"
                    , opacity "0.7"
                    , r "3"
                    , cx (toString goto.x)
                    , cy (toString goto.y)
                    , "scale(" ++ (toString scale) ++ ")" |> transform
                    ]
                    []
                )

        _ ->
            Nothing
    , case charger of
        Just charger ->
            Just
                (Svg.circle
                    [ fill "green"
                    , stroke "black"
                    , strokeWidth "0.8"
                    , opacity "0.7"
                    , r "3"
                    , cx (toString charger.x)
                    , cy (toString charger.y)
                    , "scale(" ++ (toString scale) ++ ")" |> transform
                    ]
                    []
                )

        _ ->
            Nothing
    ]
        |> List.filterMap identity
