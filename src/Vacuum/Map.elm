module Vacuum.Map exposing (..)

import Html exposing (Html)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Models exposing (Map, Path, Position)
import Vacuum.Models
import Svg
import Svg.Attributes exposing (viewBox, x, y, version, width, height, stroke, strokeWidth, fill, points, transform, opacity, r, cx, cy)
import Material.Slider as Slider


view : Map -> Float -> Path -> Maybe Position -> List (Html Msg)
view map scale path charger =
    [ Slider.view
        [ Slider.onChange Vacuum.Msgs.MapZoomSliderMsg
        , Slider.value scale
        , Slider.max 8
        , Slider.min 0.1
        , Slider.step 0.1
        ]
    , Svg.svg
        [ version "1.1"
        , x "0"
        , y "0"
        , scale * toFloat (map.width) |> round |> toString |> width
        , scale * toFloat (map.height) |> round |> toString |> height
        ]
        (svgContent
            map
            scale
            path
            charger
        )
    ]


pathToPoints : Path -> String
pathToPoints path =
    List.map (\p -> toString (p.x) ++ "," ++ toString (p.y)) path
        |> String.join " "


lastElem : List a -> Maybe a
lastElem =
    List.foldl (Just >> always) Nothing


svgContent : Vacuum.Models.Map -> Float -> Vacuum.Models.Path -> Maybe Vacuum.Models.Position -> List (Svg.Svg msg)
svgContent map scale path charger =
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
