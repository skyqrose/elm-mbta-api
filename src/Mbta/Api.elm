module Mbta.Api exposing
    ( Host(..)
    , LatLngFilter
    , getPredictions, PredictionsFilter, predictionsFilter
    , getVehicle, getVehicles, VehiclesFilter, vehiclesFilter
    , getRoute, getRoutes, RoutesFilter, routesFilter
    , getRoutePattern, getRoutePatterns, RoutePatternsFilter, routePatternsFilter
    , getLine, getLines, LinesFilter, linesFilter
    , getSchedules, SchedulesFilter, StopSequenceFilter(..), schedulesFilter
    , getTrip, getTrips, TripsFilter, tripsFilter
    , getService, getServices, ServicesFilter, servicesFilter
    , getShape, getShapes, ShapesFilter, shapesFilter
    , getStop, getStops, StopsFilter, stopsFilter
    , getFacility, getFacilities, FacilitiesFilter, facilitiesFilter
    , getLiveFacility, getLiveFacilities, LiveFacilitiesFilter, liveFacilitiesFilter
    , getAlert, getAlerts, AlertsFilter, AlertDatetimeFilter(..), alertsFilter
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


# Util

@docs LatLngFilter


# Realtime Data

@docs getPredictions, PredictionsFilter, predictionsFilter
@docs getVehicle, getVehicles, VehiclesFilter, vehiclesFilter


# Schedule Data

@docs getRoute, getRoutes, RoutesFilter, routesFilter
@docs getRoutePattern, getRoutePatterns, RoutePatternsFilter, routePatternsFilter
@docs getLine, getLines, LinesFilter, linesFilter
@docs getSchedules, SchedulesFilter, StopSequenceFilter, schedulesFilter
@docs getTrip, getTrips, TripsFilter, tripsFilter
@docs getService, getServices, ServicesFilter, servicesFilter
@docs getShape, getShapes, ShapesFilter, shapesFilter


# Stops

@docs getStop, getStops, StopsFilter, stopsFilter
@docs getFacility, getFacilities, FacilitiesFilter, facilitiesFilter
@docs getLiveFacility, getLiveFacilities, LiveFacilitiesFilter, liveFacilitiesFilter


# Alerts

@docs getAlert, getAlerts, AlertsFilter, AlertDatetimeFilter, alertsFilter

-}

import DecodeHelpers
import Http
import Iso8601
import JsonApi
import Mbta exposing (..)
import Mbta.Decode
import Mbta.Include exposing (Include)
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


url : Host -> List String -> Filters -> List (Include resource) -> String
url host path filters includes =
    let
        filterQueryParams : List Url.Builder.QueryParameter
        filterQueryParams =
            List.map
                (\( key, values ) -> Url.Builder.string key (String.join "," values))
                filters
    in
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
                (apiKeyQueryParam ++ Mbta.Include.queryParameter includes ++ filterQueryParams)

        SameOrigin config ->
            Url.Builder.absolute
                (config.basePath ++ path)
                (config.queryParameters ++ Mbta.Include.queryParameter includes ++ filterQueryParams)

        CustomHost config ->
            Url.Builder.crossOrigin
                config.host
                (config.basePath ++ path)
                (config.queryParameters ++ Mbta.Include.queryParameter includes ++ filterQueryParams)


getCustomId : (Result Http.Error resource -> msg) -> Host -> JsonApi.Decoder resource -> String -> List (Include resource) -> String -> Cmd msg
getCustomId toMsg host resourceDecoder path includes id =
    Http.get
        { url = url host [ path, id ] [] includes
        , expect = Http.expectJson toMsg (JsonApi.decoderOne resourceDecoder)
        }


getCustomList : (Result Http.Error (List resource) -> msg) -> Host -> JsonApi.Decoder resource -> String -> List (Include resource) -> Filters -> Cmd msg
getCustomList toMsg host resourceDecoder path includes filters =
    Http.get
        { url = url host [ path ] filters includes
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


filterRouteType : List RouteType -> Filters
filterRouteType routeTypes =
    filterList "route_type" routeTypeToString routeTypes


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


{-| At least one filter (not counting `direcitonId`) is required
-}
getPredictions : (Result Http.Error (List Prediction) -> msg) -> Host -> List (Include Prediction) -> PredictionsFilter -> Cmd msg
getPredictions toMsg host includes filter =
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
    getCustomList toMsg host Mbta.Decode.prediction "predictions" includes filters


{-| -}
type alias PredictionsFilter =
    { latLng : Maybe LatLngFilter
    , directionId : Maybe DirectionId
    , routeType : List RouteType
    , route : List RouteId
    , stop : List StopId
    , trip : List TripId
    }


{-| -}
predictionsFilter : PredictionsFilter
predictionsFilter =
    { latLng = Nothing
    , directionId = Nothing
    , routeType = []
    , route = []
    , stop = []
    , trip = []
    }


{-| -}
getVehicle : (Result Http.Error Vehicle -> msg) -> Host -> List (Include Vehicle) -> VehicleId -> Cmd msg
getVehicle toMsg host includes (VehicleId vehicleId) =
    getCustomId toMsg host Mbta.Decode.vehicle "vehicles" includes vehicleId


{-| -}
getVehicles : (Result Http.Error (List Vehicle) -> msg) -> Host -> List (Include Vehicle) -> VehiclesFilter -> Cmd msg
getVehicles toMsg host includes filter =
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
    getCustomList toMsg host Mbta.Decode.vehicle "vehicles" includes filters


{-| -}
type alias VehiclesFilter =
    { id : List VehicleId
    , trip : List TripId
    , label : List String
    , route : List RouteId
    , directionId : Maybe DirectionId
    , routeType : List RouteType
    }


{-| -}
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


{-| -}
getRoute : (Result Http.Error Route -> msg) -> Host -> List (Include Route) -> RouteId -> Cmd msg
getRoute toMsg host includes (RouteId routeId) =
    getCustomId toMsg host Mbta.Decode.route "routes" includes routeId


{-| -}
getRoutes : (Result Http.Error (List Route) -> msg) -> Host -> List (Include Route) -> RoutesFilter -> Cmd msg
getRoutes toMsg host includes filter =
    let
        filters =
            List.concat
                [ filterList "id" (\(RouteId routeId) -> routeId) filter.id
                , filterList "type" routeTypeToString filter.routeType
                , filterDirectionId filter.directionId
                , filterStop filter.stop
                ]
    in
    getCustomList toMsg host Mbta.Decode.route "routes" includes filters


{-| -}
type alias RoutesFilter =
    { id : List RouteId
    , routeType : List RouteType
    , directionId : Maybe DirectionId
    , stop : List StopId
    }


{-| -}
routesFilter : RoutesFilter
routesFilter =
    { id = []
    , routeType = []
    , directionId = Nothing
    , stop = []
    }


{-| -}
getRoutePattern : (Result Http.Error RoutePattern -> msg) -> Host -> List (Include RoutePattern) -> RoutePatternId -> Cmd msg
getRoutePattern toMsg host includes (RoutePatternId routePatternId) =
    getCustomId toMsg host Mbta.Decode.routePattern "route-patterns" includes routePatternId


{-| -}
getRoutePatterns : (Result Http.Error (List RoutePattern) -> msg) -> Host -> List (Include RoutePattern) -> RoutePatternsFilter -> Cmd msg
getRoutePatterns toMsg host includes filter =
    let
        filters =
            List.concat
                [ filterList "id" (\(RoutePatternId routePatternId) -> routePatternId) filter.id
                , filterRoute filter.route
                , filterDirectionId filter.directionId
                ]
    in
    getCustomList toMsg host Mbta.Decode.routePattern "route-patterns" includes filters


{-| -}
type alias RoutePatternsFilter =
    { id : List RoutePatternId
    , route : List RouteId
    , directionId : Maybe DirectionId
    }


{-| -}
routePatternsFilter : RoutePatternsFilter
routePatternsFilter =
    { id = []
    , route = []
    , directionId = Nothing
    }


{-| -}
getLine : (Result Http.Error Line -> msg) -> Host -> List (Include Line) -> LineId -> Cmd msg
getLine toMsg host includes (LineId lineId) =
    getCustomId toMsg host Mbta.Decode.line "lines" includes lineId


{-| -}
getLines : (Result Http.Error (List Line) -> msg) -> Host -> List (Include Line) -> LinesFilter -> Cmd msg
getLines toMsg host includes filter =
    let
        filters =
            List.concat
                [ filterList "id" (\(LineId lineId) -> lineId) filter.id
                ]
    in
    getCustomList toMsg host Mbta.Decode.line "lines" includes filters


{-| -}
type alias LinesFilter =
    { id : List LineId
    }


{-| -}
linesFilter : LinesFilter
linesFilter =
    { id = []
    }


{-| Requires filtering by at least one of route, stop, or trip.
-}
getSchedules : (Result Http.Error (List Schedule) -> msg) -> Host -> List (Include Schedule) -> SchedulesFilter -> Cmd msg
getSchedules toMsg host includes filter =
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
    getCustomList toMsg host Mbta.Decode.schedule "schedules" includes filters


{-| -}
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


{-| -}
type StopSequenceFilter
    = StopSequence Int
    | First
    | Last


{-| -}
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


{-| -}
getTrip : (Result Http.Error Trip -> msg) -> Host -> List (Include Trip) -> TripId -> Cmd msg
getTrip toMsg host includes (TripId tripId) =
    getCustomId toMsg host Mbta.Decode.trip "trips" includes tripId


{-| -}
getTrips : (Result Http.Error (List Trip) -> msg) -> Host -> List (Include Trip) -> TripsFilter -> Cmd msg
getTrips toMsg host includes filter =
    let
        filters =
            List.concat
                [ filterList "id" (\(TripId tripId) -> tripId) filter.id
                , filterRoute filter.route
                , filterDirectionId filter.directionId
                , filterList "route_pattern" (\(RoutePatternId routePatternId) -> routePatternId) filter.routePattern
                , filterList "name" identity filter.name
                ]
    in
    getCustomList toMsg host Mbta.Decode.trip "trips" includes filters


{-| -}
type alias TripsFilter =
    -- TODO date filter, which didn't work.
    { id : List TripId
    , route : List RouteId
    , directionId : Maybe DirectionId
    , routePattern : List RoutePatternId
    , name : List String
    }


{-| -}
tripsFilter : TripsFilter
tripsFilter =
    { id = []
    , route = []
    , directionId = Nothing
    , routePattern = []
    , name = []
    }


{-| -}
getService : (Result Http.Error Service -> msg) -> Host -> List (Include Service) -> ServiceId -> Cmd msg
getService toMsg host includes (ServiceId serviceId) =
    getCustomId toMsg host Mbta.Decode.service "services" includes serviceId


{-| -}
getServices : (Result Http.Error (List Service) -> msg) -> Host -> List (Include Service) -> ServicesFilter -> Cmd msg
getServices toMsg host includes filter =
    let
        filters =
            List.concat
                [ filterList "id" (\(ServiceId serviceId) -> serviceId) filter.id
                ]
    in
    getCustomList toMsg host Mbta.Decode.service "services" includes filters


{-| -}
type alias ServicesFilter =
    { id : List ServiceId
    }


{-| -}
servicesFilter : ServicesFilter
servicesFilter =
    { id = []
    }


{-| -}
getShape : (Result Http.Error Shape -> msg) -> Host -> List (Include Shape) -> ShapeId -> Cmd msg
getShape toMsg host includes (ShapeId shapeId) =
    getCustomId toMsg host Mbta.Decode.shape "shapes" includes shapeId


{-| Must filter by route
-}
getShapes : (Result Http.Error (List Shape) -> msg) -> Host -> List (Include Shape) -> ShapesFilter -> Cmd msg
getShapes toMsg host includes filter =
    let
        filters =
            List.concat
                [ filterRoute filter.route
                , filterDirectionId filter.directionId
                ]
    in
    getCustomList toMsg host Mbta.Decode.shape "shapes" includes filters


{-| -}
type alias ShapesFilter =
    { route : List RouteId
    , directionId : Maybe DirectionId
    }


{-| Must filter by route
-}
shapesFilter : List RouteId -> ShapesFilter
shapesFilter routes =
    { route = routes
    , directionId = Nothing
    }



-- Stops


{-| -}
getStop : (Result Http.Error Stop -> msg) -> Host -> List (Include Stop) -> StopId -> Cmd msg
getStop toMsg host includes (StopId stopId) =
    getCustomId toMsg host Mbta.Decode.stop "stops" includes stopId


{-| -}
getStops : (Result Http.Error (List Stop) -> msg) -> Host -> List (Include Stop) -> StopsFilter -> Cmd msg
getStops toMsg host includes filter =
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

        filters =
            List.concat
                [ filterList "id" (\(StopId stopId) -> stopId) filter.id
                , filterRouteType filter.routeType
                , filterRoute filter.route
                , filterDirectionId filter.directionId
                , filterList "location_type" locationTypeToString filter.locationType
                , filterLatLng filter.latLng
                ]
    in
    getCustomList toMsg host Mbta.Decode.stop "stops" includes filters


{-| -}
type alias StopsFilter =
    { id : List StopId
    , routeType : List RouteType
    , route : List RouteId
    , directionId : Maybe DirectionId
    , locationType : List LocationType
    , latLng : Maybe LatLngFilter
    }


{-| -}
stopsFilter : StopsFilter
stopsFilter =
    { id = []
    , routeType = []
    , route = []
    , directionId = Nothing
    , locationType = []
    , latLng = Nothing
    }


{-| -}
getFacility : (Result Http.Error Facility -> msg) -> Host -> List (Include Facility) -> FacilityId -> Cmd msg
getFacility toMsg host includes (FacilityId facilityId) =
    getCustomId toMsg host Mbta.Decode.facility "facilities" includes facilityId


{-| -}
getFacilities : (Result Http.Error (List Facility) -> msg) -> Host -> List (Include Facility) -> FacilitiesFilter -> Cmd msg
getFacilities toMsg host includes filter =
    let
        filters =
            List.concat
                [ filterStop filter.stop
                , filterList "type" (\(FacilityType facilityType) -> facilityType) filter.facilityType
                ]
    in
    getCustomList toMsg host Mbta.Decode.facility "facilities" includes filters


{-| -}
type alias FacilitiesFilter =
    { stop : List StopId
    , facilityType : List FacilityType
    }


{-| -}
facilitiesFilter : FacilitiesFilter
facilitiesFilter =
    { stop = []
    , facilityType = []
    }


{-| -}
getLiveFacility : (Result Http.Error LiveFacility -> msg) -> Host -> List (Include LiveFacility) -> FacilityId -> Cmd msg
getLiveFacility toMsg host includes (FacilityId facilityId) =
    getCustomId toMsg host Mbta.Decode.liveFacility "live-facilities" includes facilityId


{-| -}
getLiveFacilities : (Result Http.Error (List LiveFacility) -> msg) -> Host -> List (Include LiveFacility) -> LiveFacilitiesFilter -> Cmd msg
getLiveFacilities toMsg host includes filter =
    let
        filters =
            List.concat
                [ filterList "id" (\(FacilityId facilityId) -> facilityId) filter.id
                ]
    in
    getCustomList toMsg host Mbta.Decode.liveFacility "live-facilities" includes filters


{-| -}
type alias LiveFacilitiesFilter =
    { id : List FacilityId
    }


{-| -}
liveFacilitiesFilter : LiveFacilitiesFilter
liveFacilitiesFilter =
    { id = []
    }



-- Alerts


{-| -}
getAlert : (Result Http.Error Alert -> msg) -> Host -> List (Include Alert) -> AlertId -> Cmd msg
getAlert toMsg host includes (AlertId alertId) =
    getCustomId toMsg host Mbta.Decode.alert "alerts" includes alertId


{-| -}
getAlerts : (Result Http.Error (List Alert) -> msg) -> Host -> List (Include Alert) -> AlertsFilter -> Cmd msg
getAlerts toMsg host includes filter =
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

        datetimeFilterToString : AlertDatetimeFilter -> String
        datetimeFilterToString datetimeFilter =
            case datetimeFilter of
                Datetime posix ->
                    Iso8601.fromTime posix

                Now ->
                    "NOW"

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

        filters =
            List.concat
                [ filterList "id" (\(AlertId alertId) -> alertId) filter.id
                , filterRouteType filter.routeType
                , filterDirectionId filter.directionId
                , filterRoute filter.route
                , filterStop filter.stop
                , filterTrip filter.trip
                , filterList "facility" (\(FacilityId facilityId) -> facilityId) filter.facility
                , filterList "activity" activityToString filter.activity
                , filterMaybe "datetime" datetimeFilterToString filter.datetime
                , filterList "lifecycle" lifecycleToString filter.lifecycle
                , filterList "severity" String.fromInt filter.severity
                ]
    in
    getCustomList toMsg host Mbta.Decode.alert "alerts" includes filters


{-| -}
type alias AlertsFilter =
    { id : List AlertId
    , routeType : List RouteType
    , directionId : Maybe DirectionId
    , route : List RouteId
    , stop : List StopId
    , trip : List TripId
    , facility : List FacilityId
    , activity : List InformedEntityActivity
    , datetime : Maybe AlertDatetimeFilter
    , lifecycle : List AlertLifecycle
    , severity : List Int
    }


{-| -}
type AlertDatetimeFilter
    = Datetime Time.Posix
    | Now


{-| -}
alertsFilter : AlertsFilter
alertsFilter =
    { id = []
    , routeType = []
    , directionId = Nothing
    , route = []
    , stop = []
    , trip = []
    , facility = []
    , activity = []
    , datetime = Nothing
    , lifecycle = []
    , severity = []
    }
