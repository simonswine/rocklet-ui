module Vacuum.Routing exposing (..)

import Navigation exposing (Location)
import Vacuum.Models exposing (Route(..))
import UrlParser exposing (..)


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map VacuumsRoute top
        , map VacuumRoute (s "vacuum" </> string)
        , map VacuumsRoute (s "vacuums")
        , map CleaningsRoute (s "cleanings")
        , map CleaningRoute (s "cleaning" </> string </> string)
        ]


parseLocation : Location -> Route
parseLocation location =
    case (parseHash matchers location) of
        Just route ->
            route

        Nothing ->
            NotFoundRoute
