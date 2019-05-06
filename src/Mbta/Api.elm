module Mbta.Api exposing
    ( ApiKey(..)
    , Config
    , Host(..)
    , getPredictions
    , getRoute
    , getRoutePattern
    , getRoutePatterns
    , getRoutes
    , getSchedules
    , getService
    , getServices
    , getShape
    , getShapes
    , getStop
    , getStops
    , getTrip
    , getTrips
    , getVehicle
    , getVehicles
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



-- predictions+schedules


getPredictions : (Result Http.Error (List Prediction) -> msg) -> Config -> Cmd msg
getPredictions toMsg config =
    getCustomList toMsg config Mbta.Decode.prediction "predictions"


getSchedules : (Result Http.Error (List Schedule) -> msg) -> Config -> Cmd msg
getSchedules toMsg config =
    getCustomList toMsg config Mbta.Decode.schedule "schedules"



-- routes


getRoute : (Result Http.Error Route -> msg) -> Config -> RouteId -> Cmd msg
getRoute toMsg config (RouteId routeId) =
    getCustomId toMsg config Mbta.Decode.route "routes" routeId


getRoutes : (Result Http.Error (List Route) -> msg) -> Config -> Cmd msg
getRoutes toMsg config =
    getCustomList toMsg config Mbta.Decode.route "routes"


getRoutePattern : (Result Http.Error RoutePattern -> msg) -> Config -> RoutePatternId -> Cmd msg
getRoutePattern toMsg config (RoutePatternId routePatternId) =
    getCustomId toMsg config Mbta.Decode.routePattern "route-patterns" routePatternId


getRoutePatterns : (Result Http.Error (List RoutePattern) -> msg) -> Config -> Cmd msg
getRoutePatterns toMsg config =
    getCustomList toMsg config Mbta.Decode.routePattern "route-patterns"



-- services


getService : (Result Http.Error Service -> msg) -> Config -> ServiceId -> Cmd msg
getService toMsg config (ServiceId serviceId) =
    getCustomId toMsg config Mbta.Decode.service "services" serviceId


getServices : (Result Http.Error (List Service) -> msg) -> Config -> Cmd msg
getServices toMsg config =
    getCustomList toMsg config Mbta.Decode.service "services"



-- shapes


getShape : (Result Http.Error Shape -> msg) -> Config -> ShapeId -> Cmd msg
getShape toMsg config (ShapeId shapeId) =
    getCustomId toMsg config Mbta.Decode.shape "shapes" shapeId


getShapes : (Result Http.Error (List Shape) -> msg) -> Config -> Cmd msg
getShapes toMsg config =
    getCustomList toMsg config Mbta.Decode.shape "shapes"



-- stops


getStop : (Result Http.Error Stop -> msg) -> Config -> StopId -> Cmd msg
getStop toMsg config (StopId stopId) =
    getCustomId toMsg config Mbta.Decode.stop "stops" stopId


getStops : (Result Http.Error (List Stop) -> msg) -> Config -> Cmd msg
getStops toMsg config =
    getCustomList toMsg config Mbta.Decode.stop "stops"



-- trips


getTrip : (Result Http.Error Trip -> msg) -> Config -> TripId -> Cmd msg
getTrip toMsg config (TripId tripId) =
    getCustomId toMsg config Mbta.Decode.trip "trips" tripId


getTrips : (Result Http.Error (List Trip) -> msg) -> Config -> Cmd msg
getTrips toMsg config =
    getCustomList toMsg config Mbta.Decode.trip "trips"



-- vehicles


getVehicle : (Result Http.Error Vehicle -> msg) -> Config -> VehicleId -> Cmd msg
getVehicle toMsg config (VehicleId vehicleId) =
    getCustomId toMsg config Mbta.Decode.vehicle "vehicles" vehicleId


getVehicles : (Result Http.Error (List Vehicle) -> msg) -> Config -> Cmd msg
getVehicles toMsg config =
    getCustomList toMsg config Mbta.Decode.vehicle "vehicles"
