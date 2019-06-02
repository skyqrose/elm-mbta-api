module Mbta.Api exposing
    ( Host(..)
    , getPredictions
    , getVehicle, getVehicles
    , getRoute, getRoutes
    , getRoutePattern, getRoutePatterns
    , getLine, getLines
    , getSchedules
    , getTrip, getTrips
    , getService, getServices
    , getShape, getShapes
    , getStop, getStops
    , getFacility, getFacilities
    , getLiveFacility, getLiveFacilities
    , getAlert, getAlerts
    )

{-| Make HTTP requests to get data

All of the calls that return a list of data take a list of filters, and a function to provide an empty list of filters. Use it to build your filters like this:

    getPredictions ReceivePredictions
        host
        { predictionsFilter
            | routeType = RouteType_2_CommuterRail
            , stop = [ StopId "place-sstat" ]
        }

If you want all results, pass in the empty filter without setting any fields,
though note that some calls require at least one filter to be specified.


# Configuration

@docs Host


# Realtime Data

@docs getPredictions
@docs getVehicle, getVehicles


# Schedule Data

@docs getRoute, getRoutes
@docs getRoutePattern, getRoutePatterns
@docs getLine, getLines
@docs getSchedules
@docs getTrip, getTrips
@docs getService, getServices
@docs getShape, getShapes


# Stops

@docs getStop, getStops
@docs getFacility, getFacilities
@docs getLiveFacility, getLiveFacilities


# Alerts

@docs getAlert, getAlerts

-}

import Http
import Json.Decode
import JsonApi
import Mbta exposing (..)
import Mbta.Decode
import Mbta.Filter exposing (Filter)
import Mbta.Include exposing (Include)
import Url.Builder



-- Configuration


{-| Where to send the HTTP requests?

  - `Default`
    <https://api-v3.mbta.com>, MBTA's official API server.
    An API key is not required, but recommended. [Sign up for a key.](https://api-v3.mbta.com/register)
  - `SameOrigin pathPrefix`
    You might want to have all api calls go to your server,
    and then your server can make the api call to the api server and forward the JSON back to the client.
    If you want to have what would normally be `https://api-v3.mbta.com/vehicles` be called to `/api/mbta-forward/vehicles`,
    use a `basePath` of `["api", "mbta-forward"]`
  - `CustomHost urlPrefix`
    Specify another api server.
    e.g. `Default` is equivalent to `CustomHost` with `host = "https://api-v3.mbta.com"` and `basePath = []`

If you use anything except `SameOrigin`, you may need to configure CORS.
-- TODO more specific instructions

-}
type Host
    = Default
        { apiKey : Maybe String
        }
    | SameOrigin
        { basePath : List String
        , queryParameters : List Url.Builder.QueryParameter
        }
    | CustomHost
        { host : String
        , basePath : List String
        , queryParameters : List Url.Builder.QueryParameter
        }


makeUrl : Host -> List String -> List (Filter resource) -> List (Include resource) -> String
makeUrl host path filters includes =
    case host of
        Default config ->
            let
                apiKeyQueryParam : List Url.Builder.QueryParameter
                apiKeyQueryParam =
                    case config.apiKey of
                        Nothing ->
                            []

                        Just key ->
                            [ Url.Builder.string "api_key" key ]
            in
            Url.Builder.crossOrigin
                "https://api-v3.mbta.com"
                path
                (List.concat
                    [ apiKeyQueryParam
                    , Mbta.Include.queryParameter includes
                    , Mbta.Filter.queryParameters filters
                    ]
                )

        SameOrigin config ->
            Url.Builder.absolute
                (config.basePath ++ path)
                (List.concat
                    [ config.queryParameters
                    , Mbta.Include.queryParameter includes
                    , Mbta.Filter.queryParameters filters
                    ]
                )

        CustomHost config ->
            Url.Builder.crossOrigin
                config.host
                (config.basePath ++ path)
                (List.concat
                    [ config.queryParameters
                    , Mbta.Include.queryParameter includes
                    , Mbta.Filter.queryParameters filters
                    ]
                )


getCustomId : (Result Error resource -> msg) -> Host -> JsonApi.Decoder resource -> String -> List (Include resource) -> String -> Cmd msg
getCustomId toMsg host resourceDecoder path includes id =
    getCustom
        toMsg
        (makeUrl host [ path, id ] [] includes)
        (JsonApi.decodeOne resourceDecoder)


getCustomList : (Result Error (List resource) -> msg) -> Host -> JsonApi.Decoder resource -> String -> List (Include resource) -> List (Filter resource) -> Cmd msg
getCustomList toMsg host resourceDecoder path includes filters =
    getCustom
        toMsg
        (makeUrl host [ path ] filters includes)
        (JsonApi.decodeMany resourceDecoder)


getCustom : (Result Error data -> msg) -> String -> (JsonApi.Document -> Result JsonApi.DocumentError data) -> Cmd msg
getCustom toMsg url decodeDocument =
    let
        documentToMsg : Result Http.Error JsonApi.Document -> msg
        documentToMsg httpResult =
            httpResult
                |> Result.mapError HttpError
                |> Result.andThen
                    (\document ->
                        document
                            |> decodeDocument
                            |> Result.mapError DecodeError
                    )
                |> toMsg
    in
    Http.get
        { url = url
        , expect = Http.expectJson documentToMsg JsonApi.documentDecoder
        }



-- Result


{-| Sometimes things don't go as planned.

If we fail to decode the JSON:API format, that will show up as HttpError Http.BadPayload
If we fail to decode the MBTA types from the JSON:API format, it will be a DecodeError

Either way is a bug in this library. Please report it.
TODO more reporting directions

TODO document cases
TODO create illegalCall

-}
type Error
    = HttpError Http.Error
    | DecodeError JsonApi.DocumentError
    | IllegalCall String



-- Realtime Data


{-| At least one filter (not counting `directionId`) is required
-}
getPredictions : (Result Error (List Prediction) -> msg) -> Host -> List (Include Prediction) -> List (Filter Prediction) -> Cmd msg
getPredictions toMsg host includes filters =
    getCustomList toMsg host Mbta.Decode.prediction "predictions" includes filters


{-| -}
getVehicle : (Result Error Vehicle -> msg) -> Host -> List (Include Vehicle) -> VehicleId -> Cmd msg
getVehicle toMsg host includes (VehicleId vehicleId) =
    getCustomId toMsg host Mbta.Decode.vehicle "vehicles" includes vehicleId


{-| -}
getVehicles : (Result Error (List Vehicle) -> msg) -> Host -> List (Include Vehicle) -> List (Filter Vehicle) -> Cmd msg
getVehicles toMsg host includes filters =
    getCustomList toMsg host Mbta.Decode.vehicle "vehicles" includes filters



-- Schedule Data


{-| -}
getRoute : (Result Error Route -> msg) -> Host -> List (Include Route) -> RouteId -> Cmd msg
getRoute toMsg host includes (RouteId routeId) =
    getCustomId toMsg host Mbta.Decode.route "routes" includes routeId


{-| -}
getRoutes : (Result Error (List Route) -> msg) -> Host -> List (Include Route) -> List (Filter Route) -> Cmd msg
getRoutes toMsg host includes filters =
    getCustomList toMsg host Mbta.Decode.route "routes" includes filters


{-| -}
getRoutePattern : (Result Error RoutePattern -> msg) -> Host -> List (Include RoutePattern) -> RoutePatternId -> Cmd msg
getRoutePattern toMsg host includes (RoutePatternId routePatternId) =
    getCustomId toMsg host Mbta.Decode.routePattern "route-patterns" includes routePatternId


{-| -}
getRoutePatterns : (Result Error (List RoutePattern) -> msg) -> Host -> List (Include RoutePattern) -> List (Filter RoutePattern) -> Cmd msg
getRoutePatterns toMsg host includes filters =
    getCustomList toMsg host Mbta.Decode.routePattern "route-patterns" includes filters


{-| -}
getLine : (Result Error Line -> msg) -> Host -> List (Include Line) -> LineId -> Cmd msg
getLine toMsg host includes (LineId lineId) =
    getCustomId toMsg host Mbta.Decode.line "lines" includes lineId


{-| -}
getLines : (Result Error (List Line) -> msg) -> Host -> List (Include Line) -> List (Filter Line) -> Cmd msg
getLines toMsg host includes filters =
    getCustomList toMsg host Mbta.Decode.line "lines" includes filters


{-| Requires filtering by at least one of route, stop, or trip.
-}
getSchedules : (Result Error (List Schedule) -> msg) -> Host -> List (Include Schedule) -> List (Filter Schedule) -> Cmd msg
getSchedules toMsg host includes filters =
    getCustomList toMsg host Mbta.Decode.schedule "schedules" includes filters


{-| -}
getTrip : (Result Error Trip -> msg) -> Host -> List (Include Trip) -> TripId -> Cmd msg
getTrip toMsg host includes (TripId tripId) =
    getCustomId toMsg host Mbta.Decode.trip "trips" includes tripId


{-| -}
getTrips : (Result Error (List Trip) -> msg) -> Host -> List (Include Trip) -> List (Filter Trip) -> Cmd msg
getTrips toMsg host includes filters =
    getCustomList toMsg host Mbta.Decode.trip "trips" includes filters


{-| -}
getService : (Result Error Service -> msg) -> Host -> List (Include Service) -> ServiceId -> Cmd msg
getService toMsg host includes (ServiceId serviceId) =
    getCustomId toMsg host Mbta.Decode.service "services" includes serviceId


{-| -}
getServices : (Result Error (List Service) -> msg) -> Host -> List (Include Service) -> List (Filter Service) -> Cmd msg
getServices toMsg host includes filters =
    getCustomList toMsg host Mbta.Decode.service "services" includes filters


{-| -}
getShape : (Result Error Shape -> msg) -> Host -> List (Include Shape) -> ShapeId -> Cmd msg
getShape toMsg host includes (ShapeId shapeId) =
    getCustomId toMsg host Mbta.Decode.shape "shapes" includes shapeId


{-| Must filter by route
-}
getShapes : (Result Error (List Shape) -> msg) -> Host -> List (Include Shape) -> List (Filter Shape) -> Cmd msg
getShapes toMsg host includes filters =
    getCustomList toMsg host Mbta.Decode.shape "shapes" includes filters



-- Stops


{-| -}
getStop : (Result Error Stop -> msg) -> Host -> List (Include Stop) -> StopId -> Cmd msg
getStop toMsg host includes (StopId stopId) =
    getCustomId toMsg host Mbta.Decode.stop "stops" includes stopId


{-| -}
getStops : (Result Error (List Stop) -> msg) -> Host -> List (Include Stop) -> List (Filter Stop) -> Cmd msg
getStops toMsg host includes filters =
    getCustomList toMsg host Mbta.Decode.stop "stops" includes filters


{-| -}
getFacility : (Result Error Facility -> msg) -> Host -> List (Include Facility) -> FacilityId -> Cmd msg
getFacility toMsg host includes (FacilityId facilityId) =
    getCustomId toMsg host Mbta.Decode.facility "facilities" includes facilityId


{-| -}
getFacilities : (Result Error (List Facility) -> msg) -> Host -> List (Include Facility) -> List (Filter Facility) -> Cmd msg
getFacilities toMsg host includes filters =
    getCustomList toMsg host Mbta.Decode.facility "facilities" includes filters


{-| -}
getLiveFacility : (Result Error LiveFacility -> msg) -> Host -> List (Include LiveFacility) -> FacilityId -> Cmd msg
getLiveFacility toMsg host includes (FacilityId facilityId) =
    getCustomId toMsg host Mbta.Decode.liveFacility "live-facilities" includes facilityId


{-| -}
getLiveFacilities : (Result Error (List LiveFacility) -> msg) -> Host -> List (Include LiveFacility) -> List (Filter LiveFacility) -> Cmd msg
getLiveFacilities toMsg host includes filters =
    getCustomList toMsg host Mbta.Decode.liveFacility "live-facilities" includes filters



-- Alerts


{-| -}
getAlert : (Result Error Alert -> msg) -> Host -> List (Include Alert) -> AlertId -> Cmd msg
getAlert toMsg host includes (AlertId alertId) =
    getCustomId toMsg host Mbta.Decode.alert "alerts" includes alertId


{-| -}
getAlerts : (Result Error (List Alert) -> msg) -> Host -> List (Include Alert) -> List (Filter Alert) -> Cmd msg
getAlerts toMsg host includes filters =
    getCustomList toMsg host Mbta.Decode.alert "alerts" includes filters
