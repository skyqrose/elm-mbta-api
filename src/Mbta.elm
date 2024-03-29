module Mbta exposing
    ( LatLng, DirectionId(..), WheelchairAccessible(..)
    , PredictionId(..), Prediction, PredictionScheduleRelationship(..), PredictionDisplay(..), predictionDisplay
    , VehicleId(..), Vehicle, CurrentStatus(..)
    , RouteType(..), RouteId(..), Route, RouteDirections, RouteDirection, getRouteDirection
    , RoutePatternId(..), RoutePattern, RoutePatternTypicality(..)
    , LineId(..), Line, ScheduleId(..)
    , Schedule, StopSequence(..), PickupDropOffType(..)
    , TripId(..), Trip, BikesAllowed(..), BlockId(..)
    , ServiceId(..), Service, ServiceDate, serviceDateFromIso8601, serviceDateToIso8601, ServiceType(..), ServiceTypicality(..), ChangedDate
    , ShapeId(..), Shape
    , StopId(..), Stop(..), Stop_Stop, Stop_Station, Stop_Entrance, Stop_Node, stopId, stopName, stopDescription, stopWheelchairAccessible, stopLatLng, stopParentStation, StopType(..), stopType, ZoneId(..)
    , FacilityId(..), Facility, LiveFacility, FacilityType(..), FacilityProperties, FacilityPropertyValue(..)
    , AlertId(..), Alert, AlertLifecycle(..), ActivePeriod, InformedEntity, InformedEntityActivity(..)
    )

{-| The types for all data coming from the MBTA API

To avoid duplicating the [official MBTA API docs][swagger],
this documentation does not describe the meaning of this data.
It just describes any important differences between this library and the API.

The [MBTA GTFS docs][gtfs-mbta] may also be useful for describing what data means,
though there's less of a direct correspondence between this library and the GTFS format.

Names were generally kept consistent with the API,
though they were changed in some places to make them clearer.

Some list fields that come from an [`include`](Mbta-Api#Include) will default to [] unless that relationship is included.

[swagger]: https://api-v3.mbta.com/docs/swagger/index.html#/Vehicle/ApiWeb_VehicleController_index
[gtfs-mbta]: https://github.com/mbta/gtfs-documentation/blob/master/reference/gtfs.md


## Util

@docs LatLng, DirectionId, WheelchairAccessible


## Realtime Data


### Prediction

@docs PredictionId, Prediction, PredictionScheduleRelationship, PredictionDisplay, predictionDisplay


### Vehicle

@docs VehicleId, Vehicle, CurrentStatus


## Schedule Data


### Route

@docs RouteType, RouteId, Route, RouteDirections, RouteDirection, getRouteDirection


### RoutePattern

@docs RoutePatternId, RoutePattern, RoutePatternTypicality


### Line

@docs LineId, Line, ScheduleId


### Schedule

@docs Schedule, StopSequence, PickupDropOffType


### Trip

@docs TripId, Trip, BikesAllowed, BlockId


### Service

@docs ServiceId, Service, ServiceDate, serviceDateFromIso8601, serviceDateToIso8601, ServiceType, ServiceTypicality, ChangedDate


### Shape

@docs ShapeId, Shape


## Stop Data


### Stop

@docs StopId, Stop, Stop_Stop, Stop_Station, Stop_Entrance, Stop_Node, stopId, stopName, stopDescription, stopWheelchairAccessible, stopLatLng, stopParentStation, StopType, stopType, ZoneId


### Facility

@docs FacilityId, Facility, LiveFacility, FacilityType, FacilityProperties, FacilityPropertyValue


## Alert Data


### Alert

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


{-| If `arrivalTime` and `departureTime` are both missing, that means the stop is predicted to be skipped.
-}
type alias Prediction =
    { id : PredictionId
    , routeId : RouteId
    , tripId : TripId
    , stopId : StopId
    , stopSequence : Maybe StopSequence
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


{-| What to show riders on something like a countdown clock.

Calculate it with [`predictionDisplay`](#predictionDisplay)

  - `Status`: A custom string to show
  - `Boarding`: The vehicle is at the platform. Show `"Boarding"` or `"BRD"`
  - `Arriving`: Show `"Arriving"` or `"ARR"`
  - `Approaching`: Show `"Approaching"` or `"1 min"`
  - `Minutes n`: Show `"1 minute"` or `"1 min"` or `"2 minutes"` or `"2 min"`
  - `Skipped`: The vehicle will not pick up passengers.

-}
type PredictionDisplay
    = Status String
    | Boarding
    | Arriving
    | Approaching
    | Minutes Int
    | Skipped


{-| Follows MBTA best practices for what to show riders on something like a countdown clock.

If you have the vehicle associated with the prediction, pass it in to check if it's is currently boarding

-}
predictionDisplay : Time.Posix -> Maybe Vehicle -> Prediction -> PredictionDisplay
predictionDisplay now maybeVehicle prediction =
    -- There are lots of cases that might control what we show. Choose the highest priority.
    Nothing
        -- If there's a custom status, show that.
        |> maybeOrElse
            (Maybe.map Status prediction.status)
        -- Check if the prediction was cancelled or skipped
        |> maybeOrElse
            (if
                prediction.scheduleRelationship
                    == ScheduleRelationship_Cancelled
                    || prediction.scheduleRelationship
                    == ScheduleRelationship_Skipped
             then
                Just Skipped

             else
                Nothing
            )
        -- If the vehicle is at the stop, it might be Boarding
        |> maybeOrElse
            (maybeVehicle
                |> Maybe.andThen
                    (\vehicle ->
                        if
                            Just vehicle.id
                                == prediction.vehicleId
                                && vehicle.currentStatus
                                == StoppedAt
                                && vehicle.stopId
                                == prediction.stopId
                        then
                            -- Vehicle is at the stop
                            case ( prediction.arrivalTime, prediction.departureTime ) of
                                ( Just _, _ ) ->
                                    -- Not the first stop. Vehicle is definitely taking passengers
                                    Just Boarding

                                ( Nothing, Just departureTime ) ->
                                    -- Waiting at first stop. Check if it's departing soon.
                                    if (Time.posixToMillis departureTime - Time.posixToMillis now) < 90000 then
                                        Just Boarding

                                    else
                                        Nothing

                                ( Nothing, Nothing ) ->
                                    -- Skipped
                                    Just Skipped

                        else
                            -- Vehicle is not at the stop
                            Nothing
                    )
            )
        -- Time based predictions
        |> maybeOrElse
            (secondsUntilPrediction now prediction
                |> Maybe.map
                    (\seconds ->
                        if seconds <= 30 then
                            Arriving

                        else if seconds <= 60 then
                            Approaching

                        else
                            -- Round to nearest minute
                            Minutes ((seconds + 30) // 60)
                    )
            )
        -- If there's no prediction time, the stop was skipped
        |> Maybe.withDefault Skipped


{-| Prioritizes `arrivalTime` over `departureTime` if both are present.
-}
secondsUntilPrediction : Time.Posix -> Prediction -> Maybe Int
secondsUntilPrediction now prediction =
    prediction.arrivalTime
        |> maybeOrElse prediction.departureTime
        |> Maybe.map
            (\predictionTime ->
                (Time.posixToMillis predictionTime - Time.posixToMillis now) // 1000
            )


{-| From [Maybe.Extra](https://package.elm-lang.org/packages/elm-community/maybe-extra/latest/Maybe-Extra#orElse)
-}
maybeOrElse : Maybe a -> Maybe a -> Maybe a
maybeOrElse second first =
    case first of
        Just _ ->
            first

        Nothing ->
            second


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


{-| `.routePatternIds` will default to `[]` unless explicitly included with [`Mbta.Api.routeRoutePatterns`](Mbta-Api#routeRoutePatterns)
-}
type alias Route =
    { id : RouteId
    , routePatternIds : List RoutePatternId
    , lineId : Maybe LineId
    , routeType : RouteType
    , shortName : Maybe String
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
getRouteDirection : DirectionId -> RouteDirections -> RouteDirection
getRouteDirection directionId routeDirections =
    case directionId of
        D0 ->
            routeDirections.d0

        D1 ->
            routeDirections.d1


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


{-| `.routeIds` will default to `[]` unless explicitly included with [`Mbta.Api.lineRoutes`](Mbta-Api#lineRoutes)
-}
type alias Line =
    { id : LineId
    , routeIds : List RouteId
    , shortName : Maybe String
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


{-| `.stopIds` will default to `[]` unless explicitly included with [`Mbta.Api.tripStops`](Mbta-Api#tripStops)
-}
type alias Trip =
    { id : TripId

    -- Added trips don't have a service
    , serviceId : Maybe ServiceId
    , routeId : RouteId
    , directionId : DirectionId
    , routePatternId : Maybe RoutePatternId
    , stopIds : List StopId
    , name : Maybe String
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


{-| `.stopIds` should be populated even if not included by [`Mbta.Api.shapeStops`](Mbta-Api#shapeStops)
-}
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

`.connectingStops` and `.facilityIds` will default to `[]` unless explicitly included with [`Mbta.Api.stopRecommenedTransfers`](Mbta-Api#stopRecommenedTransfers) or [`Mbta.Api.stopFacilities`](Mbta-Api#stopFacilities)

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
    , zone : Maybe ZoneId
    , connectingStops : List StopId
    , facilityIds : List FacilityId
    }


{-| A parent station that groups together the other kinds of stops into one building.

`.childStops`, `.connectingStops`, and `.facilityIds` will default to `[]` unless explicitly included with [`Mbta.Api.stopChildStops`](Mbta-Api#stopChildStops), [`Mbta.Api.stopRecommenedTransfers`](Mbta-Api#stopRecommenedTransfers), or [`Mbta.Api.stopFacilities`](Mbta-Api#stopFacilities)

-}
type alias Stop_Station =
    { id : StopId
    , name : String
    , description : Maybe String
    , wheelchairAccessible : WheelchairAccessible
    , latLng : LatLng
    , address : Maybe String
    , zone : Maybe ZoneId
    , childStops : List StopId
    , connectingStops : List StopId
    , facilityIds : List FacilityId
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
type ZoneId
    = ZoneId String


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
but only if that relationship was [included](Mbta-Api#alertRoutes),
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
