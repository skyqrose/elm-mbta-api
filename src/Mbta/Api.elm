module Mbta.Api exposing
    ( Host(..), ApiKey(..), Config
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
        config
        { predictionsFilter
            | routeType = RouteType_2_CommuterRail
            , stop = [ StopId "place-sstat" ]
        }

If you want all results, pass in the empty filter without setting any fields,
though note that some calls require at least one filter to be specified.


# Configuration

@docs Host, ApiKey, Config


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
import Time
import Url.Builder



-- Configuration


{-| Where to send the HTTP requests?

  - `Default`
    <https://api-v3.mbta.com>, MBTA's official API server.
  - `SameOrigin pathPrefix`
    You might want to have all api calls go to your server,
    and then your server can make the api call to the api server and forward the JSON back to the client.
    If you want to have what would normally be `https://api-v3.mbta.com/vehicles` be called to `/api/mbta-forward/vehicles`,
    use a `pathPrefix` of `["api", "mbta-forward"]`
  - `CustomHost urlPrefix`
    Specify another api server, e.g. `Default` is equivalent to `CustomHost "https://api-v3.mbta.com"`

If you use anything except `SameOrigin`, you may need to configure CORS.
-- TODO more specific instructions

-}
type Host
    = Default
    | SameOrigin (List String)
    | CustomHost String


{-| Not required, but recommended. [Sign up for a key.](https://api-v3.mbta.com/register)
-}
type ApiKey
    = NoApiKey
    | ApiKey String


{-| -}
type alias Config =
    { host : Host
    , apiKey : ApiKey
    }


url : Config -> List String -> Filters -> String
url config path filters =
    let
        urlExceptParams : List Url.Builder.QueryParameter -> String
        urlExceptParams =
            case config.host of
                Default ->
                    Url.Builder.crossOrigin "https://api-v3.mbta.com" path

                SameOrigin apiPath ->
                    Url.Builder.absolute (apiPath ++ path)

                CustomHost customHost ->
                    Url.Builder.crossOrigin "https://api-v3.mbta.com" path

        apiKeyQueryParams : List Url.Builder.QueryParameter
        apiKeyQueryParams =
            case config.apiKey of
                NoApiKey ->
                    []

                ApiKey key ->
                    [ Url.Builder.string "api_key" key ]

        filterQueryParams : List Url.Builder.QueryParameter
        filterQueryParams =
            List.map
                (\( key, values ) -> Url.Builder.string key (String.join "," values))
                filters
    in
    urlExceptParams (apiKeyQueryParams ++ filterQueryParams)


getCustomId : (Result Http.Error resource -> msg) -> Config -> JsonApi.Decoder resource -> String -> String -> Cmd msg
getCustomId toMsg config resourceDecoder path id =
    Http.get
        { url = url config [ path, id ] []
        , expect = Http.expectJson toMsg (JsonApi.decoderOne resourceDecoder)
        }


getCustomList : (Result Http.Error (List resource) -> msg) -> Config -> JsonApi.Decoder resource -> String -> Filters -> Cmd msg
getCustomList toMsg config resourceDecoder path filters =
    Http.get
        { url = url config [ path ] filters
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
getVehicle : (Result Http.Error Vehicle -> msg) -> Config -> VehicleId -> Cmd msg
getVehicle toMsg config (VehicleId vehicleId) =
    getCustomId toMsg config Mbta.Decode.vehicle "vehicles" vehicleId


{-| -}
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
getRoute : (Result Http.Error Route -> msg) -> Config -> RouteId -> Cmd msg
getRoute toMsg config (RouteId routeId) =
    getCustomId toMsg config Mbta.Decode.route "routes" routeId


{-| -}
getRoutes : (Result Http.Error (List Route) -> msg) -> Config -> RoutesFilter -> Cmd msg
getRoutes toMsg config filter =
    let
        filters =
            List.concat
                [ filterList "id" (\(RouteId routeId) -> routeId) filter.id
                , filterList "type" routeTypeToString filter.routeType
                , filterDirectionId filter.directionId
                , filterStop filter.stop
                ]
    in
    getCustomList toMsg config Mbta.Decode.route "routes" filters


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
getRoutePattern : (Result Http.Error RoutePattern -> msg) -> Config -> RoutePatternId -> Cmd msg
getRoutePattern toMsg config (RoutePatternId routePatternId) =
    getCustomId toMsg config Mbta.Decode.routePattern "route-patterns" routePatternId


{-| -}
getRoutePatterns : (Result Http.Error (List RoutePattern) -> msg) -> Config -> RoutePatternsFilter -> Cmd msg
getRoutePatterns toMsg config filter =
    let
        filters =
            List.concat
                [ filterList "id" (\(RoutePatternId routePatternId) -> routePatternId) filter.id
                , filterRoute filter.route
                , filterDirectionId filter.directionId
                ]
    in
    getCustomList toMsg config Mbta.Decode.routePattern "route-patterns" filters


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
getLine : (Result Http.Error Line -> msg) -> Config -> LineId -> Cmd msg
getLine toMsg config (LineId lineId) =
    getCustomId toMsg config Mbta.Decode.line "lines" lineId


{-| -}
getLines : (Result Http.Error (List Line) -> msg) -> Config -> LinesFilter -> Cmd msg
getLines toMsg config filter =
    let
        filters =
            List.concat
                [ filterList "id" (\(LineId lineId) -> lineId) filter.id
                ]
    in
    getCustomList toMsg config Mbta.Decode.line "lines" filters


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
getTrip : (Result Http.Error Trip -> msg) -> Config -> TripId -> Cmd msg
getTrip toMsg config (TripId tripId) =
    getCustomId toMsg config Mbta.Decode.trip "trips" tripId


{-| -}
getTrips : (Result Http.Error (List Trip) -> msg) -> Config -> TripsFilter -> Cmd msg
getTrips toMsg config filter =
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
    getCustomList toMsg config Mbta.Decode.trip "trips" filters


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
getService : (Result Http.Error Service -> msg) -> Config -> ServiceId -> Cmd msg
getService toMsg config (ServiceId serviceId) =
    getCustomId toMsg config Mbta.Decode.service "services" serviceId


{-| -}
getServices : (Result Http.Error (List Service) -> msg) -> Config -> ServicesFilter -> Cmd msg
getServices toMsg config filter =
    let
        filters =
            List.concat
                [ filterList "id" (\(ServiceId serviceId) -> serviceId) filter.id
                ]
    in
    getCustomList toMsg config Mbta.Decode.service "services" filters


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
getShape : (Result Http.Error Shape -> msg) -> Config -> ShapeId -> Cmd msg
getShape toMsg config (ShapeId shapeId) =
    getCustomId toMsg config Mbta.Decode.shape "shapes" shapeId


{-| Must filter by route
-}
getShapes : (Result Http.Error (List Shape) -> msg) -> Config -> ShapesFilter -> Cmd msg
getShapes toMsg config filter =
    let
        filters =
            List.concat
                [ filterRoute filter.route
                , filterDirectionId filter.directionId
                ]
    in
    getCustomList toMsg config Mbta.Decode.shape "shapes" filters


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
getStop : (Result Http.Error Stop -> msg) -> Config -> StopId -> Cmd msg
getStop toMsg config (StopId stopId) =
    getCustomId toMsg config Mbta.Decode.stop "stops" stopId


{-| -}
getStops : (Result Http.Error (List Stop) -> msg) -> Config -> StopsFilter -> Cmd msg
getStops toMsg config filter =
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
    getCustomList toMsg config Mbta.Decode.stop "stops" filters


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
getFacility : (Result Http.Error Facility -> msg) -> Config -> FacilityId -> Cmd msg
getFacility toMsg config (FacilityId facilityId) =
    getCustomId toMsg config Mbta.Decode.facility "facilities" facilityId


{-| -}
getFacilities : (Result Http.Error (List Facility) -> msg) -> Config -> FacilitiesFilter -> Cmd msg
getFacilities toMsg config filter =
    let
        filters =
            List.concat
                [ filterStop filter.stop
                , filterList "type" (\(FacilityType facilityType) -> facilityType) filter.facilityType
                ]
    in
    getCustomList toMsg config Mbta.Decode.facility "facilities" filters


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
getLiveFacility : (Result Http.Error LiveFacility -> msg) -> Config -> FacilityId -> Cmd msg
getLiveFacility toMsg config (FacilityId facilityId) =
    getCustomId toMsg config Mbta.Decode.liveFacility "live-facilities" facilityId


{-| -}
getLiveFacilities : (Result Http.Error (List LiveFacility) -> msg) -> Config -> LiveFacilitiesFilter -> Cmd msg
getLiveFacilities toMsg config filter =
    let
        filters =
            List.concat
                [ filterList "id" (\(FacilityId facilityId) -> facilityId) filter.id
                ]
    in
    getCustomList toMsg config Mbta.Decode.liveFacility "live-facilities" filters


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
getAlert : (Result Http.Error Alert -> msg) -> Config -> AlertId -> Cmd msg
getAlert toMsg config (AlertId alertId) =
    getCustomId toMsg config Mbta.Decode.alert "alerts" alertId


{-| -}
getAlerts : (Result Http.Error (List Alert) -> msg) -> Config -> AlertsFilter -> Cmd msg
getAlerts toMsg config filter =
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

        boolToString : Bool -> String
        boolToString bool =
            if bool then
                "true"

            else
                "false"

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
                , filterMaybe "banner" boolToString filter.banner
                , filterMaybe "datetime" datetimeFilterToString filter.datetime
                , filterList "lifecycle" lifecycleToString filter.lifecycle
                , filterList "severity" String.fromInt filter.severity
                ]
    in
    getCustomList toMsg config Mbta.Decode.alert "alerts" filters


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
    , banner : Maybe Bool
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
    , banner = Nothing
    , datetime = Nothing
    , lifecycle = []
    , severity = []
    }
