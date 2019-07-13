module Mbta.Filter exposing
    ( Filter
    , filterPredictionsByRouteTypes, filterPredictionsByRouteIds, filterPredictionsByTripIds, filterPredictionsByDirectionId, filterPredictionsByStopIds, filterPredictionsByLatLng, filterPredictionsByLatLngWithRadius
    , filterVehiclesByIds, filterVehiclesByLabels, filterVehiclesByRouteIds, filterVehiclesByRouteTypes, filterVehiclesByDirectionId, filterVehiclesByTripIds
    , filterRoutesByIds, filterRoutesByRouteTypes, filterRoutesByDirectionId, filterRoutesByStopIds
    , filterRoutePatternsByIds, filterRoutePatternsByRouteIds, filterRoutePatternsByDirectionId
    , filterLinesByIds
    , filterSchedulesByRouteIds, filterSchedulesByDirectionId, filterSchedulesByTripIds, filterSchedulesByStopSequence, StopSequenceFilter, filterSchedulesByStopIds, filterSchedulesByServiceDate, filterSchedulesByMinTime, filterSchedulesByMaxTime
    , filterTripsByIds, filterTripsByNames, filterTripsByRouteIds, filterTripsByRoutePatternIds, filterTripsByDirectionId
    , filterServicesByIds
    , filterShapesByRouteIds, filterShapesByDirectionId
    , filterStopsByIds, filterStopsByLocationTypes, filterStopsByRouteTypes, filterStopsByRouteIds, filterStopsByDirectionId, filterStopsByLatLng, filterStopsByLatLngWithRadius
    , filterFacilitiesByStopIds, filterFacilitiesByFacilityTypes
    , filterLiveFacilitiesByIds
    , filterAlertsByIds, filterAlertsByRouteTypes, filterAlertsByRouteIds, filterAlertsByDirectionId, filterAlertsByTripIds, filterAlertsByStopIds, filterAlertsByFacilities, filterAlertsByActivities, filterAlertsByDatetime, AlertDatetimeFilter, filterAlertsByLifecycles, filterAlertsBySeverities
    , queryParameters
    )

{-| For filtering the resources returned during an api call

Use it like

    Mbta.Api.getTrips
        ReceiveTrip
        apiConfig
        [ Mbta.Filter.tripsByRouteIds [ redLineId, orangeLineId ]
        , Mbta.Filter.tripsByDirectionId Mbta.D0
        ]
        includes

@docs Filter


## Realtime Data


### [Prediction](#Mbta.Prediction)

For use in [`Mbta.Api.getPredictions`](#Mbta.Api.getPredictions)

@docs filterPredictionsByRouteTypes, filterPredictionsByRouteIds, filterPredictionsByTripIds, filterPredictionsByDirectionId, filterPredictionsByStopIds, filterPredictionsByLatLng, filterPredictionsByLatLngWithRadius


### [Vehicle](#Mbta.Vehicle)

For use in [`Mbta.Api.getVehicles`](#Mbta.Api.getVehicles)

@docs filterVehiclesByIds, filterVehiclesByLabels, filterVehiclesByRouteIds, filterVehiclesByRouteTypes, filterVehiclesByDirectionId, filterVehiclesByTripIds


## Schedule Data


### [Route](#Mbta.Route)

For use in [`Mbta.Api.getRoutes`](#Mbta.Api.getRoutes)

@docs filterRoutesByIds, filterRoutesByRouteTypes, filterRoutesByDirectionId, filterRoutesByStopIds


### [RoutePattern](#Mbta.RoutePattern)

For use in [`Mbta.Api.getRoutePatterns`](#Mbta.Api.getRoutePatterns)

@docs filterRoutePatternsByIds, filterRoutePatternsByRouteIds, filterRoutePatternsByDirectionId


### [Line](#Mbta.Line)

For use in [`Mbta.Api.getLines`](#Mbta.Api.getLines)

@docs filterLinesByIds


### [Schedule](#Mbta.Schedule)

For use in [`Mbta.Api.getSchedules`](#Mbta.Api.getSchedules)

@docs filterSchedulesByRouteIds, filterSchedulesByDirectionId, filterSchedulesByTripIds, filterSchedulesByStopSequence, StopSequenceFilter, filterSchedulesByStopIds, filterSchedulesByServiceDate, filterSchedulesByMinTime, filterSchedulesByMaxTime


### [Trip](#Mbta.Trip)

For use in [`Mbta.Api.getTrips`](#Mbta.Api.getTrips)

@docs filterTripsByIds, filterTripsByNames, filterTripsByRouteIds, filterTripsByRoutePatternIds, filterTripsByDirectionId


### [Service](#Mbta.Service)

For use in [`Mbta.Api.getServices`](#Mbta.Api.getServices)

@docs filterServicesByIds


### [Shape](#Mbta.Shape)

For use in [`Mbta.Api.getShapes`](#Mbta.Api.getShapes)

@docs filterShapesByRouteIds, filterShapesByDirectionId


## Stops


### [Stop](#Mbta.Stop)

For use in [`Mbta.Api.getStops`](#Mbta.Api.getStops)

@docs filterStopsByIds, filterStopsByLocationTypes, filterStopsByRouteTypes, filterStopsByRouteIds, filterStopsByDirectionId, filterStopsByLatLng, filterStopsByLatLngWithRadius


### [Facility](#Mbta.Facility)

For use in [`Mbta.Api.getFacilities`](#Mbta.Api.getFacilities)

@docs filterFacilitiesByStopIds, filterFacilitiesByFacilityTypes


### [LiveFacility](#Mbta.LiveFacility)

For use in [`Mbta.Api.getLiveFacilities`](#Mbta.Api.getLiveFacilities)

@docs filterLiveFacilitiesByIds


## Alerts


### [Alert](#Mbta.Alert)

For use in [`Mbta.Api.getAlerts`](#Mbta.Api.getAlerts)

@docs filterAlertsByIds, filterAlertsByRouteTypes, filterAlertsByRouteIds, filterAlertsByDirectionId, filterAlertsByTripIds, filterAlertsByStopIds, filterAlertsByFacilities, filterAlertsByActivities, filterAlertsByDatetime, AlertDatetimeFilter, filterAlertsByLifecycles, filterAlertsBySeverities


## Internal Use

@docs queryParameters

-}

import Iso8601
import Mbta exposing (..)
import Time
import Url.Builder


{-| An instruction for the API
It shows up as a query parameter in an api call
-}
type Filter resource
    = Filter (List ( String, List String ))


{-| For internal use. You won't need this unless you're constructing your own urls.
-}
queryParameters : List (Filter a) -> List Url.Builder.QueryParameter
queryParameters filters =
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



-- Realtime Data
-- Prediction


{-| -}
filterPredictionsByRouteTypes : List RouteType -> Filter Prediction
filterPredictionsByRouteTypes routeTypes =
    byList "route_type" routeTypeToString routeTypes


{-| -}
filterPredictionsByRouteIds : List RouteId -> Filter Prediction
filterPredictionsByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
filterPredictionsByTripIds : List TripId -> Filter Prediction
filterPredictionsByTripIds tripIds =
    byList "trip" tripIdToString tripIds


{-| -}
filterPredictionsByDirectionId : DirectionId -> Filter Prediction
filterPredictionsByDirectionId directionId =
    byDirectionId directionId


{-| -}
filterPredictionsByStopIds : List StopId -> Filter Prediction
filterPredictionsByStopIds stopIds =
    byList "stop" stopIdToString stopIds


{-| -}
filterPredictionsByLatLng : LatLng -> Filter Prediction
filterPredictionsByLatLng latLng =
    byLatLng latLng


{-| -}
filterPredictionsByLatLngWithRadius : LatLng -> Float -> Filter Prediction
filterPredictionsByLatLngWithRadius latLng radius =
    byLatLngWithRadius latLng radius



-- Vehicle


{-| -}
filterVehiclesByIds : List VehicleId -> Filter Vehicle
filterVehiclesByIds vehicleIds =
    byList "id" (\(VehicleId id) -> id) vehicleIds


{-| -}
filterVehiclesByLabels : List String -> Filter Vehicle
filterVehiclesByLabels labels =
    byList "label" identity labels


{-| -}
filterVehiclesByRouteIds : List RouteId -> Filter Vehicle
filterVehiclesByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
filterVehiclesByRouteTypes : List RouteType -> Filter Vehicle
filterVehiclesByRouteTypes routeTypes =
    byList "route_type" routeTypeToString routeTypes


{-| -}
filterVehiclesByDirectionId : DirectionId -> Filter Vehicle
filterVehiclesByDirectionId directionId =
    byDirectionId directionId


{-| -}
filterVehiclesByTripIds : List TripId -> Filter Vehicle
filterVehiclesByTripIds tripIds =
    byList "trip" tripIdToString tripIds



-- Schedule Data
-- Route


{-| -}
filterRoutesByIds : List RouteId -> Filter Route
filterRoutesByIds routeIds =
    byList "id" routeIdToString routeIds


{-| -}
filterRoutesByRouteTypes : List RouteType -> Filter Route
filterRoutesByRouteTypes routeTypes =
    byList "type" routeTypeToString routeTypes


{-| -}
filterRoutesByDirectionId : DirectionId -> Filter Route
filterRoutesByDirectionId directionId =
    byDirectionId directionId


{-| -}
filterRoutesByStopIds : List StopId -> Filter Route
filterRoutesByStopIds stopIds =
    byList "stop" stopIdToString stopIds



-- RoutePattern


{-| -}
filterRoutePatternsByIds : List RoutePatternId -> Filter RoutePattern
filterRoutePatternsByIds routePatternIds =
    byList "id" routePatternIdToString routePatternIds


{-| -}
filterRoutePatternsByRouteIds : List RouteId -> Filter RoutePattern
filterRoutePatternsByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
filterRoutePatternsByDirectionId : DirectionId -> Filter RoutePattern
filterRoutePatternsByDirectionId directionId =
    byDirectionId directionId



-- Line


{-| -}
filterLinesByIds : List LineId -> Filter Line
filterLinesByIds lineIds =
    byList "id" (\(LineId id) -> id) lineIds



-- Schedule


{-| -}
filterSchedulesByRouteIds : List RouteId -> Filter Schedule
filterSchedulesByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
filterSchedulesByDirectionId : DirectionId -> Filter Schedule
filterSchedulesByDirectionId directionId =
    byDirectionId directionId


{-| -}
filterSchedulesByTripIds : List TripId -> Filter Schedule
filterSchedulesByTripIds tripIds =
    byList "trip" tripIdToString tripIds


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
    byList "stop_sequence" stopSequenceToString stopSequences


{-| -}
type StopSequenceFilter
    = StopSequence Int
    | First
    | Last


{-| -}
filterSchedulesByStopIds : List StopId -> Filter Schedule
filterSchedulesByStopIds stopIds =
    byList "stop" stopIdToString stopIds


{-| -}
filterSchedulesByServiceDate : ServiceDate -> Filter Schedule
filterSchedulesByServiceDate serviceDate =
    byOne "date" (\(ServiceDate s) -> s) serviceDate


{-| -}
filterSchedulesByMinTime : String -> Filter Schedule
filterSchedulesByMinTime minTime =
    byOne "min_time" identity minTime


{-| -}
filterSchedulesByMaxTime : String -> Filter Schedule
filterSchedulesByMaxTime maxTime =
    byOne "max_time" identity maxTime



-- Trip


{-| -}
filterTripsByIds : List TripId -> Filter Trip
filterTripsByIds tripIds =
    byList "id" tripIdToString tripIds


{-| -}
filterTripsByNames : List String -> Filter Trip
filterTripsByNames names =
    byList "name" identity names


{-| -}
filterTripsByRouteIds : List RouteId -> Filter Trip
filterTripsByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
filterTripsByRoutePatternIds : List RoutePatternId -> Filter Trip
filterTripsByRoutePatternIds routePatternIds =
    byList "route_pattern" routePatternIdToString routePatternIds


{-| -}
filterTripsByDirectionId : DirectionId -> Filter Trip
filterTripsByDirectionId directionId =
    byDirectionId directionId



-- Service


{-| -}
filterServicesByIds : List ServiceId -> Filter Service
filterServicesByIds serviceIds =
    byList "id" (\(ServiceId id) -> id) serviceIds



-- Shape


{-| TODO Must filter by route. How to enforce/ document
-}
filterShapesByRouteIds : List RouteId -> Filter Shape
filterShapesByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
filterShapesByDirectionId : DirectionId -> Filter Shape
filterShapesByDirectionId directionId =
    byDirectionId directionId



-- Stops
-- Stop


{-| -}
filterStopsByIds : List StopId -> Filter Stop
filterStopsByIds stopIds =
    byList "id" stopIdToString stopIds


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
    byList "location_type" locationTypeToString locationTypes


{-| -}
filterStopsByRouteTypes : List RouteType -> Filter Stop
filterStopsByRouteTypes routeTypes =
    byList "route_type" routeTypeToString routeTypes


{-| -}
filterStopsByRouteIds : List RouteId -> Filter Stop
filterStopsByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
filterStopsByDirectionId : DirectionId -> Filter Stop
filterStopsByDirectionId directionId =
    byDirectionId directionId


{-| -}
filterStopsByLatLng : LatLng -> Filter Stop
filterStopsByLatLng latLng =
    byLatLng latLng


{-| -}
filterStopsByLatLngWithRadius : LatLng -> Float -> Filter Stop
filterStopsByLatLngWithRadius latLng radius =
    byLatLngWithRadius latLng radius



-- Facility


{-| -}
filterFacilitiesByStopIds : List StopId -> Filter Facility
filterFacilitiesByStopIds stopIds =
    byList "stop" stopIdToString stopIds


{-| -}
filterFacilitiesByFacilityTypes : List FacilityType -> Filter Facility
filterFacilitiesByFacilityTypes facilityTypes =
    byList "type" (\(FacilityType facilityType) -> facilityType) facilityTypes



-- LiveFacility


{-| -}
filterLiveFacilitiesByIds : List FacilityId -> Filter LiveFacility
filterLiveFacilitiesByIds facilityIds =
    byList "id" facilityIdToString facilityIds



-- Alerts
-- Alert


{-| -}
filterAlertsByIds : List AlertId -> Filter Alert
filterAlertsByIds alertIds =
    byList "id" (\(AlertId id) -> id) alertIds


{-| -}
filterAlertsByRouteTypes : List RouteType -> Filter Alert
filterAlertsByRouteTypes routeTypes =
    byList "route_type" routeTypeToString routeTypes


{-| -}
filterAlertsByRouteIds : List RouteId -> Filter Alert
filterAlertsByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
filterAlertsByDirectionId : DirectionId -> Filter Alert
filterAlertsByDirectionId directionId =
    byDirectionId directionId


{-| -}
filterAlertsByTripIds : List TripId -> Filter Alert
filterAlertsByTripIds tripIds =
    byList "trip" tripIdToString tripIds


{-| -}
filterAlertsByStopIds : List StopId -> Filter Alert
filterAlertsByStopIds stopIds =
    byList "stop" stopIdToString stopIds


{-| -}
filterAlertsByFacilities : List FacilityId -> Filter Alert
filterAlertsByFacilities facilityIds =
    byList "facility" facilityIdToString facilityIds


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
    byList "activity" activityToString activities


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
    byOne "datetime" datetimeFilterToString datetime


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
    byList "lifecycle" lifecycleToString lifecycles


{-| -}
filterAlertsBySeverities : List Int -> Filter Alert
filterAlertsBySeverities severities =
    byList "severity" String.fromInt severities



-- Util


byOne : String -> (a -> String) -> a -> Filter b
byOne key toString value =
    Filter [ ( key, [ toString value ] ) ]


byList : String -> (a -> String) -> List a -> Filter b
byList key toString values =
    Filter [ ( key, List.map toString values ) ]


byDirectionId : DirectionId -> Filter a
byDirectionId directionId =
    let
        directionIdString =
            case directionId of
                D0 ->
                    "0"

                D1 ->
                    "1"
    in
    Filter [ ( "direction_id", [ directionIdString ] ) ]


byLatLng : LatLng -> Filter a
byLatLng latLng =
    Filter
        [ ( "latitude", [ String.fromFloat latLng.latitude ] )
        , ( "longitude", [ String.fromFloat latLng.longitude ] )
        ]


byLatLngWithRadius : LatLng -> Float -> Filter a
byLatLngWithRadius latLng radius =
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
