module Mbta exposing
    ( ActivePeriod
    , Alert
    , AlertCause(..)
    , AlertEffect(..)
    , AlertId(..)
    , AlertLifecycle(..)
    , BikesAllowed(..)
    , BlockId(..)
    , Color(..)
    , CurrentStatus(..)
    , DirectionId(..)
    , Facility
    , FacilityId(..)
    , FacilityProperties
    , FacilityProperty
    , FacilityPropertyName(..)
    , FacilityPropertyValue(..)
    , InformedEntity
    , InformedEntityActivity(..)
    , LatLng
    , Line
    , LineId(..)
    , LiveFacility
    , LocationType(..)
    , PickupDropOffType(..)
    , Prediction
    , PredictionId(..)
    , PredictionScheduleRelationship(..)
    , Route
    , RouteId(..)
    , RoutePattern
    , RoutePatternId(..)
    , RoutePatternTypicality(..)
    , RouteType(..)
    , Schedule
    , ScheduleId(..)
    , ScheduleType(..)
    , Service
    , ServiceDate(..)
    , ServiceId(..)
    , ServiceTypicality(..)
    , Shape
    , ShapeId(..)
    , Stop
    , StopId(..)
    , StopSequence(..)
    , Trip
    , TripId(..)
    , Vehicle
    , VehicleId(..)
    , WheelchairAccessible(..)
    )

-- TODO lots of fields should be optional

import Time



-- Util


type Color
    = Color String


type alias LatLng =
    { latitude : Float
    , longitude : Float
    }



-- Core Data reusable


type ServiceDate
    = ServiceDate String


type CurrentStatus
    = IncomingAt
    | StoppedAt
    | InTransitTo


type DirectionId
    = D0
    | D1


type RouteType
    = RouteType_0_LightRail
    | RouteType_1_HeavyRail
    | RouteType_2_CommuterRail
    | RouteType_3_Bus
    | RouteType_4_Ferry


type StopSequence
    = StopSequence Int


type WheelchairAccessible
    = Accessible_0_NoInformation
    | Accessible_1_Accessible
    | Accessible_2_Inaccessible



-- Core Data resources


type LineId
    = LineId String


type alias Line =
    { id : LineId
    , shortName : String
    , longName : String
    , sortOrder : Int
    , color : Color
    , textColor : Color
    }


type PredictionId
    = PredictionId String


type alias Prediction =
    { id : PredictionId
    , routeId : RouteId
    , tripId : TripId
    , stopId : StopId
    , stopSequence : Maybe StopSequence
    , scheduleId : ScheduleId
    , vehicleId : Maybe VehicleId
    , alertIds : List AlertId
    , arrivalTime : Maybe Time.Posix
    , currentStatus : CurrentStatus -- What is this?
    , departureTime : Maybe Time.Posix
    , directionId : DirectionId
    , scheduleRelationship : Maybe PredictionScheduleRelationship
    }


type PredictionScheduleRelationship
    = ScheduleRelationship_Added
    | ScheduleRelationship_Cancelled
    | ScheduleRelationship_NoData
    | ScheduleRelationship_Skipped
    | ScheduleRelationship_Unscheduled
    | ScheduleRelationship_Scheduled


type RouteId
    = RouteId String


type alias Route =
    { id : RouteId
    , routeType : RouteType
    , shortName : String
    , longName : String
    , description : String
    , fareClass : String

    -- TODO pair direction name and destination
    , directionNames : Maybe { d0 : String, d1 : String }
    , directionDestinations : Maybe { d0 : String, d1 : String }
    , sortOrder : Int
    , textColor : Color
    , color : Color
    }


type RoutePatternId
    = RoutePatternId String


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


type RoutePatternTypicality
    = RoutePatternTypicality_0_NotDefined
    | RoutePatternTypicality_1_Typical
    | RoutePatternTypicality_2_Deviation
    | RoutePatternTypicality_3_Atypical
    | RoutePatternTypicality_4_Diversion


type ScheduleId
    = ScheduleId String


type alias Schedule =
    { id : ScheduleId
    , routeId : RouteId
    , directionId : DirectionId
    , tripId : TripId
    , stopId : StopId
    , stopSequence : StopSequence
    , predictionId : PredictionId
    , timepoint : Bool
    , departureTime : Time.Posix
    , arrivalTime : Time.Posix
    , pickupType : PickupDropOffType
    , dropOffType : PickupDropOffType
    }


type PickupDropOffType
    = PUDO_0_Regular
    | PUDO_1_NotAllowed
    | PUDO_2_PhoneAgency
    | PUDO_3_CoordinateWithDriver


type ServiceId
    = ServiceId String


type alias Service =
    { id : ServiceId
    , description : Maybe String
    , scheduleType : List ScheduleType
    , scheduleName : Maybe String
    , scheduleTypicality : ServiceTypicality
    , startDate : ServiceDate
    , endDate : ServiceDate
    , validDays : List Int

    -- TODO better format for added/removed
    -- Remove illegal states where lists are different lengths
    , addedDates : List ServiceDate
    , addedDatesNotes : List String
    , removedDates : List ServiceDate
    , removedDatesNotes : List String
    }


type ServiceTypicality
    = ServiceTypicality_0_NotDefined
    | ServiceTypicality_1_Typical
    | ServiceTypicality_2_ExtraService
    | ServiceTypicality_3_ReducedHoliday
    | ServiceTypicality_4_PlannedDisruption
    | ServiceTypicality_5_WeatherDisruption


type ScheduleType
    = ScheduleType_Weekday
    | ScheduleType_Saturday
    | ScheduleType_Sunday
    | ScheduleType_Other


type ShapeId
    = ShapeId String


type alias Shape =
    { id : ShapeId
    , name : String
    , routeId : RouteId
    , directionId : DirectionId
    , stopIds : List StopId
    , priority : Int
    , polyline : String
    }


type StopId
    = StopId String


type alias Stop =
    { id : StopId
    , name : String
    , description : Maybe String
    , parentStation : Maybe StopId
    , platformCode : Maybe String
    , platformName : Maybe String
    , locationType : LocationType
    , latLng : LatLng
    , address : Maybe String
    , wheelchairBoarding : WheelchairAccessible
    }


type LocationType
    = LocationType_0_Stop
    | LocationType_1_Station
    | LocationType_2_Entrance


type TripId
    = TripId String


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


type BlockId
    = BlockId String


type BikesAllowed
    = Bikes_NoInformation
    | Bikes_Allowed
    | Bikes_NotAllowed


type VehicleId
    = VehicleId String


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
    , speed : Float
    , bearing : Int
    , updatedAt : Time.Posix
    }



-- Facilities


type FacilityId
    = FacilityId String


type alias Facility =
    { id : FacilityId
    , stopId : StopId
    , name : String
    , latLng : LatLng
    , properties : FacilityProperties
    }


type alias LiveFacility =
    { id : FacilityId
    , updatedAt : Time.Posix
    , properties : FacilityProperties
    }


type alias FacilityProperties =
    List FacilityProperty


type alias FacilityProperty =
    ( FacilityPropertyName, FacilityPropertyValue )


type FacilityPropertyName
    = FacilityProperyName String


type FacilityPropertyValue
    = StringProperty String
    | IntProperty Int



-- Alerts


type AlertId
    = AlertId String


type alias Alert =
    { id : AlertId
    , url : String
    , shortHeader : String
    , header : String
    , banner : String
    , description : String
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    , timeframe : String
    , activePeriod : List ActivePeriod
    , severity : Int
    , serviceEffect : String
    , lifecycle : AlertLifecycle
    , effectName : String
    , effect : AlertEffect
    , cause : AlertCause
    , facilityId : FacilityId
    , informedEntities : InformedEntity
    }


type AlertCause
    = Cause_Accident
    | Cause_Amtrak
    | Cause_AnEarlierMechanicalProblem
    | Cause_AnEarlierSignalProblem
    | Cause_AutosImpedingService
    | Cause_CoastGuardRestriction
    | Cause_Congestion
    | Cause_Construction
    | Cause_CrossingMalfunction
    | Cause_Demonstration
    | Cause_DisabledBus
    | Cause_DisabledTrain
    | Cause_DrawbridgeBeingRaised
    | Cause_ElectricalWork
    | Cause_Fire
    | Cause_Fog
    | Cause_FreightTrainInterference
    | Cause_HazmatCondition
    | Cause_HeavyRidership
    | Cause_HighWinds
    | Cause_Holiday
    | Cause_Hurricane
    | Cause_IceInHarbor
    | Cause_Maintenance
    | Cause_MechanicalProblem
    | Cause_MedicalEmergency
    | Cause_Parade
    | Cause_PoliceAction
    | Cause_PowerProblem
    | Cause_SevereWeather
    | Cause_SignalProblem
    | Cause_SlipperyRail
    | Cause_Snow
    | Cause_SpecialEvent
    | Cause_SpeedRestriction
    | Cause_SwitchProblem
    | Cause_TieReplacement
    | Cause_TrackProblem
    | Cause_TrackWork
    | Cause_Traffic
    | Cause_UnrulyPassenger
    | Cause_Weather


type AlertEffect
    = Effect_AccessIssue
    | Effect_AdditionalService
    | Effect_AmberAlert
    | Effect_BikeIssue
    | Effect_Cancellation
    | Effect_Delay
    | Effect_Detour
    | Effect_DockClosuR
    | Effect_DockIssue
    | Effect_ElevatorClosure
    | Effect_EscalatorClosure
    | Effect_ExtraService
    | Effect_FacilityIssue
    | Effect_ModifiedService
    | Effect_NoService
    | Effect_OtherEffect
    | Effect_ParkingClosure
    | Effect_ParkingIssue
    | Effect_PolicyChange
    | Effect_ScheduleChange
    | Effect_ServiceChange
    | Effect_Shuttle
    | Effect_SnowRoute
    | Effect_StationClosure
    | Effect_StationIssue
    | Effect_StopClosure
    | Effect_StopMove
    | Effect_StopMoved
    | Effect_Summary
    | Effect_Suspension
    | Effect_TrackChange
    | Effect_UnknownEffect


type AlertLifecycle
    = Alert_New
    | Alert_Ongoing
    | Alert_OngoingUpcoming
    | Alert_Upcoming


type alias ActivePeriod =
    { start : Time.Posix
    , end : Time.Posix
    }



-- TODO most are probably optional


type alias InformedEntity =
    { routeType : RouteType
    , routeId : RouteId
    , directionId : DirectionId
    , tripId : TripId
    , stopId : StopId
    , facilityId : FacilityId
    , activities : InformedEntityActivity
    }


type InformedEntityActivity
    = Activity_Board
    | Activity_BringingBike
    | Activity_Exit
    | Activity_ParkCar
    | Activity_Ride
    | Activity_StoreBike
    | Activity_UsingEscalator
    | Activity_UsingWheelchair
