module JsonApi exposing
    ( Document, documentData, expectJsonApi, decodeDocumentString, decodeDocumentJsonValue
    , DocumentDecoder, documentDecoderOne, documentDecoderMany, ResourceDecoder, IdDecoder, idDecoder
    , decode, id, attribute, relationshipOne, relationshipMaybe, relationshipMany, custom
    , map, andThen
    , Error(..), errorToString, DocumentError(..), documentErrorToString, ResourceError(..), resourceErrorToString, IdError, idErrorToString
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

    booksDocumentDecoder : DocumentDecoder included (List Book)
    booksDocumentDecoder =
        documentDecoderMany bookDecoder

    getBooks : (Result DocumentError (Document included (List Book)) -> msg) -> Cmd msg
    getBooks toMsg =
        Http.get
            { url = url
            , expect = Http.expectJsonApi toMsg booksDocumentDecoder
            }


# Get a JSON:API document

@docs Document, documentData, expectJsonApi, decodeDocumentString, decodeDocumentJsonValue


# Make decoders

@docs DocumentDecoder, documentDecoderOne, documentDecoderMany, ResourceDecoder, IdDecoder, idDecoder


# Pipelines

You can make `ResourceDecoder`s using a pipeline, modeled off of [`NoRedInk/elm-json-decode-pipeline`](Pipeline)
[Pipeline][https://package.elm-lang.org/packages/NoRedInk/elm-json-decode-pipeline/latest/Json-Decode-Pipeline]

@docs decode, id, attribute, relationshipOne, relationshipMaybe, relationshipMany, custom


# Fancy Decoding

@docs map, andThen


# Error Handling

@docs Error, errorToString, DocumentError, documentErrorToString, ResourceError, resourceErrorToString, IdError, idErrorToString

-}

import DecodeHelpers
import Dict exposing (Dict)
import Http
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Result.Extra



-- TODO map2 instead of Tuple.Pair >> andThen
-- Make an API call


{-| The data returned from a json api endpoint.
-}
type alias Document included data =
    { data : data
    , included : included -> ()
    }


{-| get the data out of a [`Document`](#Document)
-}
documentData : Document included data -> data
documentData document =
    document.data


{-| For passing to [`Http.get`](https://package.elm-lang.org/packages/elm/http/2.0.0/Http#get)
-}
expectJsonApi : (Result Error (Document included data) -> msg) -> DocumentDecoder included data -> Http.Expect msg
expectJsonApi toMsg documentDecoder =
    let
        httpToMsg : Result Http.Error (Result DocumentError (Document included data)) -> msg
        httpToMsg =
            \httpResult ->
                httpResult
                    |> Result.mapError HttpError
                    |> Result.andThen
                        (\documentResult ->
                            documentResult
                                |> Result.mapError DocumentError
                        )
                    |> toMsg

        jsonDecoder : Decode.Decoder (Result DocumentError (Document included data))
        jsonDecoder =
            documentJsonDecoder
                |> Decode.map documentDecoder
    in
    Http.expectJson httpToMsg jsonDecoder


decodeDocumentString : DocumentDecoder included data -> String -> Result Error (Document included data)
decodeDocumentString documentDecoder jsonString =
    jsonString
        |> Decode.decodeString documentJsonDecoder
        |> Result.mapError NoncompliantJson
        |> Result.andThen (documentDecoder >> Result.mapError DocumentError)


decodeDocumentJsonValue : DocumentDecoder included data -> Decode.Value -> Result Error (Document included data)
decodeDocumentJsonValue documentDecoder jsonValue =
    jsonValue
        |> Decode.decodeValue documentJsonDecoder
        |> Result.mapError NoncompliantJson
        |> Result.andThen (documentDecoder >> Result.mapError DocumentError)



-- Untyped internal JsonApi representation


type JsonApiDocument
    = DocumentOne
        { data : Resource
        , included : List Resource
        }
    | DocumentMany
        { data : List Resource
        , included : List Resource
        }
    | DocumentApiErrors (List Decode.Value)


documentJsonDecoder : Decode.Decoder JsonApiDocument
documentJsonDecoder =
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
        |> Pipeline.custom resourceIdJsonDecoder
        |> Pipeline.required "attributes" (Decode.dict Decode.value)
        |> Pipeline.optional "relationships" (Decode.dict relationshipJsonDecoder) Dict.empty


relationshipJsonDecoder : Decode.Decoder Relationship
relationshipJsonDecoder =
    Decode.oneOf
        [ Decode.field "data" <|
            Decode.oneOf
                [ Decode.null RelationshipMissing
                , Decode.map RelationshipOne resourceIdJsonDecoder
                , Decode.map RelationshipMany (Decode.list resourceIdJsonDecoder)
                ]
        , Decode.succeed RelationshipMissing
        ]


resourceIdJsonDecoder : Decode.Decoder ResourceId
resourceIdJsonDecoder =
    Decode.succeed ResourceId
        |> Pipeline.required "type" Decode.string
        |> Pipeline.required "id" Decode.string



-- Public decoders
-- TODO make these opaque


{-| A `DocumentDecoder` knows how to turn JSON:API compliant json data into usable Elm data.

Note that this is a different type than [`Json.Decode.Decoder`](https://package.elm-lang.org/packages/elm/json/1.1.3/Json-Decode#Decoder).

Use it by passing it to [`expectJsonApi`](#expectJsonApi)

-}
type alias DocumentDecoder included data =
    JsonApiDocument -> Result DocumentError (Document included data)


{-| Turn JSON:API compliant json representing a single resource into typed data.

Fails if the document has a list of resources.

-}
documentDecoderOne : ResourceDecoder resource -> DocumentDecoder included resource
documentDecoderOne resourceDecoder =
    \document ->
        case document of
            DocumentOne { data } ->
                resourceDecoder data
                    |> Result.mapError ResourceError
                    |> Result.map
                        (\resource ->
                            { data = resource
                            , included = \_ -> ()
                            }
                        )

            DocumentMany _ ->
                Err ExpectedOne

            DocumentApiErrors errors ->
                Err (ApiErrors errors)


{-| Turn JSON:API compliant json representing a list of resources into typed data.

Fails if the document has only a single resource.

-}
documentDecoderMany : ResourceDecoder resource -> DocumentDecoder included (List resource)
documentDecoderMany resourceDecoder =
    \document ->
        case document of
            DocumentOne _ ->
                Err ExpectedMany

            DocumentMany { data } ->
                data
                    |> List.map resourceDecoder
                    |> Result.Extra.combine
                    |> Result.mapError ResourceError
                    |> Result.map
                        (\resources ->
                            { data = resources
                            , included = \_ -> ()
                            }
                        )

            DocumentApiErrors errors ->
                Err (ApiErrors errors)


{-| A `ResourceDecoder` knows how to turn an untyped JSON:API resource into usable Elm data.

Note that this is a different type than [`Json.Decode.Decoder`](https://package.elm-lang.org/packages/elm/json/1.1.3/Json-Decode#Decoder).
A `JsonApi.ResourceDecoder` is specifically for working with JSON in the JSON:API format.
It does not know how to work on general JSON.

Create one with a [pipeline](#Pipelines)

Use it to create a [`DocumentDecoder`](#DocumentDecoder) with [`documentDecoderOne`](#documentDecoderOne) or [`documentDecoderMany`](#documentDecoderMany)

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

Since attributes can be arbitrary JSON, this function takes a general use [`Json.Decode.Decoder`](https://package.elm-lang.org/packages/elm/json/1.1.3/Json-Decode#Decoder).

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


{-| What went wrong when using [`expectJsonApi`](#expectJsonApi)

See the error with [`errorToString`](#errorToString)

TODO have a `InvalidJsonApi` case

TODO document cases

-}
type Error
    = HttpError Http.Error
    | NoncompliantJson Decode.Error
    | DocumentError DocumentError


errorToString : Error -> String
errorToString error =
    case error of
        HttpError httpError ->
            Debug.toString httpError

        NoncompliantJson decodeError ->
            Decode.errorToString decodeError

        DocumentError documentError ->
            documentErrorToString documentError


{-| Describes what went wrong while trying to create a [`Document`](#Document)

This will happen if a document has valid JSON:API, but the provided [`DocumentDecoder`](#DocumentDecoder) does not know how to understand it.

This is different from [`Json.Decode.Error`](#https://package.elm-lang.org/packages/elm/json/1.1.3/Json-Decode#Error),
which might happen if the raw json does not follow the JSON:API spec.

If a response has json that does not meet the JSON:API spec, it will be a `HttpError Http.BadBody message`

If a response is valid JSON:API, but the `DocumentDecoder` and its `ResourceDecoder`s fail to turn it into Elm data,
the other cases will describe what went wrong.

TODO document cases

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


{-| TODO document cases
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
