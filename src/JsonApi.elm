module JsonApi exposing
    ( Document, documentData, documentIncluded, expectJsonApi, decodeDocumentString, decodeDocumentJsonValue
    , DocumentDecoder, documentDecoderOne, documentDecoderMany, ResourceDecoder, IdDecoder, idDecoder
    , decode, id, attribute, relationshipOne, relationshipMaybe, relationshipMany, custom
    , map, andThen, oneOf
    , decodeResourceString, decodeResourceValue
    , mapId, oneOfId
    , decodeIdString, decodeIdValue
    , IncludedDecoder
    , Error(..), errorToString, DocumentError(..), documentErrorToString, ResourceError(..), resourceErrorToString, IdError, idErrorToString
    )

{-| This module serves as a middle point between the raw JSON in JSON:API
and the Elm types for the data you get out of it.

TODO better summary that gets across this module's role in decoding

TODO I think the bookDecoder is using an old interface for making decoders

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

@docs Document, documentData, documentIncluded, expectJsonApi, decodeDocumentString, decodeDocumentJsonValue


# Make decoders

@docs DocumentDecoder, documentDecoderOne, documentDecoderMany, ResourceDecoder, IdDecoder, idDecoder


# Pipelines

You can make `ResourceDecoder`s using a pipeline, modeled off of [`NoRedInk/elm-json-decode-pipeline`](Pipeline)
[Pipeline][https://package.elm-lang.org/packages/NoRedInk/elm-json-decode-pipeline/latest/Json-Decode-Pipeline]

@docs decode, id, attribute, relationshipOne, relationshipMaybe, relationshipMany, custom


# Fancy Resource Decoding

@docs map, andThen, oneOf

Typically, you will get a whole JSON:API document, and decode the whole thing at once.
But if you get json for a resource outside of its document,
you can decode it with these.

@docs decodeResourceString, decodeResourceValue


# Fancy Id Decoding

@docs mapId, oneOfId

Typically, you will get a whole JSON:API document, and decode the whole thing at once.
But if you get json for an id outside of its document,
you can decode it with these.

@docs decodeIdString, decodeIdValue


# Decoding included resources

The `included` field may contain multiple types of resource objects mixed together.
Elm cannot handle lists with multiple types, so you must define your own collection type,
and provide instructions for how to decode a resource and add it to the collection.

@docs IncludedDecoder


# Decoding resources


# Error Handling

@docs Error, errorToString, DocumentError, documentErrorToString, ResourceError, resourceErrorToString, IdError, idErrorToString

-}

import DecodeHelpers
import Dict exposing (Dict)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import JsonApi.Untyped as Untyped
import Result.Extra



-- TODO map2 instead of Tuple.Pair >> andThen
-- Make an API call


{-| The data returned from a json api endpoint.

Both the `data` type and the `included` type are determined by the [`DocumentDecoder`](#DocumentDecoder) you provide.

-}
type alias Document included data =
    { data : data
    , included : included
    }


{-| get the data out of a [`Document`](#Document)
-}
documentData : Document included data -> data
documentData document =
    document.data


documentIncluded : Document included data -> included
documentIncluded document =
    document.included


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
            Untyped.documentDecoder
                |> Decode.map documentDecoder
    in
    Http.expectJson httpToMsg jsonDecoder


decodeDocumentString : DocumentDecoder included data -> String -> Result Error (Document included data)
decodeDocumentString documentDecoder jsonString =
    jsonString
        |> Decode.decodeString Untyped.documentDecoder
        |> Result.mapError NoncompliantJson
        |> Result.andThen (documentDecoder >> Result.mapError DocumentError)


decodeDocumentJsonValue : DocumentDecoder included data -> Decode.Value -> Result Error (Document included data)
decodeDocumentJsonValue documentDecoder jsonValue =
    jsonValue
        |> Decode.decodeValue Untyped.documentDecoder
        |> Result.mapError NoncompliantJson
        |> Result.andThen (documentDecoder >> Result.mapError DocumentError)



-- Public decoders
-- TODO make these opaque


{-| A `DocumentDecoder` knows how to turn JSON:API compliant json data into usable Elm data.

Note that this is a different type than [`Json.Decode.Decoder`](https://package.elm-lang.org/packages/elm/json/1.1.3/Json-Decode#Decoder).

Use it by passing it to [`expectJsonApi`](#expectJsonApi)

-}
type alias DocumentDecoder included data =
    Untyped.Document -> Result DocumentError (Document included data)


{-| Turn JSON:API compliant json representing a single resource into typed data.

Fails if the document has a list of resources.

-}
documentDecoderOne : IncludedDecoder included -> ResourceDecoder resource -> DocumentDecoder included resource
documentDecoderOne includedDecoder resourceDecoder =
    \untypedDocument ->
        case untypedDocument of
            Untyped.DocumentOne { data, included } ->
                Result.map2
                    (\decodedData decodedIncluded ->
                        { data = decodedData
                        , included = decodedIncluded
                        }
                    )
                    (resourceDecoder data)
                    (decodeIncluded includedDecoder included)
                    |> Result.mapError ResourceError

            Untyped.DocumentMany _ ->
                Err ExpectedOne

            Untyped.DocumentApiErrors errors ->
                Err (ApiErrors errors)


{-| Turn JSON:API compliant json representing a list of resources into typed data.

Fails if the document has only a single resource.

-}
documentDecoderMany : IncludedDecoder included -> ResourceDecoder resource -> DocumentDecoder included (List resource)
documentDecoderMany includedDecoder resourceDecoder =
    \untypedDocument ->
        case untypedDocument of
            Untyped.DocumentOne _ ->
                Err ExpectedMany

            Untyped.DocumentMany { data, included } ->
                Result.map2
                    (\decodedData decodedIncluded ->
                        { data = decodedData
                        , included = decodedIncluded
                        }
                    )
                    (data
                        |> List.map resourceDecoder
                        |> Result.Extra.combine
                    )
                    (decodeIncluded includedDecoder included)
                    |> Result.mapError ResourceError

            Untyped.DocumentApiErrors errors ->
                Err (ApiErrors errors)


{-| A `ResourceDecoder` knows how to turn an untyped JSON:API resource into usable Elm data.

Note that this is a different type than [`Json.Decode.Decoder`](https://package.elm-lang.org/packages/elm/json/1.1.3/Json-Decode#Decoder).
A `JsonApi.ResourceDecoder` is specifically for working with JSON in the JSON:API format.
It does not know how to work on general JSON.

Create one with a [pipeline](#Pipelines)

Use it to create a [`DocumentDecoder`](#DocumentDecoder) with [`documentDecoderOne`](#documentDecoderOne) or [`documentDecoderMany`](#documentDecoderMany)

-}
type alias ResourceDecoder a =
    Untyped.Resource -> Result ResourceError a


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
    Untyped.ResourceId -> Result IdError a


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
idDecoder typeString idConstructor =
    \untypedResourceId ->
        if untypedResourceId.resourceType == typeString then
            Ok (idConstructor untypedResourceId.id)

        else
            Err
                { expectedType = typeString
                , actualType = untypedResourceId.resourceType
                , actualIdValue = untypedResourceId.id
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
    \untypedResource -> Ok constructor


{-| Use an id within a pipeline

This is for the id of the resource being decoded.
For the id of a related resource, use one of the `relationship` functions below.

-}
id : IdDecoder id -> ResourceDecoder (id -> rest) -> ResourceDecoder rest
id idDecoder_ =
    custom
        (\untypedResource ->
            idDecoder_ untypedResource.id
                |> Result.mapError ResourceIdError
        )


{-| Use a resource's attribute within a pipeline

Since attributes can be arbitrary JSON, this function takes a general use [`Json.Decode.Decoder`](https://package.elm-lang.org/packages/elm/json/1.1.3/Json-Decode#Decoder).

-}
attribute : String -> Decode.Decoder attribute -> ResourceDecoder (attribute -> rest) -> ResourceDecoder rest
attribute attributeName attributeDecoder =
    custom
        (\untypedResource ->
            case Dict.get attributeName untypedResource.attributes of
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
        (\untypedResource ->
            case Dict.get relationshipName untypedResource.relationships of
                Just (Untyped.RelationshipOne relatedResourceId) ->
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
        (\untypedResource ->
            case Dict.get relationshipName untypedResource.relationships of
                Just (Untyped.RelationshipOne relatedResourceId) ->
                    relatedIdDecoder relatedResourceId
                        |> Result.map Just
                        |> Result.mapError (RelationshipIdError relationshipName)

                Just Untyped.RelationshipMissing ->
                    Ok Nothing

                Nothing ->
                    Ok Nothing

                Just (Untyped.RelationshipMany _) ->
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
        (\untypedResource ->
            case Dict.get relationshipName untypedResource.relationships of
                Just (Untyped.RelationshipMany relatedResourceIds) ->
                    relatedResourceIds
                        |> List.map relatedIdDecoder
                        |> Result.Extra.combine
                        |> Result.mapError (RelationshipIdError relationshipName)

                Nothing ->
                    Ok []

                Just Untyped.RelationshipMissing ->
                    Err (RelationshipNumberError relationshipName "Expected a list of relationships but it was missing")

                Just (Untyped.RelationshipOne _) ->
                    Err (RelationshipNumberError relationshipName "Expected a list of relationships but only got one")
        )


{-| Run an arbitrary [`ResourceDecoder`](#ResourceDecoder) and include its result in the pipeline

Useful for decoding complex objects

-}
custom : ResourceDecoder a -> ResourceDecoder (a -> rest) -> ResourceDecoder rest
custom resourceDecoder constructorDecoder =
    \untypedResource ->
        Result.map2
            (\x consructor -> consructor x)
            (resourceDecoder untypedResource)
            (constructorDecoder untypedResource)



-- Fancy Resource Decoding


{-| Apply a function to the result of a resourceDecoder if it succeeds
-}
map : (a -> b) -> ResourceDecoder a -> ResourceDecoder b
map f resourceDecoder =
    \untypedResource ->
        resourceDecoder untypedResource
            |> Result.map f


{-| Run another resourceDecoder that depends on a previous result.
-}
andThen : (a -> Result String b) -> ResourceDecoder a -> ResourceDecoder b
andThen second first =
    \untypedResource ->
        first untypedResource
            |> Result.andThen (second >> Result.mapError CustomError)


{-| If you have a resource object that may be one of multiple types,
this will choose the appropriate ResourceDecoder based on the JSON:API type of the object
(the same type as used in [`idDecoder`](#IdDecoder)),

Every result must be the same type, so you may want to use [`map`](#map)
to convert your decoders.

    authorIdFromAnyResource : ResourceDecoder AuthorId
    authorIdFromAnyResource =
        oneOf <|
            Dict.fromList
                [ ( "book", bookDecoder |> map (\book -> book.author) )
                , ( "author", authorDecoder |> map (\author -> id) )
                ]

-}
oneOf : Dict String (ResourceDecoder a) -> ResourceDecoder a
oneOf decoders =
    \untypedResource ->
        case Dict.get untypedResource.id.resourceType decoders of
            Just decoder ->
                decoder untypedResource

            Nothing ->
                let
                    allTypes : String
                    allTypes =
                        decoders
                            |> Dict.keys
                            |> String.join ","
                in
                Err
                    (ResourceIdError
                        { expectedType = "oneOf " ++ allTypes
                        , actualType = untypedResource.id.resourceType
                        , actualIdValue = untypedResource.id.id
                        }
                    )


{-| -}
decodeResourceString : ResourceDecoder a -> String -> Result ResourceError a
decodeResourceString resourceDecoder jsonString =
    jsonString
        |> Decode.decodeString Untyped.resourceDecoder
        |> Result.mapError resourceErrorFromDecodeError
        |> Result.andThen resourceDecoder


{-| -}
decodeResourceValue : ResourceDecoder a -> Decode.Value -> Result ResourceError a
decodeResourceValue resourceDecoder jsonValue =
    jsonValue
        |> Decode.decodeValue Untyped.resourceDecoder
        |> Result.mapError resourceErrorFromDecodeError
        |> Result.andThen resourceDecoder


resourceErrorFromDecodeError : Decode.Error -> ResourceError
resourceErrorFromDecodeError decodeError =
    decodeError
        |> Decode.errorToString
        |> CustomError



-- Fancy Id Decoding


{-| Apply a function to the result of a resourceDecoder if it succeeds
-}
mapId : (a -> b) -> IdDecoder a -> IdDecoder b
mapId f decoder =
    \untypedId ->
        decoder untypedId
            |> Result.map f


{-| If you have an id that may be one of multiple types,
this will choose the appropriate IdDecoder based on the JSON:API type of the object

Every result must be the same type, so you may want to use [`map`](#map)
to convert your decoders.

    authorIdFromAnyResource : ResourceDecoder AuthorId
    authorIdFromAnyResource =
        oneOf <|
            Dict.fromList
                [ ( "book", bookDecoder |> map (\book -> book.author) )
                , ( "author", authorDecoder |> map (\author -> id) )
                ]

-}
oneOfId : Dict String (IdDecoder a) -> IdDecoder a
oneOfId decoders =
    \untypedId ->
        case Dict.get untypedId.resourceType decoders of
            Just decoder ->
                decoder untypedId

            Nothing ->
                let
                    allTypes : String
                    allTypes =
                        decoders
                            |> Dict.keys
                            |> String.join ","
                in
                Err
                    { expectedType = "oneOf " ++ allTypes
                    , actualType = untypedId.resourceType
                    , actualIdValue = untypedId.id
                    }


{-| -}
decodeIdString : IdDecoder a -> String -> Result IdError a
decodeIdString decoder jsonString =
    jsonString
        |> Decode.decodeString Untyped.resourceIdDecoder
        |> Result.mapError idErrorFromDecodeError
        |> Result.andThen decoder


{-| -}
decodeIdValue : IdDecoder a -> Decode.Value -> Result IdError a
decodeIdValue decoder jsonValue =
    jsonValue
        |> Decode.decodeValue Untyped.resourceIdDecoder
        |> Result.mapError idErrorFromDecodeError
        |> Result.andThen decoder



-- TODO standardize on `id` vs `resourceId`


idErrorFromDecodeError : Decode.Error -> IdError
idErrorFromDecodeError decodeError =
    -- TODO a not-hacky way to represent Decode.Error. (resourceErrorFromDecodeError too)
    { expectedType = ""
    , actualType = "decode error"
    , actualIdValue = Decode.errorToString decodeError
    }



-- Decoding included resources


{-| This library doesn't know your application's types and needs,
so you will need to provide your own collection type for included data,
and a way to add a resource to that collection.

In JSON:API, the included field may contain resources of multiple different types mixed together,
so you may wish to make your accumulator with [`oneOf`](#oneOf) to sort them out.

`included` is the resulting application-specific collection of resources.
`accumulator` decodes each resource and says how to add it to the collection.

When decoding, the [`DocumentDecoder`](#DocumentDecoder) will reduce over the list of included resources,
and use the resulting function to add the new resource to the collection.

    { emptyIncluded =
        { books = []
        , authors = []
        }
    , accumulator =
        oneOf <|
            Dict.fromList
                [ ( "book"
                  , bookResourceDecoder
                        |> JsonApi.map
                            (\book ->
                                \included ->
                                    { included
                                        | books = book :: included.books
                                    }
                            )
                  )
                , ( "author"
                  , authorResourceDecoder
                        |> JsonApi.map
                            (\author ->
                                \included ->
                                    { included
                                        | authors = author :: included.authors
                                    }
                            )
                  )
                ]
    }

-}
type alias IncludedDecoder included =
    { emptyIncluded : included
    , accumulator : ResourceDecoder (included -> included)
    }


decodeIncluded : IncludedDecoder included -> List Untyped.Resource -> Result ResourceError included
decodeIncluded { emptyIncluded, accumulator } untypedResources =
    List.foldl
        (\untypedResource previousResult ->
            previousResult
                |> Result.andThen
                    (\previousIncluded ->
                        untypedResource
                            |> accumulator
                            |> Result.map (\newAccumulator -> newAccumulator previousIncluded)
                    )
        )
        (Ok emptyIncluded)
        untypedResources



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



-- TODO include the resource id in the error/string, so it's easier to track down


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
