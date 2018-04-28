module Vacuum.Commands exposing (..)

import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Models exposing (VacuumId, Vacuum, VacuumStatus, Cleaning, CleaningStatus, Metadata, Path, Position, Map)
import RemoteData
import Maybe


metadataDecoder : Decode.Decoder Metadata
metadataDecoder =
    decode Metadata
        |> required "namespace" Decode.string
        |> required "name" Decode.string


mapDecoder : Decode.Decoder Map
mapDecoder =
    decode Map
        |> required "left" Decode.int
        |> required "top" Decode.int
        |> required "width" Decode.int
        |> required "height" Decode.int
        |> required "data" Decode.string


positionDecoder : Decode.Decoder Position
positionDecoder =
    Decode.map2 Position
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)


pathDecoder : Decode.Decoder Path
pathDecoder =
    positionDecoder
        |> Decode.list


fetchVacuums : Cmd Msg
fetchVacuums =
    Http.get fetchVacuumsUrl vacuumsDecoder
        |> RemoteData.sendRequest
        |> Cmd.map Vacuum.Msgs.OnFetchVacuums


fetchVacuumsUrl : String
fetchVacuumsUrl =
    "/apis/vacuum.swine.de/v1alpha1/vacuums"


fetchVacuum : String -> String -> Cmd Msg
fetchVacuum namespace name =
    Http.get (fetchVacuumUrl namespace name) vacuumDecoder
        |> RemoteData.sendRequest
        |> Cmd.map Vacuum.Msgs.OnFetchVacuum


fetchVacuumUrl : String -> String -> String
fetchVacuumUrl namespace name =
    "/apis/vacuum.swine.de/v1alpha1/namespaces/" ++ namespace ++ "/vacuum/" ++ name


vacuumsDecoder : Decode.Decoder (List Vacuum)
vacuumsDecoder =
    Decode.list vacuumDecoder
        |> Decode.at [ "items" ]


vacuumStatusDecoder : Decode.Decoder VacuumStatus
vacuumStatusDecoder =
    decode VacuumStatus
        |> required "state" Decode.string


vacuumDecoder : Decode.Decoder Vacuum
vacuumDecoder =
    decode Vacuum
        |> required "metadata" metadataDecoder
        |> required "status" vacuumStatusDecoder


fetchCleanings : Cmd Msg
fetchCleanings =
    Http.get fetchCleaningsUrl cleaningsDecoder
        |> RemoteData.sendRequest
        |> Cmd.map Vacuum.Msgs.OnFetchCleanings


fetchCleaningsUrl : String
fetchCleaningsUrl =
    "/apis/vacuum.swine.de/v1alpha1/cleanings"


fetchCleaning : String -> String -> Cmd Msg
fetchCleaning namespace name =
    Http.get (fetchCleaningUrl namespace name) cleaningDecoder
        |> RemoteData.sendRequest
        |> Cmd.map Vacuum.Msgs.OnFetchCleaning


fetchCleaningUrl : String -> String -> String
fetchCleaningUrl namespace name =
    "/apis/vacuum.swine.de/v1alpha1/namespaces/" ++ namespace ++ "/cleanings/" ++ name


cleaningsDecoder : Decode.Decoder (List Cleaning)
cleaningsDecoder =
    Decode.list cleaningDecoder
        |> Decode.at [ "items" ]


cleaningStatusDecoder : Decode.Decoder CleaningStatus
cleaningStatusDecoder =
    decode CleaningStatus
        |> required "area" Decode.int
        |> required "code" Decode.int
        |> required "complete" Decode.bool
        |> required "duration" Decode.string
        |> optional "path" pathDecoder []
        |> optional "map" (Decode.nullable mapDecoder) Nothing
        |> optional "charger" (Decode.maybe positionDecoder) Nothing
        |> optional "beginTime" (Decode.nullable Decode.string) Nothing
        |> optional "endTime" (Decode.nullable Decode.string) Nothing


cleaningDecoder : Decode.Decoder Cleaning
cleaningDecoder =
    decode Cleaning
        |> required "metadata" metadataDecoder
        |> required "status" cleaningStatusDecoder
