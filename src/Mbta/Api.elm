module Mbta.Api exposing
    ( ApiKey(..)
    , Config
    , Host(..)
    )

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import JsonApi
import Mbta exposing (..)
import Mbta.Decode
import Url.Builder


type Host
    = Default
    | CustomUrl String


type ApiKey
    = NoApiKey
    | ApiKey String


type alias Config =
    { host : Host
    , apiKey : ApiKey
    }


hostUrl : Host -> String
hostUrl host =
    case host of
        Default ->
            "https://api-v3.mbta.com"

        CustomUrl url ->
            url


apiKeyQueryParams : ApiKey -> List Url.Builder.QueryParameter
apiKeyQueryParams apiKey =
    case apiKey of
        NoApiKey ->
            []

        ApiKey key ->
            [ Url.Builder.string "api_key" key ]


getCustomId : (Result Http.Error resource -> msg) -> Config -> (JsonApi.Resource -> Decoder resource) -> String -> String -> Cmd msg
getCustomId toMsg config resourceDecoder path id =
    let
        url =
            Url.Builder.crossOrigin
                (hostUrl config.host)
                [ path, id ]
                (apiKeyQueryParams config.apiKey)

        decoder =
            JsonApi.resourceDecoder
                |> Decode.andThen
                    (\resource ->
                        resourceDecoder resource
                    )
                |> Decode.field "data"
    in
    Http.get
        { url = url
        , expect = Http.expectJson toMsg decoder
        }


getCustomList : (Result Http.Error (List resource) -> msg) -> Config -> (JsonApi.Resource -> Decoder resource) -> String -> Cmd msg
getCustomList toMsg config resourceDecoder path =
    let
        url =
            Url.Builder.crossOrigin
                (hostUrl config.host)
                [ path ]
                (apiKeyQueryParams config.apiKey)

        decoder =
            JsonApi.resourceDecoder
                |> Decode.andThen
                    (\resource ->
                        resourceDecoder resource
                    )
                |> Decode.list
                |> Decode.field "data"
    in
    Http.get
        { url = url
        , expect = Http.expectJson toMsg decoder
        }



-- /stop


getStop : (Result Http.Error Stop -> msg) -> Config -> StopId -> Cmd msg
getStop toMsg config (StopId stopId) =
    getCustomId toMsg config Mbta.Decode.stop "stop" stopId


getStops : (Result Http.Error (List Stop) -> msg) -> Config -> Cmd msg
getStops toMsg config =
    getCustomList toMsg config Mbta.Decode.stop "stop"
