module Mbta.Api exposing
    ( ApiKey(..)
    , Config
    , Host(..)
    )

import DecodeHelpers
import Http
import JsonApi
import Mbta exposing (..)
import Mbta.Decode
import Url.Builder


type Host
    = Default
    | SameOrigin (List String)
    | CustomHost String


type ApiKey
    = NoApiKey
    | ApiKey String


type alias Config =
    { host : Host
    , apiKey : ApiKey
    }


url : Config -> List String -> String
url config path =
    let
        apiKeyQueryParams =
            case config.apiKey of
                NoApiKey ->
                    []

                ApiKey key ->
                    [ Url.Builder.string "api_key" key ]

        urlExceptParams : List Url.Builder.QueryParameter -> String
        urlExceptParams =
            case config.host of
                Default ->
                    Url.Builder.crossOrigin "https://api-v3.mbta.com" path

                SameOrigin apiPath ->
                    Url.Builder.absolute (apiPath ++ path)

                CustomHost customHost ->
                    Url.Builder.crossOrigin "https://api-v3.mbta.com" path
    in
    urlExceptParams apiKeyQueryParams


getCustomId : (Result Http.Error resource -> msg) -> Config -> JsonApi.Decoder resource -> String -> String -> Cmd msg
getCustomId toMsg config resourceDecoder path id =
    Http.get
        { url = url config [ path, id ]
        , expect = Http.expectJson toMsg (JsonApi.decoderOne resourceDecoder)
        }


getCustomList : (Result Http.Error (List resource) -> msg) -> Config -> JsonApi.Decoder resource -> String -> Cmd msg
getCustomList toMsg config resourceDecoder path =
    Http.get
        { url = url config [ path ]
        , expect = Http.expectJson toMsg (JsonApi.decoderMany resourceDecoder)
        }



-- /stop


getStop : (Result Http.Error Stop -> msg) -> Config -> StopId -> Cmd msg
getStop toMsg config (StopId stopId) =
    getCustomId toMsg config Mbta.Decode.stop "stop" stopId


getStops : (Result Http.Error (List Stop) -> msg) -> Config -> Cmd msg
getStops toMsg config =
    getCustomList toMsg config Mbta.Decode.stop "stop"
