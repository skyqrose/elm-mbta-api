module JsonApi exposing (Resource, ResourceId, decodeResource)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)


type alias ResourceId =
    { typeString : String
    , id : String
    }


type alias Resource =
    { id : ResourceId
    , attributes : Dict String Decode.Value
    , relationships : List ResourceId
    }


decodeResource : Decoder Resource
decodeResource =
    Decode.fail "TODO"
