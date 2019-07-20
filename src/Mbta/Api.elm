module Mbta.Api exposing
    ( Host(..)
    , ApiResult, Ok, Error(..)
    , Include, Relationship, include, andIts
    , Included
    , getIncludedPrediction, getIncludedVehicle, getIncludedRoute, getIncludedRoutePattern, getIncludedLine, getIncludedSchedule, getIncludedTrip, getIncludedService, getIncludedShape, getIncludedStop, getIncludedFacility, getIncludedLiveFacility, getIncludedAlert
    , Filter
    , StreamData, StreamError(..), getStreamData, getStreamIncluded, updateStream
    , getPredictions, streamPredictions
    , predictionVehicle, predictionRoute, predictionSchedule, predictionTrip, predictionStop, predictionAlerts
    , filterPredictionsByRouteTypes, filterPredictionsByRouteIds, filterPredictionsByTripIds, filterPredictionsByDirectionId, filterPredictionsByStopIds, filterPredictionsByLatLng, filterPredictionsByLatLngWithRadius
    , getVehicle, getVehicles, streamVehicles
    , vehicleRoute, vehicleTrip, vehicleStop
    , filterVehiclesByIds, filterVehiclesByLabels, filterVehiclesByRouteIds, filterVehiclesByRouteTypes, filterVehiclesByDirectionId, filterVehiclesByTripIds
    , getRoute, getRoutes
    , routeRoutePatterns, routeLine, routeStop
    , filterRoutesByIds, filterRoutesByRouteTypes, filterRoutesByDirectionId, filterRoutesByStopIds
    , getRoutePattern, getRoutePatterns
    , routePatternRoute, routePatternRepresentativeTrip
    , filterRoutePatternsByIds, filterRoutePatternsByRouteIds, filterRoutePatternsByDirectionId
    , getLine, getLines
    , lineRoutes
    , filterLinesByIds
    , getSchedules
    , schedulePrediction, scheduleRoute, scheduleTrip, scheduleStop
    , filterSchedulesByRouteIds, filterSchedulesByDirectionId, filterSchedulesByTripIds, filterSchedulesByStopSequence, StopSequenceFilter, filterSchedulesByStopIds, filterSchedulesByServiceDate, filterSchedulesByMinTime, filterSchedulesByMaxTime
    , getTrip, getTrips
    , tripPredictions, tripVehicle, tripRoute, tripRoutePattern, tripService, tripShape
    , filterTripsByIds, filterTripsByNames, filterTripsByRouteIds, filterTripsByRoutePatternIds, filterTripsByDirectionId
    , getService, getServices
    , filterServicesByIds
    , getShape, getShapes
    , shapeRoute, shapeStops
    , filterShapesByRouteIds, filterShapesByDirectionId
    , getStop, getStops
    , stopParentStation, stopChildStops, stopRecommendedTransfers, stopFacilities
    , filterStopsByIds, filterStopsByLocationTypes, filterStopsByRouteTypes, filterStopsByRouteIds, filterStopsByDirectionId, filterStopsByLatLng, filterStopsByLatLngWithRadius
    , getFacility, getFacilities
    , facilityStop
    , filterFacilitiesByStopIds, filterFacilitiesByFacilityTypes
    , getLiveFacility, getLiveFacilities
    , liveFacilityFacility
    , filterLiveFacilitiesByIds
    , getAlert, getAlerts, streamAlerts
    , alertRoutes, alertTrips, alertStops, alertFacilities
    , filterAlertsByIds, filterAlertsByRouteTypes, filterAlertsByRouteIds, filterAlertsByDirectionId, filterAlertsByTripIds, filterAlertsByStopIds, filterAlertsByFacilities, filterAlertsByActivities, filterAlertsByDatetime, AlertDatetimeFilter, filterAlertsByLifecycles, filterAlertsBySeverities
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
@docs Included
@docs getIncludedPrediction, getIncludedVehicle, getIncludedRoute, getIncludedRoutePattern, getIncludedLine, getIncludedSchedule, getIncludedTrip, getIncludedService, getIncludedShape, getIncludedStop, getIncludedFacility, getIncludedLiveFacility, getIncludedAlert


# Filtering

Use it like

    Mbta.Api.getTrips
        ReceiveTrip
        apiConfig
        [ Mbta.filterTripsByRouteIds [ redLineId, orangeLineId ]
        , Mbta.filterTripsByDirectionId Mbta.D0
        ]
        includes

@docs Filter


# Streaming

@docs StreamData, StreamError, getStreamData, getStreamIncluded, updateStream


# Realtime Data


## [Prediction](#Mbta.Prediction)

@docs getPredictions, streamPredictions


### Includes

@docs predictionVehicle, predictionRoute, predictionSchedule, predictionTrip, predictionStop, predictionAlerts


### Filters

@docs filterPredictionsByRouteTypes, filterPredictionsByRouteIds, filterPredictionsByTripIds, filterPredictionsByDirectionId, filterPredictionsByStopIds, filterPredictionsByLatLng, filterPredictionsByLatLngWithRadius


## [Vehicle](#Mbta.Vehicle)

@docs getVehicle, getVehicles, streamVehicles


### Includes

@docs vehicleRoute, vehicleTrip, vehicleStop


### Filters

@docs filterVehiclesByIds, filterVehiclesByLabels, filterVehiclesByRouteIds, filterVehiclesByRouteTypes, filterVehiclesByDirectionId, filterVehiclesByTripIds


# Schedule Data


## [Route](#Mbta.Route)

@docs getRoute, getRoutes


### Includes

@docs routeRoutePatterns, routeLine, routeStop


### Filters

@docs filterRoutesByIds, filterRoutesByRouteTypes, filterRoutesByDirectionId, filterRoutesByStopIds


## [RoutePattern](#Mbta.RoutePattern)

@docs getRoutePattern, getRoutePatterns


### Includes

@docs routePatternRoute, routePatternRepresentativeTrip


### Filters

@docs filterRoutePatternsByIds, filterRoutePatternsByRouteIds, filterRoutePatternsByDirectionId


## [Line](#Mbta.Line)

@docs getLine, getLines


### Includes

@docs lineRoutes


### Filters

@docs filterLinesByIds


## [Schedule](#Mbta.Schedule)

@docs getSchedules


### Includes

@docs schedulePrediction, scheduleRoute, scheduleTrip, scheduleStop


### Filters

@docs filterSchedulesByRouteIds, filterSchedulesByDirectionId, filterSchedulesByTripIds, filterSchedulesByStopSequence, StopSequenceFilter, filterSchedulesByStopIds, filterSchedulesByServiceDate, filterSchedulesByMinTime, filterSchedulesByMaxTime


## [Trip](#Mbta.Trip)

@docs getTrip, getTrips


### Includes

@docs tripPredictions, tripVehicle, tripRoute, tripRoutePattern, tripService, tripShape


### Filters

@docs filterTripsByIds, filterTripsByNames, filterTripsByRouteIds, filterTripsByRoutePatternIds, filterTripsByDirectionId


## [Service](#Mbta.Service)

@docs getService, getServices


### Includes

`Service` does not currently have any relationships to include.


### Filters

@docs filterServicesByIds


## [Shape](#Mbta.Shape)

@docs getShape, getShapes


### Includes

@docs shapeRoute, shapeStops


### Filters

@docs filterShapesByRouteIds, filterShapesByDirectionId


# Stop Data


## [Stop](#Mbta.Stop)

@docs getStop, getStops


### Includes

@docs stopParentStation, stopChildStops, stopRecommendedTransfers, stopFacilities


### Filters

@docs filterStopsByIds, filterStopsByLocationTypes, filterStopsByRouteTypes, filterStopsByRouteIds, filterStopsByDirectionId, filterStopsByLatLng, filterStopsByLatLngWithRadius


## [Facility](#Mbta.Facility)

@docs getFacility, getFacilities


### Includes

@docs facilityStop


### Filters

@docs filterFacilitiesByStopIds, filterFacilitiesByFacilityTypes


## [Live Facility](#Mbta.Live)

@docs getLiveFacility, getLiveFacilities


### Includes

@docs liveFacilityFacility


### Filters

@docs filterLiveFacilitiesByIds


# Alert Data


## [Alert](#Mbta.Alert)

@docs getAlert, getAlerts, streamAlerts


### Includes

@docs alertRoutes, alertTrips, alertStops, alertFacilities


### Filters

@docs filterAlertsByIds, filterAlertsByRouteTypes, filterAlertsByRouteIds, filterAlertsByDirectionId, filterAlertsByTripIds, filterAlertsByStopIds, filterAlertsByFacilities, filterAlertsByActivities, filterAlertsByDatetime, AlertDatetimeFilter, filterAlertsByLifecycles, filterAlertsBySeverities

-}

import AssocList as Dict
import Http
import Iso8601
import Json.Decode as Decode
import JsonApi
import Mbta exposing (..)
import Mbta.Decode
import Mbta.Mixed as Mixed
import RemoteData
import Time
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
    , included : Included
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
                    , filterQueryParameters filters
                    ]
                )

        SameOrigin config ->
            Url.Builder.absolute
                (config.basePath ++ path)
                (List.concat
                    [ config.queryParameters
                    , includeQueryParameter includes
                    , filterQueryParameters filters
                    ]
                )

        CustomHost config ->
            Url.Builder.crossOrigin
                config.host
                (config.basePath ++ path)
                (List.concat
                    [ config.queryParameters
                    , includeQueryParameter includes
                    , filterQueryParameters filters
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
        toMsg_ : Result JsonApi.Error (JsonApi.Document Included resource) -> msg
        toMsg_ =
            Result.mapError jsonApiErrorToApiError >> toMsg

        documentDecoder : JsonApi.DocumentDecoder Included resource
        documentDecoder =
            JsonApi.documentDecoderOne includedDecoder resourceDecoder
    in
    Http.get
        { url = makeUrl host [ path, id ] [] includes
        , expect = JsonApi.expectJsonApi toMsg_ documentDecoder
        }


getList : (ApiResult (List resource) -> msg) -> Host -> JsonApi.ResourceDecoder resource -> String -> List (Include resource) -> List (Filter resource) -> Cmd msg
getList toMsg host resourceDecoder path includes filters =
    let
        toMsg_ : Result JsonApi.Error (JsonApi.Document Included (List resource)) -> msg
        toMsg_ =
            Result.mapError jsonApiErrorToApiError >> toMsg

        documentDecoder : JsonApi.DocumentDecoder Included (List resource)
        documentDecoder =
            JsonApi.documentDecoderMany includedDecoder resourceDecoder
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


{-| The data returned in the includes field of an API call.
Use the getters below to look up a resource by its id
-}
type Included
    = Included Mixed.Mixed


includedDecoder : JsonApi.IncludedDecoder Included
includedDecoder =
    { emptyIncluded = Included Mixed.empty
    , accumulator =
        JsonApi.map
            (\mixedAdd ->
                \(Included mixed) -> Included (mixedAdd mixed)
            )
            Mixed.insert
    }


{-| -}
getIncludedPrediction : PredictionId -> Included -> Maybe Prediction
getIncludedPrediction predictionId (Included mixed) =
    Dict.get predictionId mixed.predictions


{-| -}
getIncludedVehicle : VehicleId -> Included -> Maybe Vehicle
getIncludedVehicle vehicleId (Included mixed) =
    Dict.get vehicleId mixed.vehicles


{-| -}
getIncludedRoute : RouteId -> Included -> Maybe Route
getIncludedRoute routeId (Included mixed) =
    Dict.get routeId mixed.routes


{-| -}
getIncludedRoutePattern : RoutePatternId -> Included -> Maybe RoutePattern
getIncludedRoutePattern routePatternId (Included mixed) =
    Dict.get routePatternId mixed.routePatterns


{-| -}
getIncludedLine : LineId -> Included -> Maybe Line
getIncludedLine lineId (Included mixed) =
    Dict.get lineId mixed.lines


{-| -}
getIncludedSchedule : ScheduleId -> Included -> Maybe Schedule
getIncludedSchedule scheduleId (Included mixed) =
    Dict.get scheduleId mixed.schedules


{-| -}
getIncludedTrip : TripId -> Included -> Maybe Trip
getIncludedTrip tripId (Included mixed) =
    Dict.get tripId mixed.trips


{-| -}
getIncludedService : ServiceId -> Included -> Maybe Service
getIncludedService serviceId (Included mixed) =
    Dict.get serviceId mixed.services


{-| -}
getIncludedShape : ShapeId -> Included -> Maybe Shape
getIncludedShape shapeId (Included mixed) =
    Dict.get shapeId mixed.shapes


{-| -}
getIncludedStop : StopId -> Included -> Maybe Stop
getIncludedStop stopId (Included mixed) =
    Dict.get stopId mixed.stops


{-| -}
getIncludedFacility : FacilityId -> Included -> Maybe Facility
getIncludedFacility facilityId (Included mixed) =
    Dict.get facilityId mixed.facilities


{-| -}
getIncludedLiveFacility : FacilityId -> Included -> Maybe LiveFacility
getIncludedLiveFacility facilityId (Included mixed) =
    Dict.get facilityId mixed.liveFacilities


{-| -}
getIncludedAlert : AlertId -> Included -> Maybe Alert
getIncludedAlert alertId (Included mixed) =
    Dict.get alertId mixed.alerts



-- Filtering


{-| An instruction for the API
It shows up as a query parameter in an api call
-}
type Filter resource
    = Filter (List ( String, List String ))


filterQueryParameters : List (Filter a) -> List Url.Builder.QueryParameter
filterQueryParameters filters =
    List.concatMap
        (\(Filter params) ->
            List.map
                (\( name, values ) ->
                    Url.Builder.string
                        ("filter[" ++ name ++ "]")
                        (String.join "," values)
                )
                params
        )
        filters



-- Streaming


{-| The data from a stream.

Put this in your model.

-}
type StreamData resource
    = StreamData
        { dataField : Mixed.Mixed -> List resource
        , mixed : RemoteData.RemoteData StreamError Mixed.Mixed
        }


{-| TODO explain what each variant means
-}
type StreamError
    = BadOrder String
    | UnrecognizedEvent String


{-| The main resources that you're watching for updates in the stream.
-}
getStreamData : StreamData resource -> RemoteData.RemoteData StreamError (List resource)
getStreamData (StreamData streamData) =
    RemoteData.map streamData.dataField streamData.mixed


{-| Any data that you side loaded by specifying `Include` parameters

The streaming API doesn't separate the main resources from included data,
so the main result will show up in this `Included`, too.

-}
getStreamIncluded : StreamData resource -> RemoteData.RemoteData StreamError Included
getStreamIncluded (StreamData streamData) =
    RemoteData.map Included streamData.mixed


{-| When you get new data coming in through the stream, use this to update the [`StreamData`](#StreamData) in your model.
-}
updateStream : String -> Decode.Value -> StreamData resource -> StreamData resource
updateStream eventString dataJson (StreamData streamData) =
    StreamData
        { streamData
            | mixed = updateStreamMixedResult eventString dataJson streamData.mixed
        }


updateStreamMixedResult : String -> Decode.Value -> RemoteData.RemoteData StreamError Mixed.Mixed -> RemoteData.RemoteData StreamError Mixed.Mixed
updateStreamMixedResult eventString dataJson mixedResult =
    case ( mixedResult, eventString ) of
        ( RemoteData.NotAsked, _ ) ->
            RemoteData.Failure <|
                BadOrder ("event received while streamResult was NotAsked: " ++ eventString)

        ( RemoteData.Loading, "reset" ) ->
            dataJson
                |> streamReset
                |> RemoteData.fromResult

        ( RemoteData.Loading, _ ) ->
            RemoteData.Failure <|
                BadOrder ("first event received was \"" ++ eventString ++ "\" instead of \"reset\"")

        ( RemoteData.Failure e, _ ) ->
            RemoteData.Failure e

        ( RemoteData.Success _, "reset" ) ->
            dataJson
                |> streamReset
                |> RemoteData.fromResult

        ( RemoteData.Success mixed, "add" ) ->
            mixed
                |> streamInsert dataJson
                |> RemoteData.fromResult

        ( RemoteData.Success mixed, "update" ) ->
            mixed
                |> streamInsert dataJson
                |> RemoteData.fromResult

        ( RemoteData.Success mixed, "remove" ) ->
            mixed
                |> streamRemove dataJson
                |> RemoteData.fromResult

        ( RemoteData.Success _, _ ) ->
            RemoteData.Failure <|
                UnrecognizedEvent eventString


streamReset : Decode.Value -> Result StreamError Mixed.Mixed
streamReset dataJson =
    dataJson
        |> Decode.decodeValue (Decode.list Decode.value)
        |> Result.mapError (\decodeError -> Debug.todo "decodeError to streamError")
        |> Result.andThen
            (\resourceJsons ->
                List.foldl
                    (\resourceJson mixedResult ->
                        mixedResult
                            |> Result.andThen
                                (\mixed ->
                                    streamInsert resourceJson mixed
                                )
                    )
                    (Result.Ok Mixed.empty)
                    resourceJsons
            )


streamInsert : Decode.Value -> Mixed.Mixed -> Result StreamError Mixed.Mixed
streamInsert resourceJson mixed =
    resourceJson
        |> JsonApi.decodeResourceValue Mixed.insert
        |> Result.mapError (\resourceError -> Debug.todo "resourceError to streamError")
        |> Result.map (\mixedInserter -> mixedInserter mixed)


streamRemove : Decode.Value -> Mixed.Mixed -> Result StreamError Mixed.Mixed
streamRemove idJson mixed =
    idJson
        |> JsonApi.decodeIdValue Mixed.remove
        |> Result.mapError (\idError -> Debug.todo "idError to streamError")
        |> Result.map (\mixedRemover -> mixedRemover mixed)



-- Realtime Data
-- Prediction


{-| At least one filter (not counting `directionId`) is required
-}
getPredictions : (ApiResult (List Prediction) -> msg) -> Host -> List (Include Prediction) -> List (Filter Prediction) -> Cmd msg
getPredictions toMsg host includes filters =
    getList toMsg host Mbta.Decode.prediction "predictions" includes filters


{-| -}
streamPredictions : Host -> List (Include Prediction) -> List (Filter Prediction) -> ( StreamData Prediction, String )
streamPredictions host includes filters =
    ( StreamData
        { dataField = .predictions >> Dict.values
        , mixed = RemoteData.Loading
        }
    , makeUrl host [ "predictions" ] filters includes
    )


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


{-| -}
filterPredictionsByRouteTypes : List RouteType -> Filter Prediction
filterPredictionsByRouteTypes routeTypes =
    filterByList "route_type" routeTypeToString routeTypes


{-| -}
filterPredictionsByRouteIds : List RouteId -> Filter Prediction
filterPredictionsByRouteIds routeIds =
    filterByList "route" routeIdToString routeIds


{-| -}
filterPredictionsByTripIds : List TripId -> Filter Prediction
filterPredictionsByTripIds tripIds =
    filterByList "trip" tripIdToString tripIds


{-| -}
filterPredictionsByDirectionId : DirectionId -> Filter Prediction
filterPredictionsByDirectionId directionId =
    filterByDirectionId directionId


{-| -}
filterPredictionsByStopIds : List StopId -> Filter Prediction
filterPredictionsByStopIds stopIds =
    filterByList "stop" stopIdToString stopIds


{-| -}
filterPredictionsByLatLng : LatLng -> Filter Prediction
filterPredictionsByLatLng latLng =
    filterByLatLng latLng


{-| -}
filterPredictionsByLatLngWithRadius : LatLng -> Float -> Filter Prediction
filterPredictionsByLatLngWithRadius latLng radius =
    filterByLatLngWithRadius latLng radius



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
streamVehicles : Host -> List (Include Vehicle) -> List (Filter Vehicle) -> ( StreamData Vehicle, String )
streamVehicles host includes filters =
    ( StreamData
        { dataField = .vehicles >> Dict.values
        , mixed = RemoteData.Loading
        }
    , makeUrl host [ "vehicles" ] filters includes
    )


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


{-| -}
filterVehiclesByIds : List VehicleId -> Filter Vehicle
filterVehiclesByIds vehicleIds =
    filterByList "id" (\(VehicleId id) -> id) vehicleIds


{-| -}
filterVehiclesByLabels : List String -> Filter Vehicle
filterVehiclesByLabels labels =
    filterByList "label" identity labels


{-| -}
filterVehiclesByRouteIds : List RouteId -> Filter Vehicle
filterVehiclesByRouteIds routeIds =
    filterByList "route" routeIdToString routeIds


{-| -}
filterVehiclesByRouteTypes : List RouteType -> Filter Vehicle
filterVehiclesByRouteTypes routeTypes =
    filterByList "route_type" routeTypeToString routeTypes


{-| -}
filterVehiclesByDirectionId : DirectionId -> Filter Vehicle
filterVehiclesByDirectionId directionId =
    filterByDirectionId directionId


{-| -}
filterVehiclesByTripIds : List TripId -> Filter Vehicle
filterVehiclesByTripIds tripIds =
    filterByList "trip" tripIdToString tripIds



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


{-| -}
filterRoutesByIds : List RouteId -> Filter Route
filterRoutesByIds routeIds =
    filterByList "id" routeIdToString routeIds


{-| -}
filterRoutesByRouteTypes : List RouteType -> Filter Route
filterRoutesByRouteTypes routeTypes =
    filterByList "type" routeTypeToString routeTypes


{-| -}
filterRoutesByDirectionId : DirectionId -> Filter Route
filterRoutesByDirectionId directionId =
    filterByDirectionId directionId


{-| -}
filterRoutesByStopIds : List StopId -> Filter Route
filterRoutesByStopIds stopIds =
    filterByList "stop" stopIdToString stopIds



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


{-| -}
filterRoutePatternsByIds : List RoutePatternId -> Filter RoutePattern
filterRoutePatternsByIds routePatternIds =
    filterByList "id" routePatternIdToString routePatternIds


{-| -}
filterRoutePatternsByRouteIds : List RouteId -> Filter RoutePattern
filterRoutePatternsByRouteIds routeIds =
    filterByList "route" routeIdToString routeIds


{-| -}
filterRoutePatternsByDirectionId : DirectionId -> Filter RoutePattern
filterRoutePatternsByDirectionId directionId =
    filterByDirectionId directionId



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


{-| -}
filterLinesByIds : List LineId -> Filter Line
filterLinesByIds lineIds =
    filterByList "id" (\(LineId id) -> id) lineIds



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


{-| -}
filterSchedulesByRouteIds : List RouteId -> Filter Schedule
filterSchedulesByRouteIds routeIds =
    filterByList "route" routeIdToString routeIds


{-| -}
filterSchedulesByDirectionId : DirectionId -> Filter Schedule
filterSchedulesByDirectionId directionId =
    filterByDirectionId directionId


{-| -}
filterSchedulesByTripIds : List TripId -> Filter Schedule
filterSchedulesByTripIds tripIds =
    filterByList "trip" tripIdToString tripIds


{-| -}
filterSchedulesByStopSequence : List StopSequenceFilter -> Filter Schedule
filterSchedulesByStopSequence stopSequences =
    let
        stopSequenceToString : StopSequenceFilter -> String
        stopSequenceToString stopSequenceFilter =
            case stopSequenceFilter of
                StopSequence stopSequence ->
                    String.fromInt stopSequence

                First ->
                    "first"

                Last ->
                    "last"
    in
    filterByList "stop_sequence" stopSequenceToString stopSequences


{-| -}
type StopSequenceFilter
    = StopSequence Int
    | First
    | Last


{-| -}
filterSchedulesByStopIds : List StopId -> Filter Schedule
filterSchedulesByStopIds stopIds =
    filterByList "stop" stopIdToString stopIds


{-| -}
filterSchedulesByServiceDate : ServiceDate -> Filter Schedule
filterSchedulesByServiceDate serviceDate =
    filterByOne "date" Mbta.serviceDateToIso8601 serviceDate


{-| -}
filterSchedulesByMinTime : String -> Filter Schedule
filterSchedulesByMinTime minTime =
    filterByOne "min_time" identity minTime


{-| -}
filterSchedulesByMaxTime : String -> Filter Schedule
filterSchedulesByMaxTime maxTime =
    filterByOne "max_time" identity maxTime



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


{-| -}
filterTripsByIds : List TripId -> Filter Trip
filterTripsByIds tripIds =
    filterByList "id" tripIdToString tripIds


{-| -}
filterTripsByNames : List String -> Filter Trip
filterTripsByNames names =
    filterByList "name" identity names


{-| -}
filterTripsByRouteIds : List RouteId -> Filter Trip
filterTripsByRouteIds routeIds =
    filterByList "route" routeIdToString routeIds


{-| -}
filterTripsByRoutePatternIds : List RoutePatternId -> Filter Trip
filterTripsByRoutePatternIds routePatternIds =
    filterByList "route_pattern" routePatternIdToString routePatternIds


{-| -}
filterTripsByDirectionId : DirectionId -> Filter Trip
filterTripsByDirectionId directionId =
    filterByDirectionId directionId



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


{-| -}
filterServicesByIds : List ServiceId -> Filter Service
filterServicesByIds serviceIds =
    filterByList "id" (\(ServiceId id) -> id) serviceIds



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


{-| TODO Must filter by route. How to enforce/ document
-}
filterShapesByRouteIds : List RouteId -> Filter Shape
filterShapesByRouteIds routeIds =
    filterByList "route" routeIdToString routeIds


{-| -}
filterShapesByDirectionId : DirectionId -> Filter Shape
filterShapesByDirectionId directionId =
    filterByDirectionId directionId



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


{-| -}
filterStopsByIds : List StopId -> Filter Stop
filterStopsByIds stopIds =
    filterByList "id" stopIdToString stopIds


{-| -}
filterStopsByLocationTypes : List LocationType -> Filter Stop
filterStopsByLocationTypes locationTypes =
    let
        locationTypeToString : LocationType -> String
        locationTypeToString locationType =
            case locationType of
                LocationType_0_Stop ->
                    "0"

                LocationType_1_Station ->
                    "1"

                LocationType_2_Entrance ->
                    "2"

                LocationType_3_Node ->
                    "3"
    in
    filterByList "location_type" locationTypeToString locationTypes


{-| -}
filterStopsByRouteTypes : List RouteType -> Filter Stop
filterStopsByRouteTypes routeTypes =
    filterByList "route_type" routeTypeToString routeTypes


{-| -}
filterStopsByRouteIds : List RouteId -> Filter Stop
filterStopsByRouteIds routeIds =
    filterByList "route" routeIdToString routeIds


{-| -}
filterStopsByDirectionId : DirectionId -> Filter Stop
filterStopsByDirectionId directionId =
    filterByDirectionId directionId


{-| -}
filterStopsByLatLng : LatLng -> Filter Stop
filterStopsByLatLng latLng =
    filterByLatLng latLng


{-| -}
filterStopsByLatLngWithRadius : LatLng -> Float -> Filter Stop
filterStopsByLatLngWithRadius latLng radius =
    filterByLatLngWithRadius latLng radius



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


{-| -}
filterFacilitiesByStopIds : List StopId -> Filter Facility
filterFacilitiesByStopIds stopIds =
    filterByList "stop" stopIdToString stopIds


{-| -}
filterFacilitiesByFacilityTypes : List FacilityType -> Filter Facility
filterFacilitiesByFacilityTypes facilityTypes =
    filterByList "type" (\(FacilityType facilityType) -> facilityType) facilityTypes



-- LiveFacility


{-| -}
filterLiveFacilitiesByIds : List FacilityId -> Filter LiveFacility
filterLiveFacilitiesByIds facilityIds =
    filterByList "id" facilityIdToString facilityIds



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
streamAlerts : Host -> List (Include Alert) -> List (Filter Alert) -> ( StreamData Alert, String )
streamAlerts host includes filters =
    ( StreamData
        { dataField = .alerts >> Dict.values
        , mixed = RemoteData.Loading
        }
    , makeUrl host [ "alerts" ] filters includes
    )


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


{-| -}
filterAlertsByIds : List AlertId -> Filter Alert
filterAlertsByIds alertIds =
    filterByList "id" (\(AlertId id) -> id) alertIds


{-| -}
filterAlertsByRouteTypes : List RouteType -> Filter Alert
filterAlertsByRouteTypes routeTypes =
    filterByList "route_type" routeTypeToString routeTypes


{-| -}
filterAlertsByRouteIds : List RouteId -> Filter Alert
filterAlertsByRouteIds routeIds =
    filterByList "route" routeIdToString routeIds


{-| -}
filterAlertsByDirectionId : DirectionId -> Filter Alert
filterAlertsByDirectionId directionId =
    filterByDirectionId directionId


{-| -}
filterAlertsByTripIds : List TripId -> Filter Alert
filterAlertsByTripIds tripIds =
    filterByList "trip" tripIdToString tripIds


{-| -}
filterAlertsByStopIds : List StopId -> Filter Alert
filterAlertsByStopIds stopIds =
    filterByList "stop" stopIdToString stopIds


{-| -}
filterAlertsByFacilities : List FacilityId -> Filter Alert
filterAlertsByFacilities facilityIds =
    filterByList "facility" facilityIdToString facilityIds


{-| -}
filterAlertsByActivities : List InformedEntityActivity -> Filter Alert
filterAlertsByActivities activities =
    let
        activityToString : InformedEntityActivity -> String
        activityToString activity =
            case activity of
                Activity_Board ->
                    "BOARD"

                Activity_BringingBike ->
                    "BRINGING_BIKE"

                Activity_Exit ->
                    "EXIT"

                Activity_ParkCar ->
                    "PARK_CAR"

                Activity_Ride ->
                    "RIDE"

                Activity_StoreBike ->
                    "STORE_BIKE"

                Activity_UsingEscalator ->
                    "USING_ESCALATOR"

                Activity_UsingWheelchair ->
                    "USING_WHEELCHAIR"
    in
    filterByList "activity" activityToString activities


{-| -}
filterAlertsByDatetime : AlertDatetimeFilter -> Filter Alert
filterAlertsByDatetime datetime =
    let
        datetimeFilterToString : AlertDatetimeFilter -> String
        datetimeFilterToString datetimeFilter =
            case datetimeFilter of
                Datetime posix ->
                    Iso8601.fromTime posix

                Now ->
                    "NOW"
    in
    filterByOne "datetime" datetimeFilterToString datetime


{-| -}
type AlertDatetimeFilter
    = Datetime Time.Posix
    | Now


{-| -}
filterAlertsByLifecycles : List AlertLifecycle -> Filter Alert
filterAlertsByLifecycles lifecycles =
    let
        lifecycleToString : AlertLifecycle -> String
        lifecycleToString lifecycle =
            case lifecycle of
                Alert_New ->
                    "NEW"

                Alert_Ongoing ->
                    "ONGOING"

                Alert_OngoingUpcoming ->
                    "ONGOING_UPCOMING"

                Alert_Upcoming ->
                    "UPCOMING"
    in
    filterByList "lifecycle" lifecycleToString lifecycles


{-| -}
filterAlertsBySeverities : List Int -> Filter Alert
filterAlertsBySeverities severities =
    filterByList "severity" String.fromInt severities



-- Private functions for building filters


filterByOne : String -> (a -> String) -> a -> Filter b
filterByOne key toString value =
    Filter [ ( key, [ toString value ] ) ]


filterByList : String -> (a -> String) -> List a -> Filter b
filterByList key toString values =
    Filter [ ( key, List.map toString values ) ]


filterByDirectionId : DirectionId -> Filter a
filterByDirectionId directionId =
    let
        directionIdString =
            case directionId of
                D0 ->
                    "0"

                D1 ->
                    "1"
    in
    Filter [ ( "direction_id", [ directionIdString ] ) ]


filterByLatLng : LatLng -> Filter a
filterByLatLng latLng =
    Filter
        [ ( "latitude", [ String.fromFloat latLng.latitude ] )
        , ( "longitude", [ String.fromFloat latLng.longitude ] )
        ]


filterByLatLngWithRadius : LatLng -> Float -> Filter a
filterByLatLngWithRadius latLng radius =
    Filter
        [ ( "latitude", [ String.fromFloat latLng.latitude ] )
        , ( "longitude", [ String.fromFloat latLng.longitude ] )
        , ( "radius", [ String.fromFloat radius ] )
        ]


routeTypeToString : RouteType -> String
routeTypeToString routeType =
    case routeType of
        RouteType_0_LightRail ->
            "0"

        RouteType_1_HeavyRail ->
            "1"

        RouteType_2_CommuterRail ->
            "2"

        RouteType_3_Bus ->
            "3"

        RouteType_4_Ferry ->
            "4"


routeIdToString : RouteId -> String
routeIdToString (RouteId routeId) =
    routeId


routePatternIdToString : RoutePatternId -> String
routePatternIdToString (RoutePatternId routePatternId) =
    routePatternId


tripIdToString : TripId -> String
tripIdToString (TripId tripId) =
    tripId


stopIdToString : StopId -> String
stopIdToString (StopId stopId) =
    stopId


facilityIdToString : FacilityId -> String
facilityIdToString (FacilityId facilityId) =
    facilityId
