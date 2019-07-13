module Mbta exposing
    ( Color(..), LatLng, DirectionId(..), WheelchairAccessible(..)
    , PredictionId(..), Prediction, PredictionScheduleRelationship(..)
    , VehicleId(..), Vehicle, CurrentStatus(..)
    , RouteType(..), RouteId(..), Route, RouteDirections, RouteDirection
    , RoutePatternId(..), RoutePattern, RoutePatternTypicality(..)
    , LineId(..), Line, ScheduleId(..)
    , Schedule, StopSequence(..), PickupDropOffType(..)
    , TripId(..), Trip, BikesAllowed(..), BlockId(..)
    , ServiceId(..), Service, ServiceDate, serviceDateFromIso8601, serviceDateToIso8601, ServiceType(..), ServiceTypicality(..), ChangedDate
    , ShapeId(..), Shape
    , StopId(..), Stop, LocationType(..)
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

@docs Color, LatLng, DirectionId, WheelchairAccessible


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

@docs StopId, Stop, LocationType
@docs FacilityId, Facility, LiveFacility, FacilityType, FacilityProperties, FacilityPropertyValue


# Alert Data

@docs AlertId, Alert, AlertLifecycle, ActivePeriod, InformedEntity, InformedEntityActivity

-}

import Dict
import Time



-- Util


{-| E.g. `Color "FFFFFF"`
-}
type
    Color
    -- TODO use avh4/elm-color instead
    = Color String


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
    , textColor : Color
    , color : Color
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
    , color : Color
    , textColor : Color
    }


{-| -}
type ScheduleId
    = ScheduleId String


{-| In GTFS, the `stop_times.txt` file roughly corresponds to `Schedule`.
-}
type alias Schedule =
    { id : ScheduleId
    , routeId : RouteId

    -- TODO disabled due to api bug https://app.asana.com/0/695227265423458/1121247532991447
    --, directionId : DirectionId
    , tripId : TripId
    , stopId : StopId
    , stopSequence : StopSequence
    , predictionId : Maybe PredictionId
    , timepoint : Bool
    , departureTime : Time.Posix
    , arrivalTime : Time.Posix
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
    , routePatternId : RoutePatternId
    , name : String
    , headsign : String
    , shapeId : ShapeId
    , wheelchairAccessible : WheelchairAccessible
    , bikesAllowed : BikesAllowed
    , blockId : BlockId
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


{-| Nodes will not have a latLng. Other location types will.
-}
type alias Stop =
    -- TODO format that enforces constraints. E.g. stations can't have a parent_station.
    -- TODO childStops : Maybe (List StopId)?
    { id : StopId
    , name : String
    , description : Maybe String
    , parentStation : Maybe StopId
    , platformCode : Maybe String
    , platformName : Maybe String
    , locationType : LocationType
    , latLng : Maybe LatLng
    , address : Maybe String
    , wheelchairBoarding : WheelchairAccessible
    }


{-| -}
type LocationType
    = LocationType_0_Stop
    | LocationType_1_Station
    | LocationType_2_Entrance
    | LocationType_3_Node


{-| -}
type FacilityId
    = FacilityId String


{-| -}
type alias Facility =
    { id : FacilityId
    , stopId : StopId
    , name : String
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

-}



-- TODO facilities is only included if includes is specified


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

    --, facilities : Maybe (List FacilityId)
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


{-| -}
type alias InformedEntity =
    -- TODO most are probably optional
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
