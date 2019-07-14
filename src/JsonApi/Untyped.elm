module JsonApi.Untyped exposing
    ( Attributes
    , Document(..)
    , Relationship(..)
    , Relationships
    , Resource
    , ResourceId
    , documentDecoder
    )

{-| JSON:API data that's been decoded into its JSON:API structure,
but not yet decoded into application-specific types.

Internal to the JSON:API library.

-}

import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline


type Document
    = DocumentOne
        { data : Resource
        , included : List Resource
        }
    | DocumentMany
        { data : List Resource
        , included : List Resource
        }
    | DocumentApiErrors (List Decode.Value)


documentDecoder : Decode.Decoder Document
documentDecoder =
    Decode.oneOf
        [ Decode.succeed DocumentApiErrors
            |> Pipeline.required "errors" (Decode.list Decode.value)
        , Decode.succeed (\data included -> DocumentOne { data = data, included = included })
            |> Pipeline.required "data" resourceDecoder
            |> Pipeline.optional "included" (Decode.list resourceDecoder) []
        , Decode.succeed (\data included -> DocumentMany { data = data, included = included })
            |> Pipeline.required "data" (Decode.list resourceDecoder)
            |> Pipeline.optional "included" (Decode.list resourceDecoder) []
        ]


type alias ResourceId =
    { resourceType : String
    , id : String
    }


type alias Resource =
    { id : ResourceId
    , attributes : Attributes
    , relationships : Relationships
    }


type alias Attributes =
    Dict String Decode.Value


type alias Relationships =
    Dict String Relationship


{-| RelationshipMissing

    "relationshipName": {
        "data": null
    }

RelationshipOne

    "relationshipName": {
        "data": {
            "id": "id",
            "type": "type"
        }
    }

RelationshipMany

    "relationshipName": {
        "data": [
            {
                "id": "id",
                "type": "type"
            },
            ...
        ]
    }

TODO:
where does relationshipName: {/_maybe other fields but not data_/} go?

-}
type Relationship
    = RelationshipMissing
    | RelationshipOne ResourceId
    | RelationshipMany (List ResourceId)


resourceDecoder : Decode.Decoder Resource
resourceDecoder =
    Decode.succeed Resource
        |> Pipeline.custom resourceIdDecoder
        -- TODO attributes is optional. have default
        |> Pipeline.required "attributes" (Decode.dict Decode.value)
        |> Pipeline.optional "relationships" (Decode.dict relationshipDecoder) Dict.empty


relationshipDecoder : Decode.Decoder Relationship
relationshipDecoder =
    Decode.oneOf
        [ Decode.field "data" <|
            Decode.oneOf
                [ Decode.null RelationshipMissing
                , Decode.map RelationshipOne resourceIdDecoder
                , Decode.map RelationshipMany (Decode.list resourceIdDecoder)
                ]
        , Decode.succeed RelationshipMissing
        ]


resourceIdDecoder : Decode.Decoder ResourceId
resourceIdDecoder =
    Decode.succeed ResourceId
        |> Pipeline.required "type" Decode.string
        |> Pipeline.required "id" Decode.string
