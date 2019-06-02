module JsonApi exposing
    ( Document, documentDecoder, decodeOne, decodeMany
    , Decoder, IdDecoder, idDecoder
    , decode, id, attribute, relationshipOne, relationshipMaybe, relationshipMany, custom
    , andThen
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

    getBook : (Result Http.Error Book -> msg) -> Cmd msg
    getBook toMsg =
        let
            documentToMsg : Result Http.Error JsonApi.Document -> msg
            documentToMsg result =
                result
                    |> Result.andThen
                        (\document ->
                            document
                                |> JsonApi.decodeOne bookDecoder
                                |> Result.mapError Http.BadBody
                        )
                    |> toMsg
        in
        Http.get
            { url = url
            , expect = Http.expectJson documentToMsg JsonApi.documentDecoder
            }


# Decode a document

@docs Document, documentDecoder, decodeOne, decodeMany


# Make decoders

@docs Decoder, IdDecoder, idDecoder


# Pipelines

You can make `Decoder`s using a pipeline, modeled off of [`NoRedInk/elm-json-decode-pipeline`](Pipeline)
[Pipeline][https://package.elm-lang.org/packages/NoRedInk/elm-json-decode-pipeline/latest/Json-Decode-Pipeline]

@docs decode, id, attribute, relationshipOne, relationshipMaybe, relationshipMany, custom


# Fancy Decoding

@docs andThen

-}

import DecodeHelpers
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Result.Extra



-- TODO map2 instead of Tuple.Pair >> andThen
-- Decode a document


{-| A structured but untyped representation of the data returned by a JSON:API compliant endpoint
-}
type Document
    = DocumentOne
        { data : Resource
        , included : List Resource
        }
    | DocumentMany
        { data : List Resource
        , included : List Resource
        }
    | Errors (List Decode.Value)


{-| -}
documentDecoder : Decode.Decoder Document
documentDecoder =
    Decode.oneOf
        [ Decode.succeed Errors
            |> Pipeline.required "errors" (Decode.list Decode.value)
        , Decode.succeed (\data included -> DocumentOne { data = data, included = included })
            |> Pipeline.required "data" resourceDecoder
            |> Pipeline.optional "included" (Decode.list resourceDecoder) []
        , Decode.succeed (\data included -> DocumentMany { data = data, included = included })
            |> Pipeline.required "data" (Decode.list resourceDecoder)
            |> Pipeline.optional "included" (Decode.list resourceDecoder) []
        ]


{-| Turn an untyped [`Document`](#Document) representing a single resource into typed data.

Fails if the document has a list of resources.

-}
decodeOne : Decoder a -> Document -> Result String a
decodeOne decoder document =
    case document of
        DocumentOne { data } ->
            decoder data

        DocumentMany _ ->
            Err "Expected one resource but got a list"

        Errors errors ->
            Err (Encode.encode 2 (Encode.list identity errors))


{-| Turn an untyped [`Document`](#Document) representing a list of resources into typed data.

Fails if the document has only a single resource.

-}
decodeMany : Decoder a -> Document -> Result String (List a)
decodeMany decoder document =
    case document of
        DocumentOne _ ->
            Err "Expected a list of resources but only got one"

        DocumentMany { data } ->
            data
                |> List.map decoder
                |> Result.Extra.combine

        Errors errors ->
            Err (Encode.encode 2 (Encode.list identity errors))



-- Private internal data types


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



-- Make decoders
-- TODO make these opaque


{-| A `Decoder` knows how to turn untyped JSON:API data into usable Elm data.

Note that this is a different type than `Json.Decode.Decoder`.
A `JsonApi.Decoder` is specifically for working with JSON in the JSON:API format.
It does not know how to work on general JSON.

It's used by [`decodeOne`](#decodeOne) and [`decodeMany`](#decodeMany)
to decode the untyped data in a [`Document`](#Document)

-}
type alias Decoder a =
    Resource -> Result String a


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
    ResourceId -> Result String a


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
        Ok (idConstructor resourceId.id)

    else
        Err
            (String.concat
                [ "Tried to decode {type: "
                , resourceId.resourceType
                , ", id: "
                , resourceId.id
                , "} as type "
                , typeString
                ]
            )



-- Pipelines


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
    \resource -> Ok constructor


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
                    Decode.decodeValue attributeDecoder attributeJson
                        |> Result.mapError Decode.errorToString

                Nothing ->
                    Err ("Expected attribute " ++ attributeName ++ ", but it's missing")
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
                    Err ("Expected resource to have exactly one relationship " ++ relationshipName)
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
                        |> Result.map Just

                Just RelationshipMissing ->
                    Ok Nothing

                Nothing ->
                    Ok Nothing

                Just (RelationshipMany _) ->
                    Err
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
    custom
        (\resource ->
            case Dict.get relationshipName resource.relationships of
                Just (RelationshipMany relatedResourceIds) ->
                    relatedResourceIds
                        |> List.map relatedIdDecoder
                        |> Result.Extra.combine

                Nothing ->
                    Ok []

                Just RelationshipMissing ->
                    Err
                        (String.concat
                            [ "Expected resource to have a list of relationships "
                            , relationshipName
                            , ", but it was missing"
                            ]
                        )

                Just (RelationshipOne _) ->
                    Err
                        (String.concat
                            [ "Expected resource to have a list of relationships "
                            , relationshipName
                            , ", but only got one"
                            ]
                        )
        )


{-| Run an arbitrary [`Decoder`](#Decoder) and include its result in the pipeline

Useful for decoding complex objects

-}
custom : Decoder a -> Decoder (a -> rest) -> Decoder rest
custom decoder constructorDecoder =
    \resource ->
        Result.map2
            (\x consructor -> consructor x)
            (decoder resource)
            (constructorDecoder resource)



-- Fancy Decoding


{-| Run another decoder that depends on a previous result.
-}
andThen : (a -> Result String b) -> Decoder a -> Decoder b
andThen second first =
    \resource ->
        first resource
            |> Result.andThen second
