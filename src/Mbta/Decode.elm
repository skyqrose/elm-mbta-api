module Mbta.Decode exposing
    ( service
    , shape
    , stop
    , trip
    , vehicle
    )

import DecodeHelpers
import Dict
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import JsonApi
    exposing
        ( attribute
        , custom
        , id
        , relationshipMany
        , relationshipMaybe
        , relationshipOne
        )
import Mbta exposing (..)


latLng : JsonApi.Resource -> Decoder LatLng
latLng =
    JsonApi.decode LatLng
        |> attribute "latitude" Decode.float
        |> attribute "longitude" Decode.float


currentStatus : Decoder CurrentStatus
currentStatus =
    DecodeHelpers.enum Decode.string
        [ ( "INCOMING_AT", IncomingAt )
        , ( "STOPPED_AT", StoppedAt )
        , ( "IN_TRANSIT_TO", InTransitTo )
        ]


directionId : Decoder DirectionId
directionId =
    DecodeHelpers.enum Decode.int
        [ ( 0, D0 )
        , ( 1, D1 )
        ]


serviceDate : Decoder ServiceDate
serviceDate =
    Decode.map ServiceDate Decode.string


stopSequence : Decoder StopSequence
stopSequence =
    Decode.map StopSequence Decode.int


wheelchairAccessible : Decoder WheelchairAccessible
wheelchairAccessible =
    DecodeHelpers.enum Decode.int
        [ ( 0, Accessible_0_NoInformation )
        , ( 1, Accessible_1_Accessible )
        , ( 2, Accessible_2_Inaccessible )
        ]


routeId : JsonApi.ResourceId -> Decoder RouteId
routeId =
    JsonApi.idDecoder "route" RouteId


routePatternId : JsonApi.ResourceId -> Decoder RoutePatternId
routePatternId =
    JsonApi.idDecoder "route_pattern" RoutePatternId


serviceId : JsonApi.ResourceId -> Decoder ServiceId
serviceId =
    JsonApi.idDecoder "service" ServiceId


service : JsonApi.Resource -> Decoder Service
service =
    JsonApi.decode Service
        |> id serviceId
        |> attribute "description" (Decode.nullable Decode.string)
        |> attribute "schedule_type" (Decode.nullable scheduleType)
        |> attribute "schedule_name" (Decode.nullable Decode.string)
        |> attribute "schedule_typicality" serviceTypicality
        |> attribute "start_date" serviceDate
        |> attribute "end_date" serviceDate
        |> attribute "valid_days" (Decode.list Decode.int)
        |> custom (changedDates "added_dates" "added_dates_notes")
        |> custom (changedDates "removed_dates" "removed_dates_notes")


scheduleType : Decoder ScheduleType
scheduleType =
    DecodeHelpers.enum Decode.string
        [ ( "Weekday", ScheduleType_Weekday )
        , ( "Saturday", ScheduleType_Saturday )
        , ( "Sunday", ScheduleType_Sunday )
        , ( "Other", ScheduleType_Other )
        ]


serviceTypicality : Decoder ServiceTypicality
serviceTypicality =
    DecodeHelpers.enum Decode.int
        [ ( 0, ServiceTypicality_0_NotDefined )
        , ( 1, ServiceTypicality_1_Typical )
        , ( 2, ServiceTypicality_2_ExtraService )
        , ( 3, ServiceTypicality_3_ReducedHoliday )
        , ( 4, ServiceTypicality_4_PlannedDisruption )
        , ( 5, ServiceTypicality_5_WeatherDisruption )
        ]


changedDates : String -> String -> (JsonApi.Resource -> Decoder (List ChangedDate))
changedDates datesAttribute notesAttribute =
    (JsonApi.decode Tuple.pair
        |> attribute datesAttribute (Decode.list serviceDate)
        |> attribute notesAttribute (Decode.list (Decode.nullable Decode.string))
    )
        >> Decode.andThen
            (\( datesList, notesList ) ->
                if List.length datesList == List.length notesList then
                    Decode.succeed
                        (List.map2
                            ChangedDate
                            datesList
                            notesList
                        )

                else
                    Decode.fail
                        (String.concat
                            [ datesAttribute
                            , " and "
                            , notesAttribute
                            , " were different lengths"
                            ]
                        )
            )


shapeId : JsonApi.ResourceId -> Decoder ShapeId
shapeId =
    JsonApi.idDecoder "shape" ShapeId


shape : JsonApi.Resource -> Decoder Shape
shape =
    JsonApi.decode Shape
        |> id shapeId
        |> attribute "name" Decode.string
        |> relationshipOne "route" routeId
        |> attribute "direction_id" directionId
        |> relationshipMany "stops" stopId
        |> attribute "priority" Decode.int
        |> attribute "polyline" Decode.string


stopId : JsonApi.ResourceId -> Decoder StopId
stopId =
    JsonApi.idDecoder "stop" StopId


stop : JsonApi.Resource -> Decoder Stop
stop =
    JsonApi.decode Stop
        |> id stopId
        |> attribute "name" Decode.string
        |> attribute "description" (Decode.nullable Decode.string)
        |> relationshipMaybe "parent_station" stopId
        |> attribute "platform_code" (Decode.nullable Decode.string)
        |> attribute "platform_name" (Decode.nullable Decode.string)
        |> attribute "location_type" locationType
        |> custom latLng
        |> attribute "address" (Decode.nullable Decode.string)
        |> attribute "wheelchair_boarding" wheelchairAccessible


locationType : Decoder LocationType
locationType =
    DecodeHelpers.enum Decode.int
        [ ( 0, LocationType_0_Stop )
        , ( 1, LocationType_1_Station )
        , ( 2, LocationType_2_Entrance )
        ]


tripId : JsonApi.ResourceId -> Decoder TripId
tripId =
    JsonApi.idDecoder "trip" TripId


trip : JsonApi.Resource -> Decoder Trip
trip =
    JsonApi.decode Trip
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


blockId : Decoder BlockId
blockId =
    Decode.map BlockId Decode.string


bikesAllowed : Decoder BikesAllowed
bikesAllowed =
    DecodeHelpers.enum Decode.int
        [ ( 0, Bikes_0_NoInformation )
        , ( 1, Bikes_1_Allowed )
        , ( 2, Bikes_2_NotAllowed )
        ]


vehicleId : JsonApi.ResourceId -> Decoder VehicleId
vehicleId =
    JsonApi.idDecoder "vehicle" VehicleId


vehicle : JsonApi.Resource -> Decoder Vehicle
vehicle =
    JsonApi.decode Vehicle
        |> id vehicleId
        |> attribute "label" Decode.string
        |> relationshipOne "route" routeId
        |> attribute "direction_id" directionId
        |> relationshipOne "trip" tripId
        |> relationshipOne "stop" stopId
        |> attribute "current_stop_sequence" stopSequence
        |> attribute "current_status" currentStatus
        |> custom latLng
        |> attribute "speed" (Decode.nullable Decode.float)
        |> attribute "bearing" Decode.int
        |> attribute "updated_at" Iso8601.decoder
