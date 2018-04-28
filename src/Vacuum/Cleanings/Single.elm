module Vacuum.Cleanings.Single exposing (..)

import Html exposing (..)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Models exposing (Cleaning, Path)
import Vacuum.Page
import RemoteData exposing (WebData)
import Material.Options exposing (css)
import Material.Grid exposing (grid, cell, noSpacing)
import Material.Slider as Slider
import String
import Svg
import Svg.Attributes exposing (viewBox, x, y, version, width, height, stroke, strokeWidth, fill, points, transform, opacity, r, cx, cy)


view : WebData Cleaning -> Float -> Html Msg
view response zoom =
    Vacuum.Page.body
        "Cleaning"
        (maybeCleaning response zoom)


maybeCleaning : WebData Cleaning -> Float -> Html Msg
maybeCleaning response zoom =
    case response of
        RemoteData.NotAsked ->
            text ""

        RemoteData.Loading ->
            text "Loading..."

        RemoteData.Success cleaning ->
            case cleaning.status.map of
                Just map ->
                    single cleaning map zoom

                Nothing ->
                    text "Cleaning does not contain map"

        RemoteData.Failure error ->
            text (toString error)


pathToPoints : Path -> String
pathToPoints path =
    List.map (\p -> toString (p.x) ++ "," ++ toString (p.y)) path
        |> String.join " "


lastElem : List a -> Maybe a
lastElem =
    List.foldl (Just >> always) Nothing


svgContent : Cleaning -> Vacuum.Models.Map -> Float -> List (Svg.Svg msg)
svgContent cleaning map scale =
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
            , cleaning.status.path |> pathToPoints |> points
            , "scale(" ++ (toString scale) ++ ")" |> transform
            ]
            []
        )
    , case (lastElem cleaning.status.path) of
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
    , case cleaning.status.charger of
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


single : Cleaning -> Vacuum.Models.Map -> Float -> Html Msg
single cleaning map scale =
    Material.Options.div
        []
        [ Material.Options.div
            []
            [ Html.h4
                []
                [ text (cleaning.metadata.namespace ++ "/" ++ cleaning.metadata.name) ]
            , grid [ noSpacing ]
                [ cell []
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
                            cleaning
                            map
                            scale
                        )
                    ]
                ]
            ]
        ]
