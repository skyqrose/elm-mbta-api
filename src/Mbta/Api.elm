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


getCustomList : (Result Http.Error (List resource) -> msg) -> Config -> JsonApi.Decoder resource -> String -> Filters -> Cmd msg
getCustomList toMsg config resourceDecoder path filters =
    Http.get
        { url = url config [ path ]
        , expect = Http.expectJson toMsg (JsonApi.decoderMany resourceDecoder)
        }



-- Filtering


type alias Filters =
    List ( String, List String )


type alias LatLngFilter =
    { latLng : LatLng
    , radius : Maybe Float
    }


filterLatLng : Maybe LatLngFilter -> Filters
filterLatLng mll =
    case mll of
        Nothing ->
            []

        Just ll ->
            [ ( "latitude", [ String.fromFloat ll.latLng.latitude ] )
            , ( "longitude", [ String.fromFloat ll.latLng.longitude ] )
            ]
                ++ (case ll.radius of
                        Nothing ->
                            []

                        Just radius ->
                            [ ( "radius", [ String.fromFloat radius ] ) ]
                   )


filterDirectionId : Maybe DirectionId -> Filters
filterDirectionId maybeDirectionId =
    let
        toString directionId =
            case directionId of
                D0 ->
                    "0"

                D1 ->
                    "1"
    in
    filterMaybe "direction_id" toString maybeDirectionId


filterRouteType : List RouteType -> Filters
filterRouteType routeTypes =
    let
        toString routeType =
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
    in
    filterList "route_type" toString routeTypes


filterRoute : List RouteId -> Filters
filterRoute routes =
    filterList "route" (\(RouteId routeId) -> routeId) routes


filterStop : List StopId -> Filters
filterStop stops =
    filterList "stop" (\(StopId stopId) -> stopId) stops


filterTrip : List TripId -> Filters
filterTrip trips =
    filterList "trip" (\(TripId tripId) -> tripId) trips


filterMaybe : String -> (filterValue -> String) -> Maybe filterValue -> Filters
filterMaybe key toString filterValue =
    case filterValue of
        Nothing ->
            []

        Just value ->
            [ ( key, [ toString value ] ) ]


filterList : String -> (filterValues -> String) -> List filterValues -> Filters
filterList key toString filterValues =
    case filterValues of
        [] ->
            []

        values ->
            [ ( key, List.map toString values ) ]



-- Realtime Data


getPredictions : (Result Http.Error (List Prediction) -> msg) -> Config -> PredictionsFilter -> Cmd msg
getPredictions toMsg config filter =
    let
        filters =
            List.concat
                [ filterLatLng filter.latLng
                , filterDirectionId filter.directionId
                , filterRouteType filter.routeType
                , filterRoute filter.route
                , filterStop filter.stop
                , filterTrip filter.trip
                ]
    in
    getCustomList toMsg config Mbta.Decode.prediction "predictions" filters


type alias PredictionsFilter =
    { latLng : Maybe LatLngFilter
    , directionId : Maybe DirectionId
    , routeType : List RouteType
    , route : List RouteId
    , stop : List StopId
    , trip : List TripId
    }


predictionsFilter : PredictionsFilter
predictionsFilter =
    { latLng = Nothing
    , directionId = Nothing
    , routeType = []
    , route = []
    , stop = []
    , trip = []
    }


getVehicle : (Result Http.Error Vehicle -> msg) -> Config -> VehicleId -> Cmd msg
getVehicle toMsg config (VehicleId vehicleId) =
    getCustomId toMsg config Mbta.Decode.vehicle "vehicles" vehicleId


getVehicles : (Result Http.Error (List Vehicle) -> msg) -> Config -> VehiclesFilter -> Cmd msg
getVehicles toMsg config filter =
    let
        filters =
            List.concat
                [ filterList "id" (\(VehicleId vehicleId) -> vehicleId) filter.id
                , filterTrip filter.trip
                , filterList "label" identity filter.label
                , filterRoute filter.route
                , filterDirectionId filter.directionId
                , filterRouteType filter.routeType
                ]
    in
    getCustomList toMsg config Mbta.Decode.vehicle "vehicles" filters


type alias VehiclesFilter =
    { id : List VehicleId
    , trip : List TripId
    , label : List String
    , route : List RouteId
    , directionId : Maybe DirectionId
    , routeType : List RouteType
    }


vehiclesFilter : VehiclesFilter
vehiclesFilter =
    { id = []
    , trip = []
    , label = []
    , route = []
    , directionId = Nothing
    , routeType = []
    }



-- Schedule Data


getRoute : (Result Http.Error Route -> msg) -> Config -> RouteId -> Cmd msg
getRoute toMsg config (RouteId routeId) =
    getCustomId toMsg config Mbta.Decode.route "routes" routeId


getRoutes : (Result Http.Error (List Route) -> msg) -> Config -> Cmd msg
getRoutes toMsg config =
    getCustomList toMsg config Mbta.Decode.route "routes" []


getRoutePattern : (Result Http.Error RoutePattern -> msg) -> Config -> RoutePatternId -> Cmd msg
getRoutePattern toMsg config (RoutePatternId routePatternId) =
    getCustomId toMsg config Mbta.Decode.routePattern "route-patterns" routePatternId


getRoutePatterns : (Result Http.Error (List RoutePattern) -> msg) -> Config -> Cmd msg
getRoutePatterns toMsg config =
    getCustomList toMsg config Mbta.Decode.routePattern "route-patterns" []


getLine : (Result Http.Error Line -> msg) -> Config -> LineId -> Cmd msg
getLine toMsg config (LineId lineId) =
    getCustomId toMsg config Mbta.Decode.line "lines" lineId


getLines : (Result Http.Error (List Line) -> msg) -> Config -> Cmd msg
getLines toMsg config =
    getCustomList toMsg config Mbta.Decode.line "lines" []


getSchedules : (Result Http.Error (List Schedule) -> msg) -> Config -> SchedulesFilter -> Cmd msg
getSchedules toMsg config filter =
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

        filters =
            List.concat
                [ filterMaybe "date" (\(ServiceDate serviceDate) -> serviceDate) filter.serviceDate
                , filterDirectionId filter.directionId
                , filterMaybe "min_time" identity filter.minTime
                , filterMaybe "max_time" identity filter.maxTime
                , filterRoute filter.route
                , filterStop filter.stop
                , filterTrip filter.trip
                , filterList "stop_sequence" stopSequenceToString filter.stopSequence
                ]
    in
    getCustomList toMsg config Mbta.Decode.schedule "schedules" filters


type alias SchedulesFilter =
    { serviceDate : Maybe ServiceDate
    , directionId : Maybe DirectionId
    , minTime : Maybe String
    , maxTime : Maybe String
    , route : List RouteId
    , stop : List StopId
    , trip : List TripId
    , stopSequence : List StopSequenceFilter
    }


schedulesFilter : SchedulesFilter
schedulesFilter =
    { serviceDate = Nothing
    , directionId = Nothing
    , minTime = Nothing
    , maxTime = Nothing
    , route = []
    , stop = []
    , trip = []
    , stopSequence = []
    }


type StopSequenceFilter
    = StopSequence Int
    | First
    | Last


getTrip : (Result Http.Error Trip -> msg) -> Config -> TripId -> Cmd msg
getTrip toMsg config (TripId tripId) =
    getCustomId toMsg config Mbta.Decode.trip "trips" tripId


getTrips : (Result Http.Error (List Trip) -> msg) -> Config -> Cmd msg
getTrips toMsg config =
    getCustomList toMsg config Mbta.Decode.trip "trips" []


getService : (Result Http.Error Service -> msg) -> Config -> ServiceId -> Cmd msg
getService toMsg config (ServiceId serviceId) =
    getCustomId toMsg config Mbta.Decode.service "services" serviceId


getServices : (Result Http.Error (List Service) -> msg) -> Config -> Cmd msg
getServices toMsg config =
    getCustomList toMsg config Mbta.Decode.service "services" []


getShape : (Result Http.Error Shape -> msg) -> Config -> ShapeId -> Cmd msg
getShape toMsg config (ShapeId shapeId) =
    getCustomId toMsg config Mbta.Decode.shape "shapes" shapeId


getShapes : (Result Http.Error (List Shape) -> msg) -> Config -> Cmd msg
getShapes toMsg config =
    getCustomList toMsg config Mbta.Decode.shape "shapes" []



-- Stops


getStop : (Result Http.Error Stop -> msg) -> Config -> StopId -> Cmd msg
getStop toMsg config (StopId stopId) =
    getCustomId toMsg config Mbta.Decode.stop "stops" stopId


getStops : (Result Http.Error (List Stop) -> msg) -> Config -> Cmd msg
getStops toMsg config =
    getCustomList toMsg config Mbta.Decode.stop "stops" []


getFacility : (Result Http.Error Facility -> msg) -> Config -> FacilityId -> Cmd msg
getFacility toMsg config (FacilityId facilityId) =
    getCustomId toMsg config Mbta.Decode.facility "facilities" facilityId


getFacilities : (Result Http.Error (List Facility) -> msg) -> Config -> Cmd msg
getFacilities toMsg config =
    getCustomList toMsg config Mbta.Decode.facility "facilities" []


getLiveFacility : (Result Http.Error LiveFacility -> msg) -> Config -> FacilityId -> Cmd msg
getLiveFacility toMsg config (FacilityId facilityId) =
    getCustomId toMsg config Mbta.Decode.liveFacility "live-facilities" facilityId


getLiveFacilities : (Result Http.Error (List LiveFacility) -> msg) -> Config -> Cmd msg
getLiveFacilities toMsg config =
    getCustomList toMsg config Mbta.Decode.liveFacility "live-facilities" []



-- Alerts


getAlert : (Result Http.Error Alert -> msg) -> Config -> AlertId -> Cmd msg
getAlert toMsg config (AlertId alertId) =
    getCustomId toMsg config Mbta.Decode.alert "alerts" alertId


getAlerts : (Result Http.Error (List Alert) -> msg) -> Config -> Cmd msg
getAlerts toMsg config =
    getCustomList toMsg config Mbta.Decode.alert "alerts" []
