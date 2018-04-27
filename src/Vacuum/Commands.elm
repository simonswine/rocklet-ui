module Vacuum.Commands exposing (..)

import Http
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required)
import Vacuum.Msgs exposing (Msg)
import Vacuum.Models exposing (VacuumId, Vacuum, VacuumStatus, Cleaning, CleaningStatus, Metadata)
import RemoteData


metadataDecoder : Decode.Decoder Metadata
metadataDecoder =
    decode Metadata
        |> required "namespace" Decode.string
        |> required "name" Decode.string


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


cleaningDecoder : Decode.Decoder Cleaning
cleaningDecoder =
    decode Cleaning
        |> required "metadata" metadataDecoder
        |> required "status" cleaningStatusDecoder
