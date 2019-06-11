module JsonApi exposing
    ( Document, documentDecoder, decodeOne, decodeMany
    , ResourceDecoder, IdDecoder, idDecoder
    , decode, id, attribute, relationshipOne, relationshipMaybe, relationshipMany, custom
    , map, andThen
    , DocumentError, documentErrorToString, ResourceError, resourceErrorToString, IdError, idErrorToString
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

    bookDecoder : ResourceDecoder Book
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
                                |> Result.mapError (Http.BadBody << JsonApi.documentErrorToString)
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

@docs ResourceDecoder, IdDecoder, idDecoder


# Pipelines

You can make `ResourceDecoder`s using a pipeline, modeled off of [`NoRedInk/elm-json-decode-pipeline`](Pipeline)
[Pipeline][https://package.elm-lang.org/packages/NoRedInk/elm-json-decode-pipeline/latest/Json-Decode-Pipeline]

@docs decode, id, attribute, relationshipOne, relationshipMaybe, relationshipMany, custom


# Fancy Decoding

@docs map, andThen


# Error Handling

@docs DocumentError, documentErrorToString, ResourceError, resourceErrorToString, IdError, idErrorToString

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
    | DocumentApiErrors (List Decode.Value)


{-| -}
documentDecoder : Decode.Decoder Document
documentDecoder =
    Decode.oneOf
        [ Decode.succeed DocumentApiErrors
            |> Pipeline.required "errors" (Decode.list Decode.value)
        , Decode.succeed (\data included -> DocumentOne { data = data, included = included })
            |> Pipeline.required "data" resourceJsonDecoder
            |> Pipeline.optional "included" (Decode.list resourceJsonDecoder) []
        , Decode.succeed (\data included -> DocumentMany { data = data, included = included })
            |> Pipeline.required "data" (Decode.list resourceJsonDecoder)
            |> Pipeline.optional "included" (Decode.list resourceJsonDecoder) []
        ]


{-| Turn an untyped [`Document`](#Document) representing a single resource into typed data.

Fails if the document has a list of resources.

-}
decodeOne : ResourceDecoder a -> Document -> Result DocumentError a
decodeOne resourceDecoder document =
    case document of
        DocumentOne { data } ->
            resourceDecoder data
                |> Result.mapError ResourceError

        DocumentMany _ ->
            Err ExpectedOne

        DocumentApiErrors errors ->
            Err (ApiErrors errors)


{-| Turn an untyped [`Document`](#Document) representing a list of resources into typed data.

Fails if the document has only a single resource.

-}
decodeMany : ResourceDecoder a -> Document -> Result DocumentError (List a)
decodeMany resourceDecoder document =
    case document of
        DocumentOne _ ->
            Err ExpectedMany

        DocumentMany { data } ->
            data
                |> List.map resourceDecoder
                |> Result.Extra.combine
                |> Result.mapError ResourceError

        DocumentApiErrors errors ->
            Err (ApiErrors errors)



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


resourceJsonDecoder : Decode.Decoder Resource
resourceJsonDecoder =
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


{-| A `ResourceDecoder` knows how to turn untyped JSON:API data into usable Elm data.

Note that this is a different type than `Json.Decode.Decoder`.
A `JsonApi.ResourceDecoder` is specifically for working with JSON in the JSON:API format.
It does not know how to work on general JSON.

It's used by [`decodeOne`](#decodeOne) and [`decodeMany`](#decodeMany)
to decode the untyped data in a [`Document`](#Document)

-}
type alias ResourceDecoder a =
    Resource -> Result ResourceError a


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
    ResourceId -> Result IdError a


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
            { expectedType = typeString
            , actualType = resourceId.resourceType
            , actualIdValue = resourceId.id
            }



-- Pipelines


{-| Start a decoding pipeline.

Note that while [`NoRedInk/elm-json-decode-pipeline`](Pipeline) starts its pipelines with `Json.Decode.succeed`,
the different `ResourceDecoder` type in this module needs to start its pipelines slightly differently

    bookDecoder : ResourceDecoder Book
    bookDecoder resource =
        decode resource
            |> id bookIdDecoder
            |> attribute "title" Decode.string

[Pipeline](https://package.elm-lang.org/packages/NoRedInk/elm-json-decode-pipeline/latest/Json-Decode-Pipeline)

-}
decode : constructor -> ResourceDecoder constructor
decode constructor =
    \resource -> Ok constructor


{-| Use an id within a pipeline

This is for the id of the resource being decoded.
For the id of a related resource, use one of the `relationship` functions below.

-}
id : IdDecoder id -> ResourceDecoder (id -> rest) -> ResourceDecoder rest
id idDecoder_ =
    custom
        (\resource ->
            idDecoder_ resource.id
                |> Result.mapError ResourceIdError
        )


{-| Use a resource's attribute within a pipeline

Since attributes can be arbitrary JSON, this function takes a general use `Json.Decode.Decoder`.

-}
attribute : String -> Decode.Decoder attribute -> ResourceDecoder (attribute -> rest) -> ResourceDecoder rest
attribute attributeName attributeDecoder =
    custom
        (\resource ->
            case Dict.get attributeName resource.attributes of
                Just attributeJson ->
                    Decode.decodeValue attributeDecoder attributeJson
                        |> Result.mapError (AttributeDecodeError attributeName)

                Nothing ->
                    Err (AttributeMissing attributeName)
        )


{-| Use a to-one relationship that must exist in a pipeline.

This will add an id to the result.
It will not look up the object in the `includes` and inline it.

-}
relationshipOne : String -> IdDecoder relatedId -> ResourceDecoder (relatedId -> rest) -> ResourceDecoder rest
relationshipOne relationshipName relatedIdDecoder =
    custom
        (\resource ->
            case Dict.get relationshipName resource.relationships of
                Just (RelationshipOne relatedResourceId) ->
                    relatedIdDecoder relatedResourceId
                        |> Result.mapError (RelationshipIdError relationshipName)

                _ ->
                    Err (RelationshipNumberError relationshipName "Expected exactly one relationship")
        )


{-| Use a to-one relationship that might not exist in a pipeline

The result will be `Nothing` if

  - There's no relationship with the given name.
  - There's a relationship without a `data` field.
  - There's a relationship whose data is `null`.

-}
relationshipMaybe : String -> IdDecoder relatedId -> ResourceDecoder (Maybe relatedId -> rest) -> ResourceDecoder rest
relationshipMaybe relationshipName relatedIdDecoder =
    custom
        (\resource ->
            case Dict.get relationshipName resource.relationships of
                Just (RelationshipOne relatedResourceId) ->
                    relatedIdDecoder relatedResourceId
                        |> Result.map Just
                        |> Result.mapError (RelationshipIdError relationshipName)

                Just RelationshipMissing ->
                    Ok Nothing

                Nothing ->
                    Ok Nothing

                Just (RelationshipMany _) ->
                    Err (RelationshipNumberError relationshipName "Expected one or zero relationship but got a list")
        )


{-| Use a to-many relationship in a pipeline

Defaults to `[]` if

  - There's no relationship with the given name.

Fails to decode if

  - There's a relationship without a `data` field.
  - There's a relationship whose data is `null`.

-}
relationshipMany : String -> IdDecoder relatedId -> ResourceDecoder (List relatedId -> rest) -> ResourceDecoder rest
relationshipMany relationshipName relatedIdDecoder =
    custom
        (\resource ->
            case Dict.get relationshipName resource.relationships of
                Just (RelationshipMany relatedResourceIds) ->
                    relatedResourceIds
                        |> List.map relatedIdDecoder
                        |> Result.Extra.combine
                        |> Result.mapError (RelationshipIdError relationshipName)

                Nothing ->
                    Ok []

                Just RelationshipMissing ->
                    Err (RelationshipNumberError relationshipName "Expected a list of relationships but it was missing")

                Just (RelationshipOne _) ->
                    Err (RelationshipNumberError relationshipName "Expected a list of relationships but only got one")
        )


{-| Run an arbitrary [`ResourceDecoder`](#ResourceDecoder) and include its result in the pipeline

Useful for decoding complex objects

-}
custom : ResourceDecoder a -> ResourceDecoder (a -> rest) -> ResourceDecoder rest
custom resourceDecoder constructorDecoder =
    \resource ->
        Result.map2
            (\x consructor -> consructor x)
            (resourceDecoder resource)
            (constructorDecoder resource)



-- Fancy Decoding


{-| Apply a function to the result of a resourceDecoder if it succeeds
-}
map : (a -> b) -> ResourceDecoder a -> ResourceDecoder b
map f resourceDecoder =
    \resource ->
        resourceDecoder resource
            |> Result.map f


{-| Run another resourceDecoder that depends on a previous result.
-}
andThen : (a -> Result String b) -> ResourceDecoder a -> ResourceDecoder b
andThen second first =
    \resource ->
        first resource
            |> Result.andThen (second >> Result.mapError CustomError)



-- Error handling
-- TODO tolerate and recover from resource errors. new error type that returns a list of results


{-| Describes what went wrong when running a [`ResourceDecoder`](#ResourceDecoder) on a [`Document`](#Document)

This will happen if a document has valid JSON:API, but the decoder does not know how to understand it.

This is different from [`Json.Decode.Error`](#https://package.elm-lang.org/packages/elm/json/1.1.3/Json-Decode#Error),
which might happen if the raw json does not follow the JSON:API spec.

See the error with [`errorToString`](#errorToString)

TODO cases

-}
type DocumentError
    = ExpectedOne
    | ExpectedMany
    | ApiErrors (List Decode.Value)
    | ResourceError ResourceError


{-| -}
documentErrorToString : DocumentError -> String
documentErrorToString documentError =
    case documentError of
        ExpectedOne ->
            "Expected one resource but got a list"

        ExpectedMany ->
            "Expected a list of resources but only got one"

        ApiErrors errors ->
            "API returned errors: " ++ Encode.encode 2 (Encode.list identity errors)

        ResourceError resourceError ->
            resourceErrorToString resourceError


{-| TODO cases
-}
type ResourceError
    = ResourceIdError IdError
    | AttributeMissing String
    | AttributeDecodeError String Decode.Error
    | RelationshipIdError String IdError
    | RelationshipNumberError String String
    | CustomError String


{-| -}
resourceErrorToString : ResourceError -> String
resourceErrorToString error =
    case error of
        ResourceIdError idError ->
            "Error decoding resource id: " ++ idErrorToString idError

        AttributeMissing attributeName ->
            "Expected attribute " ++ attributeName ++ ", but it's missing"

        AttributeDecodeError attributeName decodeError ->
            String.concat
                [ "Failed to decode attribute "
                , attributeName
                , ": "
                , Decode.errorToString decodeError
                ]

        RelationshipIdError relationshipName idError ->
            String.concat
                [ "Couldn't decode id of relationship "
                , relationshipName
                , ": "
                , idErrorToString idError
                ]

        RelationshipNumberError relationshipName message ->
            String.concat
                [ "Error at relationship "
                , relationshipName
                , ": "
                , message
                ]

        CustomError s ->
            s


{-| -}
type alias IdError =
    { expectedType : String
    , actualType : String
    , actualIdValue : String
    }


{-| -}
idErrorToString : IdError -> String
idErrorToString idError =
    String.concat
        [ "Tried to decode {type: "
        , idError.actualType
        , ", id: "
        , idError.actualIdValue
        , "} as type "
        , idError.expectedType
        ]
