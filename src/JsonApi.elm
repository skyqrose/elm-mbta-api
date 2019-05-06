module JsonApi exposing
    ( Decoder, IdDecoder, idDecoder
    , decode, id, attribute, relationshipOne, relationshipMaybe, relationshipMany, custom
    , decoderOne, decoderMany
    )

{-| This module serves as a middle point between the raw JSON in JSON:API
and the Elm types for the data you get out of it.

    type BookId
        = BookId String

    type alias Book =
        { id : BookId
        , author : AuthorId
        , title : String
        }

    bookIdDecoder : IdDecoder BookId
    bookIdDecoder =
        idDecoder "book" BookId

    bookDecoder : Decoder Book
    bookDecoder resource =
        decode resource
            |> id bookIdDecoder
            |> relationshipOne "author" authorIdDecoder
            |> attribute "title" Json.Decode.string

    Http.get
        { url = url
        , expect = expectJson toMsg (decoderOne bookDecoder)
        }

@docs Decoder, IdDecoder, idDecoder


# Pipelines

You can make `Decoder`s using a pipeline, modeled off of [`NoRedInk/elm-json-decode-pipeline`](Pipeline)
[Pipeline][https://package.elm-lang.org/packages/NoRedInk/elm-json-decode-pipeline/latest/Json-Decode-Pipeline]

@docs decode, id, attribute, relationshipOne, relationshipMaybe, relationshipMany, custom


# Running a Decoder

@docs decoderOne, decoderMany

-}

import DecodeHelpers
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline



-- TODO map2 instead of Tuple.Pair >> andThen
-- Internal Document Format


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


type Relationship
    = RelationshipMissing
    | RelationshipOne ResourceId
    | RelationshipMany (List ResourceId)


resourceDecoder : Decode.Decoder Resource
resourceDecoder =
    Decode.succeed Resource
        |> Pipeline.custom resourceIdDecoder
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



-- Public


{-| A `Decoder` knows how to turn untyped JSON:API data into usable Elm data.

Note that this is a different type than `Json.Decode.Decoder`.
A `JsonApi.Decoder` is specifically for working with JSON in the JSON:API format.
It does not know how to work on general JSON.

To turn this into a more general `Json.Decode.Decoder` and run it,
see [`decoderOne`](#decoderOne) or [`decoderMany`](#decoderMany)

-}
type alias Decoder a =
    Resource -> Decode.Decoder a


{-| JSON:API represents ids as

    {
        "type": "book",
        "id": "0-06-443017-0"
    }

which works fine for dynamically typed languages,
but doesn't work well with Elm's type system.
An `IdDecoder` know how to convert those ids into typesafe Elm objects

Create an `IdDecoder` with [`idDecoder`](#idDecoder)

-}
type alias IdDecoder a =
    ResourceId -> Decode.Decoder a


{-| Create an [`IdDecoder`](#IdDecoder)

    type BookId
        = BookId String

    bookIdDecoder : IdDecoder BookId
    bookIdDecoder =
        idDecoder "book" BookId

The `String` provided will be checked against the JSON:API's `type` field.
If it doesn't match, decoding will fail.
This provides protection that one id type can not be accidentally confused with another.

It's recommended that you wrap id types with a custom type with one variant, like `BookId` above.
This lets the Elm Compiler check that different id types don't get mixed up within your Elm code.
`idDecoder` needs that constructor.

-}
idDecoder : String -> (String -> id) -> IdDecoder id
idDecoder typeString idConstructor resourceId =
    if resourceId.resourceType == typeString then
        Decode.succeed (idConstructor resourceId.id)

    else
        Decode.fail
            (String.concat
                [ "Tried to decode {type: "
                , resourceId.resourceType
                , ", id: "
                , resourceId.id
                , "} as type "
                , typeString
                ]
            )



-- Pipeline


{-| Start a decoding pipeline.

Note that while [`NoRedInk/elm-json-decode-pipeline`](Pipeline) starts its pipelines with `Json.Decode.succeed`,
the different `Decoder` type in this module needs to start its pipelines slightly differently

    bookDecoder : Decoder Book
    bookDecoder resource =
        decode resource
            |> id bookIdDecoder
            |> attribute "title" Decode.string

[Pipeline](https://package.elm-lang.org/packages/NoRedInk/elm-json-decode-pipeline/latest/Json-Decode-Pipeline)

-}
decode : constructor -> Decoder constructor
decode constructor =
    \resource -> Decode.succeed constructor


{-| Use an id within a pipeline

This is for the id of the resource being decoded.
For the id of a related resource, use one of the `relationship` functions below.

-}
id : IdDecoder id -> Decoder (id -> rest) -> Decoder rest
id idDecoder_ =
    custom
        (\resource ->
            idDecoder_ resource.id
        )


{-| Use a resource's attribute within a pipeline

Since attributes can be arbitrary JSON, this function takes a general use `Json.Decode.Decoder`.

-}
attribute : String -> Decode.Decoder attribute -> Decoder (attribute -> rest) -> Decoder rest
attribute attributeName attributeDecoder =
    custom
        (\resource ->
            case Dict.get attributeName resource.attributes of
                Just attributeJson ->
                    case Decode.decodeValue attributeDecoder attributeJson of
                        Ok attribute_ ->
                            Decode.succeed attribute_

                        Err error ->
                            Decode.fail (Decode.errorToString error)

                Nothing ->
                    Decode.fail ("Expected attribute " ++ attributeName ++ ", but it's missing")
        )


{-| Use a to-one relationship that must exist in a pipeline.

This will add an id to the result.
It will not look up the object in the `includes` and inline it.

-}
relationshipOne : String -> IdDecoder relatedId -> Decoder (relatedId -> rest) -> Decoder rest
relationshipOne relationshipName relatedIdDecoder =
    custom
        (\resource ->
            case Dict.get relationshipName resource.relationships of
                Just (RelationshipOne relatedResourceId) ->
                    relatedIdDecoder relatedResourceId

                _ ->
                    Decode.fail ("Expected resource to have exactly one relationship " ++ relationshipName)
        )


{-| Use a to-one relationship that might not exist in a pipeline

The result will be `Nothing` if

  - There's no relationship with the given name.
  - There's a relationship without a `data` field.
  - There's a relationship whose data is `null`.

-}
relationshipMaybe : String -> IdDecoder relatedId -> Decoder (Maybe relatedId -> rest) -> Decoder rest
relationshipMaybe relationshipName relatedIdDecoder =
    custom
        (\resource ->
            case Dict.get relationshipName resource.relationships of
                Just (RelationshipOne relatedResourceId) ->
                    relatedIdDecoder relatedResourceId
                        |> Decode.map Just

                Just RelationshipMissing ->
                    Decode.succeed Nothing

                Nothing ->
                    Decode.succeed Nothing

                Just (RelationshipMany _) ->
                    Decode.fail
                        (String.concat
                            [ "Expected resource to have exactly one relationship "
                            , relationshipName
                            , ", but got a list"
                            ]
                        )
        )


{-| Use a to-many relationship in a pipeline

Defaults to `[]` if

  - There's no relationship with the given name.

Fails to decode if

  - There's a relationship without a `data` field.
  - There's a relationship whose data is `null`.

-}
relationshipMany : String -> IdDecoder relatedId -> Decoder (List relatedId -> rest) -> Decoder rest
relationshipMany relationshipName relatedIdDecoder =
    let
        fail : String -> Decode.Decoder a
        fail message =
            Decode.fail
                (String.concat
                    [ "Expected resource to have a list of relationships "
                    , relationshipName
                    , ", but "
                    , message
                    ]
                )
    in
    custom
        (\resource ->
            case Dict.get relationshipName resource.relationships of
                Just (RelationshipMany relatedResourceIds) ->
                    relatedResourceIds
                        |> List.map relatedIdDecoder
                        |> DecodeHelpers.all

                Nothing ->
                    Decode.succeed []

                Just RelationshipMissing ->
                    fail "it was missing"

                Just (RelationshipOne _) ->
                    fail "only got one"
        )


{-| Run an arbitrary [`Decoder`](#Decoder) and include its result in the pipeline

Useful for decoding complex objects

-}
custom : Decoder a -> Decoder (a -> rest) -> Decoder rest
custom decoder constructorDecoder =
    \resource ->
        Decode.map2
            (\x consructor -> consructor x)
            (decoder resource)
            (constructorDecoder resource)



-- Run it


{-| Create a `Json.Decode.Decoder` that can decode a JSON:API document representing a single resource
-}
decoderOne : Decoder a -> Decode.Decoder a
decoderOne decoder =
    resourceDecoder
        |> Decode.field "data"
        |> Decode.andThen decoder


{-| Create a `Json.Decode.Decoder` that can decode a JSON:API document representing many resources
-}
decoderMany : Decoder a -> Decode.Decoder (List a)
decoderMany decoder =
    resourceDecoder
        |> Decode.list
        |> Decode.field "data"
        |> Decode.andThen
            (\resources ->
                resources
                    |> List.map decoder
                    |> DecodeHelpers.all
            )
