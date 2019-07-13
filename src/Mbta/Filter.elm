module Mbta.Filter exposing
    ( Filter
    , predictionsByRouteTypes, predictionsByRouteIds, predictionsByTripIds, predictionsByDirectionId, predictionsByStopIds, predictionsByLatLng, predictionsByLatLngWithRadius
    , vehiclesByIds, vehiclesByLabels, vehiclesByRouteIds, vehiclesByRouteTypes, vehiclesByDirectionId, vehiclesByTripIds
    , routesByIds, routesByRouteTypes, routesByDirectionId, routesByStopIds
    , routePatternsByIds, routePatternsByRouteIds, routePatternsByDirectionId
    , linesByIds
    , schedulesByRouteIds, schedulesByDirectionId, schedulesByTripIds, schedulesByStopSequence, StopSequenceFilter, schedulesByStopIds, schedulesByServiceDate, schedulesByMinTime, schedulesByMaxTime
    , tripsByIds, tripsByNames, tripsByRouteIds, tripsByRoutePatternIds, tripsByDirectionId
    , servicesByIds
    , shapesByRouteIds, shapesByDirectionId
    , stopsByIds, stopsByLocationTypes, stopsByRouteTypes, stopsByRouteIds, stopsByDirectionId, stopsByLatLng, stopsByLatLngWithRadius
    , facilitiesByStopIds, facilitiesByFacilityTypes
    , liveFacilitiesByIds
    , alertsByIds, alertsByRouteTypes, alertsByRouteIds, alertsByDirectionId, alertsByTripIds, alertsByStopIds, alertsByFacilities, alertsByActivities, alertsByDatetime, AlertDatetimeFilter, alertsByLifecycles, alertsBySeverities
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

@docs predictionsByRouteTypes, predictionsByRouteIds, predictionsByTripIds, predictionsByDirectionId, predictionsByStopIds, predictionsByLatLng, predictionsByLatLngWithRadius


### [Vehicle](#Mbta.Vehicle)

For use in [`Mbta.Api.getVehicles`](#Mbta.Api.getVehicles)

@docs vehiclesByIds, vehiclesByLabels, vehiclesByRouteIds, vehiclesByRouteTypes, vehiclesByDirectionId, vehiclesByTripIds


## Schedule Data


### [Route](#Mbta.Route)

For use in [`Mbta.Api.getRoutes`](#Mbta.Api.getRoutes)

@docs routesByIds, routesByRouteTypes, routesByDirectionId, routesByStopIds


### [RoutePattern](#Mbta.RoutePattern)

For use in [`Mbta.Api.getRoutePatterns`](#Mbta.Api.getRoutePatterns)

@docs routePatternsByIds, routePatternsByRouteIds, routePatternsByDirectionId


### [Line](#Mbta.Line)

For use in [`Mbta.Api.getLines`](#Mbta.Api.getLines)

@docs linesByIds


### [Schedule](#Mbta.Schedule)

For use in [`Mbta.Api.getSchedules`](#Mbta.Api.getSchedules)

@docs schedulesByRouteIds, schedulesByDirectionId, schedulesByTripIds, schedulesByStopSequence, StopSequenceFilter, schedulesByStopIds, schedulesByServiceDate, schedulesByMinTime, schedulesByMaxTime


### [Trip](#Mbta.Trip)

For use in [`Mbta.Api.getTrips`](#Mbta.Api.getTrips)

@docs tripsByIds, tripsByNames, tripsByRouteIds, tripsByRoutePatternIds, tripsByDirectionId


### [Service](#Mbta.Service)

For use in [`Mbta.Api.getServices`](#Mbta.Api.getServices)

@docs servicesByIds


### [Shape](#Mbta.Shape)

For use in [`Mbta.Api.getShapes`](#Mbta.Api.getShapes)

@docs shapesByRouteIds, shapesByDirectionId


## Stops


### [Stop](#Mbta.Stop)

For use in [`Mbta.Api.getStops`](#Mbta.Api.getStops)

@docs stopsByIds, stopsByLocationTypes, stopsByRouteTypes, stopsByRouteIds, stopsByDirectionId, stopsByLatLng, stopsByLatLngWithRadius


### [Facility](#Mbta.Facility)

For use in [`Mbta.Api.getFacilities`](#Mbta.Api.getFacilities)

@docs facilitiesByStopIds, facilitiesByFacilityTypes


### [LiveFacility](#Mbta.LiveFacility)

For use in [`Mbta.Api.getLiveFacilities`](#Mbta.Api.getLiveFacilities)

@docs liveFacilitiesByIds


## Alerts


### [Alert](#Mbta.Alert)

For use in [`Mbta.Api.getAlerts`](#Mbta.Api.getAlerts)

@docs alertsByIds, alertsByRouteTypes, alertsByRouteIds, alertsByDirectionId, alertsByTripIds, alertsByStopIds, alertsByFacilities, alertsByActivities, alertsByDatetime, AlertDatetimeFilter, alertsByLifecycles, alertsBySeverities


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
predictionsByRouteTypes : List RouteType -> Filter Prediction
predictionsByRouteTypes routeTypes =
    byList "route_type" routeTypeToString routeTypes


{-| -}
predictionsByRouteIds : List RouteId -> Filter Prediction
predictionsByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
predictionsByTripIds : List TripId -> Filter Prediction
predictionsByTripIds tripIds =
    byList "trip" tripIdToString tripIds


{-| -}
predictionsByDirectionId : DirectionId -> Filter Prediction
predictionsByDirectionId directionId =
    byDirectionId directionId


{-| -}
predictionsByStopIds : List StopId -> Filter Prediction
predictionsByStopIds stopIds =
    byList "stop" stopIdToString stopIds


{-| -}
predictionsByLatLng : LatLng -> Filter Prediction
predictionsByLatLng latLng =
    byLatLng latLng


{-| -}
predictionsByLatLngWithRadius : LatLng -> Float -> Filter Prediction
predictionsByLatLngWithRadius latLng radius =
    byLatLngWithRadius latLng radius



-- Vehicle


{-| -}
vehiclesByIds : List VehicleId -> Filter Vehicle
vehiclesByIds vehicleIds =
    byList "id" (\(VehicleId id) -> id) vehicleIds


{-| -}
vehiclesByLabels : List String -> Filter Vehicle
vehiclesByLabels labels =
    byList "label" identity labels


{-| -}
vehiclesByRouteIds : List RouteId -> Filter Vehicle
vehiclesByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
vehiclesByRouteTypes : List RouteType -> Filter Vehicle
vehiclesByRouteTypes routeTypes =
    byList "route_type" routeTypeToString routeTypes


{-| -}
vehiclesByDirectionId : DirectionId -> Filter Vehicle
vehiclesByDirectionId directionId =
    byDirectionId directionId


{-| -}
vehiclesByTripIds : List TripId -> Filter Vehicle
vehiclesByTripIds tripIds =
    byList "trip" tripIdToString tripIds



-- Schedule Data
-- Route


{-| -}
routesByIds : List RouteId -> Filter Route
routesByIds routeIds =
    byList "id" routeIdToString routeIds


{-| -}
routesByRouteTypes : List RouteType -> Filter Route
routesByRouteTypes routeTypes =
    byList "type" routeTypeToString routeTypes


{-| -}
routesByDirectionId : DirectionId -> Filter Route
routesByDirectionId directionId =
    byDirectionId directionId


{-| -}
routesByStopIds : List StopId -> Filter Route
routesByStopIds stopIds =
    byList "stop" stopIdToString stopIds



-- RoutePattern


{-| -}
routePatternsByIds : List RoutePatternId -> Filter RoutePattern
routePatternsByIds routePatternIds =
    byList "id" routePatternIdToString routePatternIds


{-| -}
routePatternsByRouteIds : List RouteId -> Filter RoutePattern
routePatternsByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
routePatternsByDirectionId : DirectionId -> Filter RoutePattern
routePatternsByDirectionId directionId =
    byDirectionId directionId



-- Line


{-| -}
linesByIds : List LineId -> Filter Line
linesByIds lineIds =
    byList "id" (\(LineId id) -> id) lineIds



-- Schedule


{-| -}
schedulesByRouteIds : List RouteId -> Filter Schedule
schedulesByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
schedulesByDirectionId : DirectionId -> Filter Schedule
schedulesByDirectionId directionId =
    byDirectionId directionId


{-| -}
schedulesByTripIds : List TripId -> Filter Schedule
schedulesByTripIds tripIds =
    byList "trip" tripIdToString tripIds


{-| -}
schedulesByStopSequence : List StopSequenceFilter -> Filter Schedule
schedulesByStopSequence stopSequences =
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
schedulesByStopIds : List StopId -> Filter Schedule
schedulesByStopIds stopIds =
    byList "stop" stopIdToString stopIds


{-| -}
schedulesByServiceDate : ServiceDate -> Filter Schedule
schedulesByServiceDate serviceDate =
    byOne "date" (\(ServiceDate s) -> s) serviceDate


{-| -}
schedulesByMinTime : String -> Filter Schedule
schedulesByMinTime minTime =
    byOne "min_time" identity minTime


{-| -}
schedulesByMaxTime : String -> Filter Schedule
schedulesByMaxTime maxTime =
    byOne "max_time" identity maxTime



-- Trip


{-| -}
tripsByIds : List TripId -> Filter Trip
tripsByIds tripIds =
    byList "id" tripIdToString tripIds


{-| -}
tripsByNames : List String -> Filter Trip
tripsByNames names =
    byList "name" identity names


{-| -}
tripsByRouteIds : List RouteId -> Filter Trip
tripsByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
tripsByRoutePatternIds : List RoutePatternId -> Filter Trip
tripsByRoutePatternIds routePatternIds =
    byList "route_pattern" routePatternIdToString routePatternIds


{-| -}
tripsByDirectionId : DirectionId -> Filter Trip
tripsByDirectionId directionId =
    byDirectionId directionId



-- Service


{-| -}
servicesByIds : List ServiceId -> Filter Service
servicesByIds serviceIds =
    byList "id" (\(ServiceId id) -> id) serviceIds



-- Shape


{-| TODO Must filter by route. How to enforce/ document
-}
shapesByRouteIds : List RouteId -> Filter Shape
shapesByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
shapesByDirectionId : DirectionId -> Filter Shape
shapesByDirectionId directionId =
    byDirectionId directionId



-- Stops
-- Stop


{-| -}
stopsByIds : List StopId -> Filter Stop
stopsByIds stopIds =
    byList "id" stopIdToString stopIds


{-| -}
stopsByLocationTypes : List LocationType -> Filter Stop
stopsByLocationTypes locationTypes =
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
stopsByRouteTypes : List RouteType -> Filter Stop
stopsByRouteTypes routeTypes =
    byList "route_type" routeTypeToString routeTypes


{-| -}
stopsByRouteIds : List RouteId -> Filter Stop
stopsByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
stopsByDirectionId : DirectionId -> Filter Stop
stopsByDirectionId directionId =
    byDirectionId directionId


{-| -}
stopsByLatLng : LatLng -> Filter Stop
stopsByLatLng latLng =
    byLatLng latLng


{-| -}
stopsByLatLngWithRadius : LatLng -> Float -> Filter Stop
stopsByLatLngWithRadius latLng radius =
    byLatLngWithRadius latLng radius



-- Facility


{-| -}
facilitiesByStopIds : List StopId -> Filter Facility
facilitiesByStopIds stopIds =
    byList "stop" stopIdToString stopIds


{-| -}
facilitiesByFacilityTypes : List FacilityType -> Filter Facility
facilitiesByFacilityTypes facilityTypes =
    byList "type" (\(FacilityType facilityType) -> facilityType) facilityTypes



-- LiveFacility


{-| -}
liveFacilitiesByIds : List FacilityId -> Filter LiveFacility
liveFacilitiesByIds facilityIds =
    byList "id" facilityIdToString facilityIds



-- Alerts
-- Alert


{-| -}
alertsByIds : List AlertId -> Filter Alert
alertsByIds alertIds =
    byList "id" (\(AlertId id) -> id) alertIds


{-| -}
alertsByRouteTypes : List RouteType -> Filter Alert
alertsByRouteTypes routeTypes =
    byList "route_type" routeTypeToString routeTypes


{-| -}
alertsByRouteIds : List RouteId -> Filter Alert
alertsByRouteIds routeIds =
    byList "route" routeIdToString routeIds


{-| -}
alertsByDirectionId : DirectionId -> Filter Alert
alertsByDirectionId directionId =
    byDirectionId directionId


{-| -}
alertsByTripIds : List TripId -> Filter Alert
alertsByTripIds tripIds =
    byList "trip" tripIdToString tripIds


{-| -}
alertsByStopIds : List StopId -> Filter Alert
alertsByStopIds stopIds =
    byList "stop" stopIdToString stopIds


{-| -}
alertsByFacilities : List FacilityId -> Filter Alert
alertsByFacilities facilityIds =
    byList "facility" facilityIdToString facilityIds


{-| -}
alertsByActivities : List InformedEntityActivity -> Filter Alert
alertsByActivities activities =
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
alertsByDatetime : AlertDatetimeFilter -> Filter Alert
alertsByDatetime datetime =
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
alertsByLifecycles : List AlertLifecycle -> Filter Alert
alertsByLifecycles lifecycles =
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
alertsBySeverities : List Int -> Filter Alert
alertsBySeverities severities =
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
