module JsonApi.Untyped exposing
    ( Attributes
    , Document(..)
    , Relationship(..)
    , Relationships
    , Resource
    , ResourceId
    , documentDecoder
    , resourceDecoder
    , resourceIdDecoder
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


{-| `RelationshipOne Nothing`

    "relationshipName": {
        "data": null
    }

`RelationshipOne (Just resourceId)`

    "relationshipName": {
        "data": {
            "id": "id",
            "type": "type"
        }
    }

`RelationshipMany []`

    "relationshipName": {
        "data": []
    }

`RelationshipMany [...]`

    "relationshipName": {
        "data": [
            {
                "id": "id",
                "type": "type"
            },
            ...
        ]
    }

If a relationship does not have a `data` field,
i.e. it has a `links` or `meta` field instead,
it is not representable by this type.
Instead, it should omitted from the [`Resource`](#Resource)'s `relationships` list.
If `links` or `meta` are ever supported in the future, this may change.

-}
type Relationship
    = RelationshipOne (Maybe ResourceId)
    | RelationshipMany (List ResourceId)


resourceDecoder : Decode.Decoder Resource
resourceDecoder =
    Decode.succeed Resource
        |> Pipeline.custom resourceIdDecoder
        |> Pipeline.optional "attributes" (Decode.dict Decode.value) Dict.empty
        |> Pipeline.optional "relationships" relationshipsDecoder Dict.empty


relationshipsDecoder : Decode.Decoder Relationships
relationshipsDecoder =
    Decode.dict relationshipDecoder
        |> Decode.map filterDict


{-| Removes `Nothing` values
-}
filterDict : Dict comparable (Maybe a) -> Dict comparable a
filterDict dict =
    Dict.foldl
        (\key maybeValue newDict ->
            case maybeValue of
                Nothing ->
                    newDict

                Just value ->
                    Dict.insert key value newDict
        )
        Dict.empty
        dict


{-| Returns `Nothing` if the relationship does not have a `data` field.
-}
relationshipDecoder : Decode.Decoder (Maybe Relationship)
relationshipDecoder =
    Decode.oneOf
        [ Decode.field "data" <|
            Decode.map Just <|
                Decode.oneOf
                    [ Decode.null (RelationshipOne Nothing)
                    , Decode.map (RelationshipOne << Just) resourceIdDecoder
                    , Decode.map RelationshipMany (Decode.list resourceIdDecoder)
                    ]
        , Decode.succeed Nothing
        ]


resourceIdDecoder : Decode.Decoder ResourceId
resourceIdDecoder =
    Decode.succeed ResourceId
        |> Pipeline.required "type" Decode.string
        |> Pipeline.required "id" Decode.string
