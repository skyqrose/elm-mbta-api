module Mbta.Decode exposing
    ( route
    , routePattern
    , service
    , shape
    , stop
    , trip
    , vehicle
    )

import DecodeHelpers
import Dict
import Iso8601
import Json.Decode as Decode
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


color : Decode.Decoder Color
color =
    Decode.map Color Decode.string


latLng : JsonApi.Decoder LatLng
latLng =
    JsonApi.decode LatLng
        |> attribute "latitude" Decode.float
        |> attribute "longitude" Decode.float


currentStatus : Decode.Decoder CurrentStatus
currentStatus =
    DecodeHelpers.enum Decode.string
        [ ( "INCOMING_AT", IncomingAt )
        , ( "STOPPED_AT", StoppedAt )
        , ( "IN_TRANSIT_TO", InTransitTo )
        ]


directionId : Decode.Decoder DirectionId
directionId =
    DecodeHelpers.enum Decode.int
        [ ( 0, D0 )
        , ( 1, D1 )
        ]


routeType : Decode.Decoder RouteType
routeType =
    DecodeHelpers.enum Decode.int
        [ ( 0, RouteType_0_LightRail )
        , ( 1, RouteType_1_HeavyRail )
        , ( 2, RouteType_2_CommuterRail )
        , ( 3, RouteType_3_Bus )
        , ( 4, RouteType_4_Ferry )
        ]


serviceDate : Decode.Decoder ServiceDate
serviceDate =
    Decode.map ServiceDate Decode.string


stopSequence : Decode.Decoder StopSequence
stopSequence =
    Decode.map StopSequence Decode.int


wheelchairAccessible : Decode.Decoder WheelchairAccessible
wheelchairAccessible =
    DecodeHelpers.enum Decode.int
        [ ( 0, Accessible_0_NoInformation )
        , ( 1, Accessible_1_Accessible )
        , ( 2, Accessible_2_Inaccessible )
        ]


routeId : JsonApi.IdDecoder RouteId
routeId =
    JsonApi.idDecoder "route" RouteId


route : JsonApi.Decoder Route
route =
    JsonApi.decode Route
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


routeDirections : JsonApi.Decoder (Maybe RouteDirections)
routeDirections =
    (JsonApi.decode Tuple.pair
        |> attribute "direction_names" (Decode.nullable (Decode.list Decode.string))
        |> attribute "direction_destinations" (Decode.nullable (Decode.list Decode.string))
    )
        >> Decode.andThen
            (\( names, destinations ) ->
                case ( names, destinations ) of
                    ( Just [ d0_name, d1_name ], Just [ d0_destination, d1_destination ] ) ->
                        Decode.succeed
                            (Just
                                { d0 = { name = d0_name, destination = d0_destination }
                                , d1 = { name = d1_name, destination = d1_destination }
                                }
                            )

                    ( Nothing, Nothing ) ->
                        Decode.succeed Nothing

                    _ ->
                        Decode.fail "expected exactly 2 direction_names and exactly 2 direction_destinations"
            )


routePatternId : JsonApi.IdDecoder RoutePatternId
routePatternId =
    JsonApi.idDecoder "route_pattern" RoutePatternId


routePattern : JsonApi.Decoder RoutePattern
routePattern =
    JsonApi.decode RoutePattern
        |> id routePatternId
        |> relationshipOne "route" routeId
        |> attribute "direction_id" directionId
        |> attribute "name" Decode.string
        |> attribute "typicality" routePatternTypicality
        |> attribute "time_desc" (Decode.nullable Decode.string)
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


serviceId : JsonApi.IdDecoder ServiceId
serviceId =
    JsonApi.idDecoder "service" ServiceId


service : JsonApi.Decoder Service
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


scheduleType : Decode.Decoder ScheduleType
scheduleType =
    DecodeHelpers.enum Decode.string
        [ ( "Weekday", ScheduleType_Weekday )
        , ( "Saturday", ScheduleType_Saturday )
        , ( "Sunday", ScheduleType_Sunday )
        , ( "Other", ScheduleType_Other )
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


changedDates : String -> String -> JsonApi.Decoder (List ChangedDate)
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


shapeId : JsonApi.IdDecoder ShapeId
shapeId =
    JsonApi.idDecoder "shape" ShapeId


shape : JsonApi.Decoder Shape
shape =
    JsonApi.decode Shape
        |> id shapeId
        |> attribute "name" Decode.string
        |> relationshipOne "route" routeId
        |> attribute "direction_id" directionId
        |> relationshipMany "stops" stopId
        |> attribute "priority" Decode.int
        |> attribute "polyline" Decode.string


stopId : JsonApi.IdDecoder StopId
stopId =
    JsonApi.idDecoder "stop" StopId


stop : JsonApi.Decoder Stop
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


locationType : Decode.Decoder LocationType
locationType =
    DecodeHelpers.enum Decode.int
        [ ( 0, LocationType_0_Stop )
        , ( 1, LocationType_1_Station )
        , ( 2, LocationType_2_Entrance )
        ]


tripId : JsonApi.IdDecoder TripId
tripId =
    JsonApi.idDecoder "trip" TripId


trip : JsonApi.Decoder Trip
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


blockId : Decode.Decoder BlockId
blockId =
    Decode.map BlockId Decode.string


bikesAllowed : Decode.Decoder BikesAllowed
bikesAllowed =
    DecodeHelpers.enum Decode.int
        [ ( 0, Bikes_0_NoInformation )
        , ( 1, Bikes_1_Allowed )
        , ( 2, Bikes_2_NotAllowed )
        ]


vehicleId : JsonApi.IdDecoder VehicleId
vehicleId =
    JsonApi.idDecoder "vehicle" VehicleId


vehicle : JsonApi.Decoder Vehicle
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
