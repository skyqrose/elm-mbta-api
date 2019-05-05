module Mbta.Decode exposing
    ( stop
    , stopId
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


latLng : JsonApi.Resource -> Decoder LatLng
latLng =
    JsonApi.decode LatLng
        |> attribute "latitude" Decode.float
        |> attribute "longitude" Decode.float


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
