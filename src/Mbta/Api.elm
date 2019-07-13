module Mbta.Api exposing
    ( Host(..)
    , ApiResult, Ok, Error(..)
    , Include, Relationship, include, andIts
    , getPredictions
    , predictionVehicle, predictionRoute, predictionSchedule, predictionTrip, predictionStop, predictionAlerts
    , getVehicle, getVehicles
    , vehicleRoute, vehicleTrip, vehicleStop
    , getRoute, getRoutes
    , routeRoutePatterns, routeLine, routeStop
    , getRoutePattern, getRoutePatterns
    , routePatternRoute, routePatternRepresentativeTrip
    , getLine, getLines
    , lineRoutes
    , getSchedules
    , schedulePrediction, scheduleRoute, scheduleTrip, scheduleStop
    , getTrip, getTrips
    , tripPredictions, tripVehicle, tripRoute, tripRoutePattern, tripService, tripShape
    , getService, getServices
    , getShape, getShapes
    , shapeRoute, shapeStops
    , getStop, getStops
    , stopParentStation, stopChildStops, stopRecommendedTransfers, stopFacilities
    , getFacility, getFacilities
    , facilityStop
    , getLiveFacility, getLiveFacilities
    , liveFacilityFacility
    , getAlert, getAlerts
    , alertRoutes, alertTrips, alertStops, alertFacilities
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


# Result

@docs ApiResult, Ok, Error


# Including

Sideload related resources

Use it like

    Mbta.Api.getTrip
        ReceiveTrip
        apiConfig
        [ Mbta.Api.include Mbta.Api.tripRoute ]
        filters

Any sideloaded resources are put in the [`Included`](#Included) object in the result.

@docs Include, Relationship, include, andIts


# Realtime Data


## [Prediction](#Mbta.Prediction)

@docs getPredictions
@docs predictionVehicle, predictionRoute, predictionSchedule, predictionTrip, predictionStop, predictionAlerts


## [Vehicle](#Mbta.Vehicle)

@docs getVehicle, getVehicles
@docs vehicleRoute, vehicleTrip, vehicleStop


# Schedule Data


## [Route](#Mbta.Route)

@docs getRoute, getRoutes

@docs routeRoutePatterns, routeLine, routeStop


## [RoutePattern](#Mbta.RoutePattern)

@docs getRoutePattern, getRoutePatterns
@docs routePatternRoute, routePatternRepresentativeTrip


## [Line](#Mbta.Line)

@docs getLine, getLines
@docs lineRoutes


## [Schedule](#Mbta.Schedule)

@docs getSchedules
@docs schedulePrediction, scheduleRoute, scheduleTrip, scheduleStop


## [Trip](#Mbta.Trip)

@docs getTrip, getTrips
@docs tripPredictions, tripVehicle, tripRoute, tripRoutePattern, tripService, tripShape


## [Service](#Mbta.Service)

@docs getService, getServices

`Service` does not currently have any relationships to include.


## [Shape](#Mbta.Shape)

@docs getShape, getShapes
@docs shapeRoute, shapeStops


# Stop Data


## [Stop](#Mbta.Stop)

@docs getStop, getStops
@docs stopParentStation, stopChildStops, stopRecommendedTransfers, stopFacilities


## [Facility](#Mbta.Facility)

@docs getFacility, getFacilities
@docs facilityStop


## [Live Facility](#Mbta.Live)

@docs getLiveFacility, getLiveFacilities
@docs liveFacilityFacility


# Alert Data


## [Alert](#Mbta.Alert)

@docs getAlert, getAlerts
@docs alertRoutes, alertTrips, alertStops, alertFacilities

-}

import Http
import Json.Decode as Decode
import JsonApi
import Mbta exposing (..)
import Mbta.Decode
import Mbta.Filter exposing (Filter)
import Mbta.Included as Included
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



-- Result


{-| -}
type alias ApiResult data =
    Result Error (Ok data)


{-| -}
type alias Ok data =
    { data : data
    , included : Included.Included
    }


{-| Sometimes things don't go as planned.

If we fail to decode the JSON:API format, that will show up as HttpError Http.BadPayload
If we fail to decode the MBTA types from the JSON:API format, it will be a DecodeError

Either way is a bug in this library or the API. Please report it.
TODO more reporting directions

TODO document cases
TODO create illegalCall

-}
type Error
    = InvalidRequest String
    | HttpError Http.Error
    | DecodeError String



-- Internal Helpers


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
                    , includeQueryParameter includes
                    , Mbta.Filter.queryParameters filters
                    ]
                )

        SameOrigin config ->
            Url.Builder.absolute
                (config.basePath ++ path)
                (List.concat
                    [ config.queryParameters
                    , includeQueryParameter includes
                    , Mbta.Filter.queryParameters filters
                    ]
                )

        CustomHost config ->
            Url.Builder.crossOrigin
                config.host
                (config.basePath ++ path)
                (List.concat
                    [ config.queryParameters
                    , includeQueryParameter includes
                    , Mbta.Filter.queryParameters filters
                    ]
                )


jsonApiErrorToApiError : JsonApi.Error -> Error
jsonApiErrorToApiError jsonApiError =
    case jsonApiError of
        JsonApi.HttpError httpError ->
            HttpError httpError

        JsonApi.NoncompliantJson decodeError ->
            HttpError (Http.BadBody (Decode.errorToString decodeError))

        JsonApi.DocumentError documentError ->
            DecodeError (JsonApi.documentErrorToString documentError)


getOne : (ApiResult resource -> msg) -> Host -> JsonApi.ResourceDecoder resource -> String -> List (Include resource) -> String -> Cmd msg
getOne toMsg host resourceDecoder path includes id =
    let
        toMsg_ : Result JsonApi.Error (JsonApi.Document Included.Included resource) -> msg
        toMsg_ =
            Result.mapError jsonApiErrorToApiError >> toMsg

        documentDecoder : JsonApi.DocumentDecoder Included.Included resource
        documentDecoder =
            JsonApi.documentDecoderOne Included.includedDecoder resourceDecoder
    in
    Http.get
        { url = makeUrl host [ path, id ] [] includes
        , expect = JsonApi.expectJsonApi toMsg_ documentDecoder
        }


getList : (ApiResult (List resource) -> msg) -> Host -> JsonApi.ResourceDecoder resource -> String -> List (Include resource) -> List (Filter resource) -> Cmd msg
getList toMsg host resourceDecoder path includes filters =
    let
        toMsg_ : Result JsonApi.Error (JsonApi.Document Included.Included (List resource)) -> msg
        toMsg_ =
            Result.mapError jsonApiErrorToApiError >> toMsg

        documentDecoder : JsonApi.DocumentDecoder Included.Included (List resource)
        documentDecoder =
            JsonApi.documentDecoderMany Included.includedDecoder resourceDecoder
    in
    Http.get
        { url = makeUrl host [ path ] filters includes
        , expect = JsonApi.expectJsonApi toMsg_ documentDecoder
        }



-- Including


{-| -}
type Include mainResource
    = Include String


{-| -}
type Relationship from to
    = Relationship String


{-| -}
include : Relationship from to -> Include from
include (Relationship s) =
    Include s


includeQueryParameter : List (Include a) -> List Url.Builder.QueryParameter
includeQueryParameter includes =
    case includes of
        [] ->
            []

        _ ->
            includes
                |> List.map (\(Include s) -> s)
                |> String.join ","
                |> Url.Builder.string "include"
                |> List.singleton


{-| For chaining includes

Adds an included resource's relationships into the sideloaded results.

Uses the `.` syntax from JSON:API's `?include=` options.

    includeRouteAndLineForAVehicle : Include Vehicle
    includeRouteAndLineForAVehicle =
        Include.include
            (Include.vehicleRoute
                |> Include.andIts Include.routeLine
            )

-}
andIts : Relationship b c -> Relationship a b -> Relationship a c
andIts (Relationship string1) (Relationship string2) =
    Relationship (string1 ++ "." ++ string2)



-- Realtime Data
-- Prediction


{-| At least one filter (not counting `directionId`) is required
-}
getPredictions : (ApiResult (List Prediction) -> msg) -> Host -> List (Include Prediction) -> List (Filter Prediction) -> Cmd msg
getPredictions toMsg host includes filters =
    getList toMsg host Mbta.Decode.prediction "predictions" includes filters


{-| -}
predictionVehicle : Relationship Prediction Vehicle
predictionVehicle =
    Relationship "vehicle"


{-| -}
predictionRoute : Relationship Prediction Route
predictionRoute =
    Relationship "route"


{-| -}
predictionSchedule : Relationship Prediction Schedule
predictionSchedule =
    Relationship "schedule"


{-| -}
predictionTrip : Relationship Prediction Trip
predictionTrip =
    Relationship "trip"


{-| -}
predictionStop : Relationship Prediction Stop
predictionStop =
    Relationship "stop"


{-| -}
predictionAlerts : Relationship Prediction Alert
predictionAlerts =
    Relationship "alerts"



-- Vehicle


{-| -}
getVehicle : (ApiResult Vehicle -> msg) -> Host -> List (Include Vehicle) -> VehicleId -> Cmd msg
getVehicle toMsg host includes (VehicleId vehicleId) =
    getOne toMsg host Mbta.Decode.vehicle "vehicles" includes vehicleId


{-| -}
getVehicles : (ApiResult (List Vehicle) -> msg) -> Host -> List (Include Vehicle) -> List (Filter Vehicle) -> Cmd msg
getVehicles toMsg host includes filters =
    getList toMsg host Mbta.Decode.vehicle "vehicles" includes filters


{-| -}
vehicleRoute : Relationship Vehicle Route
vehicleRoute =
    Relationship "route"


{-| -}
vehicleTrip : Relationship Vehicle Trip
vehicleTrip =
    Relationship "trip"


{-| -}
vehicleStop : Relationship Vehicle Trip
vehicleStop =
    Relationship "stop"



-- Schedule Data
-- Route


{-| -}
getRoute : (ApiResult Route -> msg) -> Host -> List (Include Route) -> RouteId -> Cmd msg
getRoute toMsg host includes (RouteId routeId) =
    getOne toMsg host Mbta.Decode.route "routes" includes routeId


{-| -}
getRoutes : (ApiResult (List Route) -> msg) -> Host -> List (Include Route) -> List (Filter Route) -> Cmd msg
getRoutes toMsg host includes filters =
    getList toMsg host Mbta.Decode.route "routes" includes filters


{-| -}
routeRoutePatterns : Relationship Route RoutePattern
routeRoutePatterns =
    Relationship "route_patterns"


{-| -}
routeLine : Relationship Route Line
routeLine =
    Relationship "line"


{-| Only valid when getting a list of routes with [`getRoutes`](#Mbta.Api.getRoutes), and when [`filter stop TODO`](TODO) is used.

If this relationship is given when invalid, the result will be a TODO error

-}
routeStop : Relationship Route Stop
routeStop =
    Relationship "stop"



-- RoutePattern


{-| -}
getRoutePattern : (ApiResult RoutePattern -> msg) -> Host -> List (Include RoutePattern) -> RoutePatternId -> Cmd msg
getRoutePattern toMsg host includes (RoutePatternId routePatternId) =
    getOne toMsg host Mbta.Decode.routePattern "route-patterns" includes routePatternId


{-| -}
getRoutePatterns : (ApiResult (List RoutePattern) -> msg) -> Host -> List (Include RoutePattern) -> List (Filter RoutePattern) -> Cmd msg
getRoutePatterns toMsg host includes filters =
    getList toMsg host Mbta.Decode.routePattern "route-patterns" includes filters


{-| -}
routePatternRoute : Relationship RoutePattern Route
routePatternRoute =
    Relationship "route"


{-| -}
routePatternRepresentativeTrip : Relationship RoutePattern Trip
routePatternRepresentativeTrip =
    Relationship "representative_trip"



-- Line


{-| -}
getLine : (ApiResult Line -> msg) -> Host -> List (Include Line) -> LineId -> Cmd msg
getLine toMsg host includes (LineId lineId) =
    getOne toMsg host Mbta.Decode.line "lines" includes lineId


{-| -}
getLines : (ApiResult (List Line) -> msg) -> Host -> List (Include Line) -> List (Filter Line) -> Cmd msg
getLines toMsg host includes filters =
    getList toMsg host Mbta.Decode.line "lines" includes filters


{-| -}
lineRoutes : Relationship Line Route
lineRoutes =
    Relationship "routes"



-- Schedule


{-| Requires filtering by at least one of route, stop, or trip.
-}
getSchedules : (ApiResult (List Schedule) -> msg) -> Host -> List (Include Schedule) -> List (Filter Schedule) -> Cmd msg
getSchedules toMsg host includes filters =
    getList toMsg host Mbta.Decode.schedule "schedules" includes filters


{-| -}
scheduleStop : Relationship Schedule Stop
scheduleStop =
    Relationship "stop"


{-| -}
scheduleTrip : Relationship Schedule Trip
scheduleTrip =
    Relationship "trip"


{-| -}
schedulePrediction : Relationship Schedule Prediction
schedulePrediction =
    Relationship "prediction"


{-| -}
scheduleRoute : Relationship Schedule Route
scheduleRoute =
    Relationship "route"



-- Trip


{-| -}
getTrip : (ApiResult Trip -> msg) -> Host -> List (Include Trip) -> TripId -> Cmd msg
getTrip toMsg host includes (TripId tripId) =
    getOne toMsg host Mbta.Decode.trip "trips" includes tripId


{-| -}
getTrips : (ApiResult (List Trip) -> msg) -> Host -> List (Include Trip) -> List (Filter Trip) -> Cmd msg
getTrips toMsg host includes filters =
    getList toMsg host Mbta.Decode.trip "trips" includes filters


{-| -}
tripPredictions : Relationship Trip Prediction
tripPredictions =
    Relationship "predictions"


{-| -}
tripVehicle : Relationship Trip Vehicle
tripVehicle =
    Relationship "vehicle"


{-| -}
tripRoute : Relationship Trip Route
tripRoute =
    Relationship "route"


{-| -}
tripRoutePattern : Relationship Trip RoutePattern
tripRoutePattern =
    Relationship "route_pattern"


{-| -}
tripService : Relationship Trip Service
tripService =
    Relationship "service"


{-| -}
tripShape : Relationship Trip Shape
tripShape =
    Relationship "shape"



-- Service


{-| -}
getService : (ApiResult Service -> msg) -> Host -> List (Include Service) -> ServiceId -> Cmd msg
getService toMsg host includes (ServiceId serviceId) =
    getOne toMsg host Mbta.Decode.service "services" includes serviceId


{-| -}
getServices : (ApiResult (List Service) -> msg) -> Host -> List (Include Service) -> List (Filter Service) -> Cmd msg
getServices toMsg host includes filters =
    getList toMsg host Mbta.Decode.service "services" includes filters



-- (no includes from Service)
-- Shape


{-| -}
getShape : (ApiResult Shape -> msg) -> Host -> List (Include Shape) -> ShapeId -> Cmd msg
getShape toMsg host includes (ShapeId shapeId) =
    getOne toMsg host Mbta.Decode.shape "shapes" includes shapeId


{-| Must filter by route
-}
getShapes : (ApiResult (List Shape) -> msg) -> Host -> List (Include Shape) -> List (Filter Shape) -> Cmd msg
getShapes toMsg host includes filters =
    getList toMsg host Mbta.Decode.shape "shapes" includes filters


{-| -}
shapeRoute : Relationship Shape Route
shapeRoute =
    Relationship "route"


{-| -}
shapeStops : Relationship Shape Stop
shapeStops =
    Relationship "stops"



-- Stop Data
-- Stop


{-| -}
getStop : (ApiResult Stop -> msg) -> Host -> List (Include Stop) -> StopId -> Cmd msg
getStop toMsg host includes (StopId stopId) =
    getOne toMsg host Mbta.Decode.stop "stops" includes stopId


{-| -}
getStops : (ApiResult (List Stop) -> msg) -> Host -> List (Include Stop) -> List (Filter Stop) -> Cmd msg
getStops toMsg host includes filters =
    getList toMsg host Mbta.Decode.stop "stops" includes filters


{-| -}
stopParentStation : Relationship Stop Stop
stopParentStation =
    Relationship "parent_station"


{-| -}
stopChildStops : Relationship Stop Stop
stopChildStops =
    Relationship "child_stops"


{-| -}
stopRecommendedTransfers : Relationship Stop Stop
stopRecommendedTransfers =
    Relationship "recommended_transfers"


{-| -}
stopFacilities : Relationship Stop Facility
stopFacilities =
    Relationship "facilities"



-- Facility


{-| -}
getFacility : (ApiResult Facility -> msg) -> Host -> List (Include Facility) -> FacilityId -> Cmd msg
getFacility toMsg host includes (FacilityId facilityId) =
    getOne toMsg host Mbta.Decode.facility "facilities" includes facilityId


{-| -}
getFacilities : (ApiResult (List Facility) -> msg) -> Host -> List (Include Facility) -> List (Filter Facility) -> Cmd msg
getFacilities toMsg host includes filters =
    getList toMsg host Mbta.Decode.facility "facilities" includes filters


{-| -}
facilityStop : Relationship Facility Stop
facilityStop =
    Relationship "stop"



-- LiveFacility


{-| -}
getLiveFacility : (ApiResult LiveFacility -> msg) -> Host -> List (Include LiveFacility) -> FacilityId -> Cmd msg
getLiveFacility toMsg host includes (FacilityId facilityId) =
    getOne toMsg host Mbta.Decode.liveFacility "live-facilities" includes facilityId


{-| -}
getLiveFacilities : (ApiResult (List LiveFacility) -> msg) -> Host -> List (Include LiveFacility) -> List (Filter LiveFacility) -> Cmd msg
getLiveFacilities toMsg host includes filters =
    getList toMsg host Mbta.Decode.liveFacility "live-facilities" includes filters


{-| -}
liveFacilityFacility : Relationship LiveFacility Facility
liveFacilityFacility =
    Relationship "facility"



-- Alert Data
-- Alert


{-| -}
getAlert : (ApiResult Alert -> msg) -> Host -> List (Include Alert) -> AlertId -> Cmd msg
getAlert toMsg host includes (AlertId alertId) =
    getOne toMsg host Mbta.Decode.alert "alerts" includes alertId


{-| -}
getAlerts : (ApiResult (List Alert) -> msg) -> Host -> List (Include Alert) -> List (Filter Alert) -> Cmd msg
getAlerts toMsg host includes filters =
    getList toMsg host Mbta.Decode.alert "alerts" includes filters


{-| -}
alertRoutes : Relationship Alert Route
alertRoutes =
    Relationship "routes"


{-| -}
alertTrips : Relationship Alert Trip
alertTrips =
    Relationship "trips"


{-| -}
alertStops : Relationship Alert Stop
alertStops =
    Relationship "stops"


{-| -}
alertFacilities : Relationship Alert Facility
alertFacilities =
    Relationship "facilities"
