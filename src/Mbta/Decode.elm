module Mbta.Decode exposing
    ( predictionId, prediction, vehicleId, vehicle
    , routeId, route, routePatternId, routePattern, lineId, line, scheduleId, schedule, tripId, trip, serviceId, service, shapeId, shape
    , stopId, stop, facilityId, facility, liveFacility
    , alertId, alert
    )

{-|


# Realtime Data

@docs predictionId, prediction, vehicleId, vehicle


# Schedule Data

@docs routeId, route, routePatternId, routePattern, lineId, line, scheduleId, schedule, tripId, trip, serviceId, service, shapeId, shape


# Stop Data

@docs stopId, stop, facilityId, facility, liveFacility


# Alert Data

@docs alertId, alert

-}

import Color
import Color.Convert
import DecodeHelpers
import Dict
import Iso8601
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import JsonApi
    exposing
        ( attribute
        , attributeMaybe
        , custom
        , id
        , relationshipMany
        , relationshipMaybe
        , relationshipOne
        )
import Mbta exposing (..)



-- Util


color : Decode.Decoder Color.Color
color =
    Decode.string
        |> Decode.map Color.Convert.hexToColor
        |> Decode.andThen DecodeHelpers.fromResult


latLng : JsonApi.ResourceDecoder LatLng
latLng =
    JsonApi.succeed LatLng
        |> attribute "latitude" Decode.float
        |> attribute "longitude" Decode.float


maybeLatLng : JsonApi.ResourceDecoder (Maybe LatLng)
maybeLatLng =
    JsonApi.succeed Tuple.pair
        |> attributeMaybe "latitude" Decode.float
        |> attributeMaybe "longitude" Decode.float
        |> JsonApi.andThen
            (\( maybeLat, maybeLng ) ->
                case ( maybeLat, maybeLng ) of
                    ( Just lat, Just lng ) ->
                        JsonApi.succeed
                            (Just
                                { latitude = lat
                                , longitude = lng
                                }
                            )

                    ( Nothing, Nothing ) ->
                        JsonApi.succeed Nothing

                    ( Just lat, Nothing ) ->
                        JsonApi.fail "longitude is missing but latitude exists"

                    ( Nothing, Just lng ) ->
                        JsonApi.fail "latitude is missing but longitude exists"
            )


directionId : Decode.Decoder DirectionId
directionId =
    DecodeHelpers.enum Decode.int
        [ ( 0, D0 )
        , ( 1, D1 )
        ]


wheelchairAccessible : Decode.Decoder WheelchairAccessible
wheelchairAccessible =
    DecodeHelpers.enum Decode.int
        [ ( 0, Accessible_0_NoInformation )
        , ( 1, Accessible_1_Accessible )
        , ( 2, Accessible_2_Inaccessible )
        ]



-- Realtime Data


predictionId : JsonApi.IdDecoder PredictionId
predictionId =
    JsonApi.idDecoder "prediction" PredictionId


prediction : JsonApi.ResourceDecoder Prediction
prediction =
    JsonApi.succeed Prediction
        |> id predictionId
        |> relationshipOne "route" routeId
        |> relationshipOne "trip" tripId
        |> relationshipOne "stop" stopId
        |> attribute "stop_sequence" stopSequence
        |> relationshipMaybe "schedule" scheduleId
        |> relationshipMaybe "vehicle" vehicleId
        |> relationshipMany "alert" alertId
        |> attributeMaybe "arrival_time" Iso8601.decoder
        |> attributeMaybe "departure_time" Iso8601.decoder
        |> attributeMaybe "status" Decode.string
        |> attribute "direction_id" directionId
        |> attribute "schedule_relationship" predictionScheduleRelatonship


predictionScheduleRelatonship : Decode.Decoder PredictionScheduleRelationship
predictionScheduleRelatonship =
    DecodeHelpers.enum Decode.string
        [ ( "ADDED", ScheduleRelationship_Added )
        , ( "CANCELLED", ScheduleRelationship_Cancelled )
        , ( "NO_DATA", ScheduleRelationship_NoData )
        , ( "SKIPPED", ScheduleRelationship_Skipped )
        , ( "UNSCHEDULED", ScheduleRelationship_Unscheduled )
        ]
        |> Decode.nullable
        |> Decode.map (Maybe.withDefault ScheduleRelationship_Scheduled)


vehicleId : JsonApi.IdDecoder VehicleId
vehicleId =
    JsonApi.idDecoder "vehicle" VehicleId


vehicle : JsonApi.ResourceDecoder Vehicle
vehicle =
    JsonApi.succeed Vehicle
        |> id vehicleId
        |> attribute "label" Decode.string
        |> relationshipOne "route" routeId
        |> attribute "direction_id" directionId
        |> relationshipOne "trip" tripId
        |> relationshipOne "stop" stopId
        |> attribute "current_stop_sequence" stopSequence
        |> attribute "current_status" currentStatus
        |> custom latLng
        |> attributeMaybe "speed" Decode.float
        |> attribute "bearing" Decode.int
        |> attribute "updated_at" Iso8601.decoder


currentStatus : Decode.Decoder CurrentStatus
currentStatus =
    DecodeHelpers.enum Decode.string
        [ ( "INCOMING_AT", IncomingAt )
        , ( "STOPPED_AT", StoppedAt )
        , ( "IN_TRANSIT_TO", InTransitTo )
        ]



-- Schedule Data


routeType : Decode.Decoder RouteType
routeType =
    DecodeHelpers.enum Decode.int
        [ ( 0, RouteType_0_LightRail )
        , ( 1, RouteType_1_HeavyRail )
        , ( 2, RouteType_2_CommuterRail )
        , ( 3, RouteType_3_Bus )
        , ( 4, RouteType_4_Ferry )
        ]


routeId : JsonApi.IdDecoder RouteId
routeId =
    JsonApi.idDecoder "route" RouteId


route : JsonApi.ResourceDecoder Route
route =
    JsonApi.succeed Route
        |> id routeId
        |> attribute "type" routeType
        |> attribute "short_name" Decode.string
        |> attribute "long_name" Decode.string
        |> attribute "description" Decode.string
        |> attribute "fare_class" Decode.string
        |> custom routeDirections
        |> attribute "sort_order" Decode.int
        |> attribute "text_color" color
        |> attribute "color" color


routeDirections : JsonApi.ResourceDecoder (Maybe RouteDirections)
routeDirections =
    JsonApi.succeed Tuple.pair
        |> attributeMaybe "direction_names" (Decode.list Decode.string)
        |> attributeMaybe "direction_destinations" (Decode.list Decode.string)
        |> JsonApi.andThen
            (\( names, destinations ) ->
                case ( names, destinations ) of
                    ( Just [ d0_name, d1_name ], Just [ d0_destination, d1_destination ] ) ->
                        JsonApi.succeed
                            (Just
                                { d0 = { name = d0_name, destination = d0_destination }
                                , d1 = { name = d1_name, destination = d1_destination }
                                }
                            )

                    ( Nothing, Nothing ) ->
                        JsonApi.succeed Nothing

                    _ ->
                        JsonApi.fail "expected exactly 2 direction_names and exactly 2 direction_destinations"
            )


routePatternId : JsonApi.IdDecoder RoutePatternId
routePatternId =
    JsonApi.idDecoder "route_pattern" RoutePatternId


routePattern : JsonApi.ResourceDecoder RoutePattern
routePattern =
    JsonApi.succeed RoutePattern
        |> id routePatternId
        |> relationshipOne "route" routeId
        |> attribute "direction_id" directionId
        |> attribute "name" Decode.string
        |> attribute "typicality" routePatternTypicality
        |> attributeMaybe "time_desc" Decode.string
        |> attribute "sort_order" Decode.int
        |> relationshipOne "representative_trip" tripId


routePatternTypicality : Decode.Decoder RoutePatternTypicality
routePatternTypicality =
    DecodeHelpers.enum Decode.int
        [ ( 0, RoutePatternTypicality_0_NotDefined )
        , ( 1, RoutePatternTypicality_1_Typical )
        , ( 2, RoutePatternTypicality_2_Deviation )
        , ( 3, RoutePatternTypicality_3_Atypical )
        , ( 4, RoutePatternTypicality_4_Diversion )
        ]


lineId : JsonApi.IdDecoder LineId
lineId =
    JsonApi.idDecoder "line" LineId


line : JsonApi.ResourceDecoder Line
line =
    JsonApi.succeed Line
        |> id lineId
        |> attribute "short_name" Decode.string
        |> attribute "long_name" Decode.string
        |> attribute "sort_order" Decode.int
        |> attribute "color" color
        |> attribute "text_color" color


scheduleId : JsonApi.IdDecoder ScheduleId
scheduleId =
    JsonApi.idDecoder "schedule" ScheduleId


schedule : JsonApi.ResourceDecoder Schedule
schedule =
    JsonApi.succeed Schedule
        |> id scheduleId
        |> relationshipOne "route" routeId
        --|> attribute "direction_id" directionId
        |> relationshipOne "trip" tripId
        |> relationshipOne "stop" stopId
        |> attribute "stop_sequence" stopSequence
        |> relationshipMaybe "prediction" predictionId
        |> attribute "timepoint" Decode.bool
        |> attribute "departure_time" Iso8601.decoder
        |> attribute "arrival_time" Iso8601.decoder
        |> attribute "pickup_type" pickupDropOffType
        |> attribute "drop_off_type" pickupDropOffType


stopSequence : Decode.Decoder StopSequence
stopSequence =
    Decode.map StopSequence Decode.int


pickupDropOffType : Decode.Decoder PickupDropOffType
pickupDropOffType =
    DecodeHelpers.enum Decode.int
        [ ( 0, PUDO_0_Regular )
        , ( 1, PUDO_1_NotAllowed )
        , ( 2, PUDO_2_PhoneAgency )
        , ( 3, PUDO_3_CoordinateWithDriver )
        ]


tripId : JsonApi.IdDecoder TripId
tripId =
    JsonApi.idDecoder "trip" TripId


trip : JsonApi.ResourceDecoder Trip
trip =
    JsonApi.succeed Trip
        |> id tripId
        |> relationshipOne "service" serviceId
        |> relationshipOne "route" routeId
        |> attribute "direction_id" directionId
        |> relationshipOne "route_pattern" routePatternId
        |> attribute "name" Decode.string
        |> attribute "headsign" Decode.string
        |> relationshipOne "shape" shapeId
        |> attribute "wheelchair_accessible" wheelchairAccessible
        |> attribute "bikes_allowed" bikesAllowed
        |> attribute "block_id" blockId


bikesAllowed : Decode.Decoder BikesAllowed
bikesAllowed =
    DecodeHelpers.enum Decode.int
        [ ( 0, Bikes_0_NoInformation )
        , ( 1, Bikes_1_Allowed )
        , ( 2, Bikes_2_NotAllowed )
        ]


blockId : Decode.Decoder BlockId
blockId =
    Decode.map BlockId Decode.string


serviceId : JsonApi.IdDecoder ServiceId
serviceId =
    JsonApi.idDecoder "service" ServiceId


service : JsonApi.ResourceDecoder Service
service =
    JsonApi.succeed Service
        |> id serviceId
        |> attributeMaybe "description" Decode.string
        |> attributeMaybe "schedule_type" serviceType
        |> attributeMaybe "schedule_name" Decode.string
        |> attribute "schedule_typicality" serviceTypicality
        |> attribute "start_date" serviceDate
        |> attribute "end_date" serviceDate
        |> attribute "valid_days" (Decode.list Decode.int)
        |> custom (changedDates "added_dates" "added_dates_notes")
        |> custom (changedDates "removed_dates" "removed_dates_notes")


serviceDate : Decode.Decoder ServiceDate
serviceDate =
    Decode.map Mbta.serviceDateFromIso8601 Decode.string


serviceType : Decode.Decoder ServiceType
serviceType =
    DecodeHelpers.enum Decode.string
        [ ( "Weekday", ServiceType_Weekday )
        , ( "Saturday", ServiceType_Saturday )
        , ( "Sunday", ServiceType_Sunday )
        , ( "Other", ServiceType_Other )
        ]


serviceTypicality : Decode.Decoder ServiceTypicality
serviceTypicality =
    DecodeHelpers.enum Decode.int
        [ ( 0, ServiceTypicality_0_NotDefined )
        , ( 1, ServiceTypicality_1_Typical )
        , ( 2, ServiceTypicality_2_ExtraService )
        , ( 3, ServiceTypicality_3_ReducedHoliday )
        , ( 4, ServiceTypicality_4_PlannedDisruption )
        , ( 5, ServiceTypicality_5_WeatherDisruption )
        ]


changedDates : String -> String -> JsonApi.ResourceDecoder (List ChangedDate)
changedDates datesAttribute notesAttribute =
    JsonApi.succeed Tuple.pair
        |> attribute datesAttribute (Decode.list serviceDate)
        |> attribute notesAttribute (Decode.list (Decode.nullable Decode.string))
        |> JsonApi.andThen
            (\( datesList, notesList ) ->
                if List.length datesList == List.length notesList then
                    JsonApi.succeed
                        (List.map2
                            ChangedDate
                            datesList
                            notesList
                        )

                else
                    JsonApi.fail
                        (String.concat
                            [ "Couldn't match dates to notes. "
                            , datesAttribute
                            , " and "
                            , notesAttribute
                            , " were different lengths"
                            ]
                        )
            )


shapeId : JsonApi.IdDecoder ShapeId
shapeId =
    JsonApi.idDecoder "shape" ShapeId


shape : JsonApi.ResourceDecoder Shape
shape =
    JsonApi.succeed Shape
        |> id shapeId
        |> attribute "name" Decode.string
        |> relationshipOne "route" routeId
        |> attribute "direction_id" directionId
        |> relationshipMany "stops" stopId
        |> attribute "priority" Decode.int
        |> attribute "polyline" Decode.string



-- Stop Data


stopId : JsonApi.IdDecoder StopId
stopId =
    JsonApi.idDecoder "stop" StopId


stop : JsonApi.ResourceDecoder Stop
stop =
    JsonApi.succeed Stop
        |> id stopId
        |> attribute "name" Decode.string
        |> attributeMaybe "description" Decode.string
        |> relationshipMaybe "parent_station" stopId
        |> attributeMaybe "platform_code" Decode.string
        |> attributeMaybe "platform_name" Decode.string
        |> attribute "location_type" locationType
        |> custom maybeLatLng
        |> attributeMaybe "address" Decode.string
        |> attribute "wheelchair_boarding" wheelchairAccessible


locationType : Decode.Decoder LocationType
locationType =
    DecodeHelpers.enum Decode.int
        [ ( 0, LocationType_0_Stop )
        , ( 1, LocationType_1_Station )
        , ( 2, LocationType_2_Entrance )
        , ( 3, LocationType_3_Node )
        ]


facilityId : JsonApi.IdDecoder FacilityId
facilityId =
    JsonApi.idDecoder "facility" FacilityId


facility : JsonApi.ResourceDecoder Facility
facility =
    JsonApi.succeed Facility
        |> id facilityId
        |> relationshipOne "stop" stopId
        |> attribute "name" Decode.string
        |> attribute "type" (Decode.map FacilityType Decode.string)
        |> custom maybeLatLng
        |> attribute "properties" facilityProperties


liveFacilityId : JsonApi.IdDecoder FacilityId
liveFacilityId =
    JsonApi.idDecoder "live-facility" FacilityId


liveFacility : JsonApi.ResourceDecoder LiveFacility
liveFacility =
    JsonApi.succeed LiveFacility
        |> id liveFacilityId
        |> attribute "updated_at" Iso8601.decoder
        |> attribute "properties" facilityProperties


facilityProperties : Decode.Decoder FacilityProperties
facilityProperties =
    Decode.map2 Tuple.pair
        (Decode.field "name" Decode.string)
        (Decode.field "value" facilityPropertyValue)
        |> Decode.list
        |> Decode.map group


facilityPropertyValue : Decode.Decoder FacilityPropertyValue
facilityPropertyValue =
    Decode.oneOf
        [ Decode.map FacilityProperty_String Decode.string
        , Decode.map FacilityProperty_Int Decode.int
        , Decode.null FacilityProperty_Null
        ]


group : List ( comparable, a ) -> Dict.Dict comparable (List a)
group nameValuePairs =
    List.foldr
        (\( name, value ) dict ->
            Dict.update name
                (\maybeExistingValues ->
                    case maybeExistingValues of
                        Nothing ->
                            Just [ value ]

                        Just existingValues ->
                            Just (value :: existingValues)
                )
                dict
        )
        Dict.empty
        nameValuePairs



-- Alert Data


alertId : JsonApi.IdDecoder AlertId
alertId =
    JsonApi.idDecoder "alert" AlertId


alert : JsonApi.ResourceDecoder Alert
alert =
    JsonApi.succeed Alert
        |> id alertId
        |> attributeMaybe "url" Decode.string
        |> attribute "short_header" Decode.string
        |> attribute "header" Decode.string
        |> attributeMaybe "description" Decode.string
        |> attribute "created_at" Iso8601.decoder
        |> attribute "updated_at" Iso8601.decoder
        |> attributeMaybe "timeframe" Decode.string
        |> attribute "active_period" (Decode.list activePeriod)
        |> attribute "severity" Decode.int
        |> attribute "service_effect" Decode.string
        |> attribute "lifecycle" alertLifecycle
        |> attribute "effect" Decode.string
        |> attribute "cause" Decode.string
        --|> relationshipMaybe "facility" facilityId
        |> attribute "informed_entity" (Decode.list informedEntity)


alertLifecycle : Decode.Decoder AlertLifecycle
alertLifecycle =
    DecodeHelpers.enum Decode.string
        [ ( "NEW", Alert_New )
        , ( "ONGOING", Alert_Ongoing )
        , ( "ONGOING_UPCOMING", Alert_OngoingUpcoming )
        , ( "UPCOMING", Alert_Upcoming )
        ]


activePeriod : Decode.Decoder ActivePeriod
activePeriod =
    Decode.map2
        (\start end -> { start = start, end = end })
        (Decode.field "start" Iso8601.decoder)
        (Decode.field "end" (Decode.nullable Iso8601.decoder))


informedEntity : Decode.Decoder InformedEntity
informedEntity =
    Decode.succeed InformedEntity
        |> Pipeline.required "activities" (Decode.list informedEntityActivity)
        |> pipelineMaybe "route_type" routeType
        |> pipelineMaybe "route" (Decode.map RouteId Decode.string)
        |> pipelineMaybe "direction_id" directionId
        |> pipelineMaybe "trip" (Decode.map TripId Decode.string)
        |> pipelineMaybe "stop" (Decode.map StopId Decode.string)
        |> pipelineMaybe "facility" (Decode.map FacilityId Decode.string)


informedEntityActivity : Decode.Decoder InformedEntityActivity
informedEntityActivity =
    DecodeHelpers.enum Decode.string
        [ ( "BOARD", Activity_Board )
        , ( "BRINGING_BIKE", Activity_BringingBike )
        , ( "EXIT", Activity_Exit )
        , ( "PARK_CAR", Activity_ParkCar )
        , ( "RIDE", Activity_Ride )
        , ( "STORE_BIKE", Activity_StoreBike )
        , ( "USING_ESCALATOR", Activity_UsingEscalator )
        , ( "USING_WHEELCHAIR", Activity_UsingWheelchair )
        ]


pipelineMaybe : String -> Decode.Decoder a -> Decode.Decoder (Maybe a -> b) -> Decode.Decoder b
pipelineMaybe field decoder =
    Pipeline.optional field (Decode.map Just decoder) Nothing
