module Mbta.Decode exposing
    ( stop
    , stopId
    )

import DecodeHelpers
import Dict
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import JsonApi
import Mbta exposing (..)


latLng : JsonApi.Resource -> Decoder LatLng
latLng =
    JsonApi.decode LatLng
        |> JsonApi.attribute "latitude" Decode.float
        |> JsonApi.attribute "longitude" Decode.float


wheelchairAccessible : Decoder WheelchairAccessible
wheelchairAccessible =
    DecodeHelpers.enum Decode.int
        [ ( 0, Accessible_0_NoInformation )
        , ( 0, Accessible_1_Accessible )
        , ( 0, Accessible_2_Inaccessible )
        ]


stopId : JsonApi.ResourceId -> Decoder StopId
stopId =
    JsonApi.idDecoder "stop" StopId


stop : JsonApi.Resource -> Decoder Stop
stop =
    JsonApi.decode Stop
        --|> JsonApi.id stopId
        |> JsonApi.custom (\resource -> Decode.fail "xx")
        |> JsonApi.attribute "name" Decode.string
        |> JsonApi.attribute "description" (Decode.nullable Decode.string)
        --|> JsonApi.relationshipMaybe "parent_station" stopId
        |> JsonApi.custom (\resource -> Decode.fail "xx")
        |> JsonApi.attribute "platform_code" (Decode.nullable Decode.string)
        |> JsonApi.attribute "platform_name" (Decode.nullable Decode.string)
        --|> JsonApi.attribute "location_type" locationType
        |> JsonApi.custom (\resource -> Decode.fail "xx")
        |> JsonApi.custom latLng
        |> JsonApi.attribute "address" (Decode.nullable Decode.string)
        --|> JsonApi.attribute "wheelchair_boarding" wheelchairAccessible
        |> JsonApi.custom (\resource -> Decode.fail "xx")


locationType : Decoder LocationType
locationType =
    DecodeHelpers.enum Decode.int
        [ ( 0, LocationType_0_Stop )
        , ( 1, LocationType_1_Station )
        , ( 2, LocationType_2_Entrance )
        ]
