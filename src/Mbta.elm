module Mbta exposing
    ( LatLng, DirectionId(..), WheelchairAccessible(..)
    , PredictionId(..), Prediction, PredictionScheduleRelationship(..)
    , VehicleId(..), Vehicle, CurrentStatus(..)
    , RouteType(..), RouteId(..), Route, RouteDirections, RouteDirection
    , RoutePatternId(..), RoutePattern, RoutePatternTypicality(..)
    , LineId(..), Line, ScheduleId(..)
    , Schedule, StopSequence(..), PickupDropOffType(..)
    , TripId(..), Trip, BikesAllowed(..), BlockId(..)
    , ServiceId(..), Service, ServiceDate, serviceDateFromIso8601, serviceDateToIso8601, ServiceType(..), ServiceTypicality(..), ChangedDate
    , ShapeId(..), Shape
    , StopId(..), Stop(..), Stop_Stop, Stop_Station, Stop_Entrance, Stop_Node, stopId, stopName, stopDescription, stopWheelchairAccessible, stopLatLng, stopParentStation, StopType(..), stopType
    , FacilityId(..), Facility, LiveFacility, FacilityType(..), FacilityProperties, FacilityPropertyValue(..)
    , AlertId(..), Alert, AlertLifecycle(..), ActivePeriod, InformedEntity, InformedEntityActivity(..)
    )

{-| The types for all data coming from the MBTA API

To avoid duplicating the [official MBTA API docs](swagger),
this documentation does not describe the meaning of this data.
It just describes any important differences between this library and the API.

The [MBTA GTFS docs](gtfs-mbta) may also be useful for describing what data means,
though there's less of a direct correspondence between this library and the GTFS format.

Names were generally kept consistent with the API,
though they were changed in some places to make them clearer.

[swagger][https://api-v3.mbta.com/docs/swagger/index.html#/Vehicle/ApiWeb_VehicleController_index]
[gtfs-mbta][https://github.com/mbta/gtfs-documentation/blob/master/reference/gtfs.md]


# Util

@docs LatLng, DirectionId, WheelchairAccessible


# Realtime Data

@docs PredictionId, Prediction, PredictionScheduleRelationship
@docs VehicleId, Vehicle, CurrentStatus


# Schedule Data

@docs RouteType, RouteId, Route, RouteDirections, RouteDirection
@docs RoutePatternId, RoutePattern, RoutePatternTypicality
@docs LineId, Line, ScheduleId
@docs Schedule, StopSequence, PickupDropOffType
@docs TripId, Trip, BikesAllowed, BlockId
@docs ServiceId, Service, ServiceDate, serviceDateFromIso8601, serviceDateToIso8601, ServiceType, ServiceTypicality, ChangedDate
@docs ShapeId, Shape


# Stop Data

@docs StopId, Stop, Stop_Stop, Stop_Station, Stop_Entrance, Stop_Node, stopId, stopName, stopDescription, stopWheelchairAccessible, stopLatLng, stopParentStation, StopType, stopType
@docs FacilityId, Facility, LiveFacility, FacilityType, FacilityProperties, FacilityPropertyValue


# Alert Data

@docs AlertId, Alert, AlertLifecycle, ActivePeriod, InformedEntity, InformedEntityActivity

-}

import Color
import Dict
import Time



-- Util


{-| -}
type alias LatLng =
    { latitude : Float
    , longitude : Float
    }


{-| Throughout the MBTA API and GTFS, these are ints, either `0` or `1`.
-}
type DirectionId
    = D0
    | D1


{-| Used for both the `wheelchair_boarding` attribute on [`Stop`](#Stop) and the `wheelchair_accessible` attribute on [`Trip`](#Trip)
-}
type WheelchairAccessible
    = Accessible_0_NoInformation
    | Accessible_1_Accessible
    | Accessible_2_Inaccessible



-- Realtime Data


{-| -}
type PredictionId
    = PredictionId String


{-| In the official docs, `stopSequence` is listed as nullable, but it's always there.
-}
type alias Prediction =
    { id : PredictionId
    , routeId : RouteId
    , tripId : TripId
    , stopId : StopId
    , stopSequence : StopSequence
    , scheduleId : Maybe ScheduleId
    , vehicleId : Maybe VehicleId
    , alertIds : List AlertId
    , arrivalTime : Maybe Time.Posix
    , departureTime : Maybe Time.Posix
    , status : Maybe String
    , directionId : DirectionId
    , scheduleRelationship : PredictionScheduleRelationship
    }


{-| In the MBTA API, this attribute is optional, and `null` represents a scheduled trip.
-}
type PredictionScheduleRelationship
    = ScheduleRelationship_Scheduled
    | ScheduleRelationship_Added
    | ScheduleRelationship_Cancelled
    | ScheduleRelationship_NoData
    | ScheduleRelationship_Skipped
    | ScheduleRelationship_Unscheduled


{-| -}
type VehicleId
    = VehicleId String


{-| -}
type alias Vehicle =
    { id : VehicleId
    , label : String
    , routeId : RouteId
    , directionId : DirectionId
    , tripId : TripId
    , stopId : StopId
    , stopSequence : StopSequence
    , currentStatus : CurrentStatus
    , latLng : LatLng
    , speed : Maybe Float
    , bearing : Int
    , updatedAt : Time.Posix
    }


{-| -}
type CurrentStatus
    = IncomingAt
    | StoppedAt
    | InTransitTo



-- Schedule Data


{-| -}
type RouteType
    = RouteType_0_LightRail
    | RouteType_1_HeavyRail
    | RouteType_2_CommuterRail
    | RouteType_3_Bus
    | RouteType_4_Ferry


{-| -}
type RouteId
    = RouteId String


{-| -}
type alias Route =
    { id : RouteId
    , routeType : RouteType
    , shortName : String
    , longName : String
    , description : String
    , fareClass : String
    , directions : Maybe RouteDirections
    , sortOrder : Int
    , textColor : Color.Color
    , color : Color.Color
    }


{-| The keys correspond to `D0` and `D1`, the cases of [`DirectionId`](#DirectionId)
-}
type alias RouteDirections =
    { d0 : RouteDirection
    , d1 : RouteDirection
    }


{-| -}
type alias RouteDirection =
    { name : String
    , destination : String
    }


{-| -}
type RoutePatternId
    = RoutePatternId String


{-| -}
type alias RoutePattern =
    { id : RoutePatternId
    , routeId : RouteId
    , directionId : DirectionId
    , name : String
    , typicality : RoutePatternTypicality
    , timeDesc : Maybe String
    , sortOrder : Int
    , representativeTripId : TripId
    }


{-| -}
type RoutePatternTypicality
    = RoutePatternTypicality_0_NotDefined
    | RoutePatternTypicality_1_Typical
    | RoutePatternTypicality_2_Deviation
    | RoutePatternTypicality_3_Atypical
    | RoutePatternTypicality_4_Diversion


{-| -}
type LineId
    = LineId String


{-| -}
type alias Line =
    { id : LineId
    , shortName : String
    , longName : String
    , sortOrder : Int
    , color : Color.Color
    , textColor : Color.Color
    }


{-| -}
type ScheduleId
    = ScheduleId String


{-| In GTFS, the `stop_times.txt` file roughly corresponds to `Schedule`.
-}
type alias Schedule =
    { id : ScheduleId
    , routeId : RouteId
    , directionId : DirectionId
    , tripId : TripId
    , stopId : StopId
    , stopSequence : StopSequence
    , predictionId : Maybe PredictionId
    , timepoint : Bool
    , departureTime : Maybe Time.Posix
    , arrivalTime : Maybe Time.Posix
    , pickupType : PickupDropOffType
    , dropOffType : PickupDropOffType
    }


{-| -}
type StopSequence
    = StopSequence Int


{-| -}
type PickupDropOffType
    = PUDO_0_Regular
    | PUDO_1_NotAllowed
    | PUDO_2_PhoneAgency
    | PUDO_3_CoordinateWithDriver


{-| -}
type TripId
    = TripId String


{-| -}
type alias Trip =
    { id : TripId
    , serviceId : ServiceId
    , routeId : RouteId
    , directionId : DirectionId
    , routePatternId : Maybe RoutePatternId
    , name : String
    , headsign : String
    , shapeId : Maybe ShapeId
    , wheelchairAccessible : WheelchairAccessible
    , bikesAllowed : BikesAllowed
    , blockId : Maybe BlockId
    }


{-| -}
type BikesAllowed
    = Bikes_0_NoInformation
    | Bikes_1_Allowed
    | Bikes_2_NotAllowed


{-| -}
type BlockId
    = BlockId String


{-| -}
type ServiceId
    = ServiceId String


{-| -}
type alias Service =
    { id : ServiceId
    , description : Maybe String
    , serviceType : Maybe ServiceType
    , name : Maybe String
    , typicality : ServiceTypicality
    , startDate : ServiceDate
    , endDate : ServiceDate
    , validDays : List Int
    , addedDates : List ChangedDate
    , removedDates : List ChangedDate
    }


{-| Refers to a day of service, not a calendar day. Service after midnight still belongs to the previous calendar day's `ServiceDate`.
-}
type ServiceDate
    = ServiceDate String


{-|

    serviceDateFromIso8601 "2019-12-31"`

-}
serviceDateFromIso8601 : String -> ServiceDate
serviceDateFromIso8601 =
    ServiceDate


{-| -}
serviceDateToIso8601 : ServiceDate -> String
serviceDateToIso8601 (ServiceDate iso8601) =
    iso8601


{-| This is called `schedule_type` in the MBTA API. It was changed here to avoid ambiguity with [`Schedule`](#Schedule), which is unrelated to [`Service`](#Service)
-}
type ServiceType
    = ServiceType_Weekday
    | ServiceType_Saturday
    | ServiceType_Sunday
    | ServiceType_Other


{-| This is called `schedule_typicality` in the MBTA API. It was changed here to avoid ambiguity with [`Schedule`](#Schedule), which is unrelated to [`Service`](#Service)
-}
type ServiceTypicality
    = ServiceTypicality_0_NotDefined
    | ServiceTypicality_1_Typical
    | ServiceTypicality_2_ExtraService
    | ServiceTypicality_3_ReducedHoliday
    | ServiceTypicality_4_PlannedDisruption
    | ServiceTypicality_5_WeatherDisruption


{-| -}
type alias ChangedDate =
    { date : ServiceDate
    , notes : Maybe String
    }


{-| -}
type ShapeId
    = ShapeId String


{-| -}
type alias Shape =
    { id : ShapeId
    , name : String
    , routeId : RouteId
    , directionId : DirectionId
    , stopIds : List StopId
    , priority : Int
    , polyline : String
    }



-- Stop Data


{-| -}
type StopId
    = StopId String


{-| The API has 4 similar but slightly different concepts that all fall under the name "stop".

To get type safety in Elm, you have to know exactly which type you're working with,
but you should probably know that anyway,
so this library separates them into 4 different types.

The API doesn't separate them, though, hence the need for this custom type.

The numbers in the variant names correspond to the [`location_type`](StopType) that the API uses to tag the variants.

If you don't want to handle the different varieties separately,
or if you're not sure which kind of stop you have,
some functions are provided below for accessing common fields.

-}
type Stop
    = Stop_0_Stop Stop_Stop
    | Stop_1_Station Stop_Station
    | Stop_2_Entrance Stop_Entrance
    | Stop_3_Node Stop_Node


{-| A place where a vehicle will stop.

Some stops, like subway platforms, belong to a larger [`Stop_Station`](#Stop_Station) indicated by the `parent_station`.

-}
type alias Stop_Stop =
    { id : StopId
    , name : String
    , description : Maybe String
    , wheelchairAccessible : WheelchairAccessible
    , latLng : LatLng
    , address : Maybe String
    , parentStation : Maybe StopId
    , platformCode : Maybe String
    , platformName : Maybe String
    }


{-| A parent station that groups together the other kinds of stops into one building.

The `.childStops` will default to `[]` unless explicitly included with [`Mbta.Api.stopChildStops`](#Mbta.Api.stopChildStops)

-}
type alias Stop_Station =
    { id : StopId
    , name : String
    , description : Maybe String
    , wheelchairAccessible : WheelchairAccessible
    , latLng : LatLng
    , address : Maybe String
    , childStops : List StopId
    }


{-| An entrance to a [`Stop_Station`](#Stop_Station)
-}
type alias Stop_Entrance =
    { id : StopId
    , name : String
    , description : Maybe String
    , wheelchairAccessible : WheelchairAccessible
    , latLng : LatLng
    , parentStation : StopId
    }


{-| A generic point within a [`Stop_Station`](#Stop_Station) for wayfinding within the station.
-}
type alias Stop_Node =
    { id : StopId
    , name : String
    , description : Maybe String
    , wheelchairAccessible : WheelchairAccessible
    , parentStation : StopId
    }


{-| -}
stopId : Stop -> StopId
stopId stop =
    case stop of
        Stop_0_Stop stop_stop ->
            stop_stop.id

        Stop_1_Station stop_station ->
            stop_station.id

        Stop_2_Entrance stop_entrance ->
            stop_entrance.id

        Stop_3_Node stop_node ->
            stop_node.id


{-| -}
stopName : Stop -> String
stopName stop =
    case stop of
        Stop_0_Stop stop_stop ->
            stop_stop.name

        Stop_1_Station stop_station ->
            stop_station.name

        Stop_2_Entrance stop_entrance ->
            stop_entrance.name

        Stop_3_Node stop_node ->
            stop_node.name


{-| -}
stopDescription : Stop -> Maybe String
stopDescription stop =
    case stop of
        Stop_0_Stop stop_stop ->
            stop_stop.description

        Stop_1_Station stop_station ->
            stop_station.description

        Stop_2_Entrance stop_entrance ->
            stop_entrance.description

        Stop_3_Node stop_node ->
            stop_node.description


{-| In the API, this field is called `wheelchair_boarding`.
-}
stopWheelchairAccessible : Stop -> WheelchairAccessible
stopWheelchairAccessible stop =
    case stop of
        Stop_0_Stop stop_stop ->
            stop_stop.wheelchairAccessible

        Stop_1_Station stop_station ->
            stop_station.wheelchairAccessible

        Stop_2_Entrance stop_entrance ->
            stop_entrance.wheelchairAccessible

        Stop_3_Node stop_node ->
            stop_node.wheelchairAccessible


{-| [`Stop_Node`](#Stop_Node) does not have a `latLng` field.
If you want to get a `LatLng` instead of a `Maybe LatLng`,
then work specifically with [`Stop_Stop`](#Stop_Stop), [`Stop_Station`](#Stop_Station), and [`Stop_Entrace`](#Stop_Entrace) types.
-}
stopLatLng : Stop -> Maybe LatLng
stopLatLng stop =
    case stop of
        Stop_0_Stop stop_stop ->
            Just stop_stop.latLng

        Stop_1_Station stop_station ->
            Just stop_station.latLng

        Stop_2_Entrance stop_entrance ->
            Just stop_entrance.latLng

        Stop_3_Node stop_node ->
            Nothing


{-| -}
stopParentStation : Stop -> Maybe StopId
stopParentStation stop =
    case stop of
        Stop_0_Stop stop_stop ->
            stop_stop.parentStation

        Stop_1_Station stop_station ->
            Nothing

        Stop_2_Entrance stop_entrance ->
            Just stop_entrance.parentStation

        Stop_3_Node stop_node ->
            Just stop_node.parentStation


{-| In the API this is called `location_type`, and is used to tag the different variants of stops

Since Elm has custom types, that's used to tag the fields instead of having a `.stopType` field,
but `StopType` is still used to filter api requests.

-}
type StopType
    = StopType_0_Stop
    | StopType_1_Station
    | StopType_2_Entrance
    | StopType_3_Node


{-| Get the [`StopType`](#StopType) that the API used to tag the stop.
-}
stopType : Stop -> StopType
stopType stop =
    case stop of
        Stop_0_Stop stop_stop ->
            StopType_0_Stop

        Stop_1_Station stop_station ->
            StopType_1_Station

        Stop_2_Entrance stop_entrance ->
            StopType_2_Entrance

        Stop_3_Node stop_node ->
            StopType_3_Node


{-| -}
type FacilityId
    = FacilityId String


{-| Most facilities have both a `long_name` and a `short_name`,
though it's not technically required.
If one is missing, it will default to the other name.
-}
type alias Facility =
    { id : FacilityId
    , stopId : Maybe StopId
    , longName : String
    , shortName : String
    , facilityType : FacilityType
    , latLng : Maybe LatLng
    , properties : FacilityProperties
    }


{-| -}
type alias LiveFacility =
    { id : FacilityId
    , updatedAt : Time.Posix
    , properties : FacilityProperties
    }


{-| The API and GTFS docs list a long but finite list of potential string values
-}
type FacilityType
    = FacilityType String


{-| Properties come in `name` `value` pairs.
A `name` may appear multiple times, so the values are grouped.
Order is not important.
-}
type alias FacilityProperties =
    Dict.Dict String (List FacilityPropertyValue)


{-| -}
type FacilityPropertyValue
    = FacilityProperty_String String
    | FacilityProperty_Int Int
    | FacilityProperty_Null



-- Alerts


{-| -}
type AlertId
    = AlertId String


{-| There are long but finite lists of possible values for `effect` and `cause` in the MBTA API docs.

The `banner` field is published by the API, but always `null`, so it's not included here.

The API publishes some relationships (`routes`, `trips`, `stops`, and `facilities`),
but only if that relationship was [included](#Mbta.Api.alertRoutes),
and those relationships are redundant with the ids specified in `informedEntities`,
so they are not included in the root of this `Alert` record.

-}
type alias Alert =
    { id : AlertId
    , url : Maybe String
    , shortHeader : String
    , header : String
    , description : Maybe String
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    , timeframe : Maybe String
    , activePeriod : List ActivePeriod
    , severity : Int
    , serviceEffect : String
    , lifecycle : AlertLifecycle
    , effect : String
    , cause : String
    , informedEntities : List InformedEntity
    }


{-| -}
type AlertLifecycle
    = Alert_New
    | Alert_Ongoing
    | Alert_OngoingUpcoming
    | Alert_Upcoming


{-| -}
type alias ActivePeriod =
    { start : Time.Posix
    , end : Maybe Time.Posix
    }


{-| There is always at least one `activity` and at least one other field.
-}
type alias InformedEntity =
    { activities : List InformedEntityActivity
    , routeType : Maybe RouteType
    , routeId : Maybe RouteId
    , directionId : Maybe DirectionId
    , tripId : Maybe TripId
    , stopId : Maybe StopId
    , facilityId : Maybe FacilityId
    }


{-| -}
type InformedEntityActivity
    = Activity_Board
    | Activity_BringingBike
    | Activity_Exit
    | Activity_ParkCar
    | Activity_Ride
    | Activity_StoreBike
    | Activity_UsingEscalator
    | Activity_UsingWheelchair
