module JsonApi exposing
    ( Document, documentData, documentIncluded
    , get, expectJsonApi, decodeDocumentString, decodeDocumentValue
    , DocumentDecoder, documentDecoderOne, documentDecoderMany, ResourceDecoder, IdDecoder, idDecoder
    , succeed, id, attribute, attributeMaybe, relationshipOne, relationshipMaybe, relationshipMany, custom
    , map, andThen, oneOf, fail
    , decodeResourceString, decodeResourceValue
    , mapId, oneOfId
    , decodeIdString, decodeIdValue
    , IncludedDecoder, ignoreIncluded
    , HttpError(..), httpErrorToString, DecodeError(..), decodeErrorToString, DocumentError(..), documentErrorToString, ResourceError(..), resourceErrorToString, IdError, idErrorToString
    )

{-| This module is for getting and decoding JSON:API data into Elm data.

Like working with normal JSON data, you will need to build decoders for your data,
and decoding into them might fail.

JSON:API data is not recursive like JSON is,
so there are separate decoder and error types for each part of the heirarchy:
documents, resources, and ids.

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
    bookDecoder =
        succeed Book
            |> id bookIdDecoder
            |> relationshipOne "author" authorIdDecoder
            |> attribute "title" Json.Decode.string

    booksDocumentDecoder : DocumentDecoder () (List Book)
    booksDocumentDecoder =
        documentDecoderMany ignoreIncluded bookDecoder

    getBooks : (Result HttpError (List Book) -> msg) -> Cmd msg
    getBooks toMsg =
        get
            toMsg
            booksDocumentDecoder
            booksUrl

Many parts of the JSON:API spec, such as links, metadata, and pagination, are not supported.
Encoding, creating, and updating JSON:API data is also not supported.


# Get a JSON:API document

@docs Document, documentData, documentIncluded
@docs get, expectJsonApi, decodeDocumentString, decodeDocumentValue


# Make decoders

@docs DocumentDecoder, documentDecoderOne, documentDecoderMany, ResourceDecoder, IdDecoder, idDecoder


# Pipelines

You can make `ResourceDecoder`s using a pipeline, modeled off of [`NoRedInk/elm-json-decode-pipeline`](Pipeline)
[Pipeline][https://package.elm-lang.org/packages/NoRedInk/elm-json-decode-pipeline/latest/Json-Decode-Pipeline]

@docs succeed, id, attribute, attributeMaybe, relationshipOne, relationshipMaybe, relationshipMany, custom


# Fancy Resource Decoding

@docs map, andThen, oneOf, fail

Typically, you will get a whole JSON:API document, and decode the whole thing at once.
But if you get JSON for a resource outside of its document,
you can decode it with these.

@docs decodeResourceString, decodeResourceValue


# Fancy Id Decoding

@docs mapId, oneOfId

Typically, you will get a whole JSON:API document, and decode the whole thing at once.
But if you get JSON for an id outside of its document,
you can decode it with these.

@docs decodeIdString, decodeIdValue


# Decoding included resources

@docs IncludedDecoder, ignoreIncluded


# Error Handling

-- TODO include the JSON in the error

@docs HttpError, httpErrorToString, DecodeError, decodeErrorToString, DocumentError, documentErrorToString, ResourceError, resourceErrorToString, IdError, idErrorToString

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


{-| get the collection of included resources out of a [`Document`](#Document)
-}
documentIncluded : Document included data -> included
documentIncluded document =
    document.included


{-| Calls [`Http.get`](https://package.elm-lang.org/packages/elm/http/2.0.0/Http#get) and decodes the JSON:API document returned
-}
get : (Result HttpError (Document included data) -> msg) -> DocumentDecoder included data -> String -> Cmd msg
get toMsg documentDecoder url =
    Http.get
        { url = url
        , expect = expectJsonApi toMsg documentDecoder
        }


{-| For passing to [`Http.get`](https://package.elm-lang.org/packages/elm/http/2.0.0/Http#get)
-}
expectJsonApi : (Result HttpError (Document included data) -> msg) -> DocumentDecoder included data -> Http.Expect msg
expectJsonApi toMsg documentDecoder =
    let
        httpResultToJsonApiResult : Result Http.Error Decode.Value -> Result HttpError (Document included data)
        httpResultToJsonApiResult httpResult =
            case httpResult of
                Ok jsonValue ->
                    jsonValue
                        |> decodeDocumentValue documentDecoder
                        |> Result.mapError DecodeDocumentError

                Err httpError ->
                    Err (HttpError httpError)
    in
    Http.expectJson (httpResultToJsonApiResult >> toMsg) Decode.value


{-| -}
decodeDocumentString : DocumentDecoder included data -> String -> Result (DecodeError DocumentError) (Document included data)
decodeDocumentString documentDecoder jsonString =
    decodeString Untyped.documentDecoder decodeDocument documentDecoder jsonString


{-| -}
decodeDocumentValue : DocumentDecoder included data -> Decode.Value -> Result (DecodeError DocumentError) (Document included data)
decodeDocumentValue documentDecoder jsonValue =
    decodeValue Untyped.documentDecoder decodeDocument documentDecoder jsonValue



-- Public decoders


{-| A `DocumentDecoder` knows how to turn JSON:API compliant json data into usable Elm data.

Note that this is a different type than [`Json.Decode.Decoder`](https://package.elm-lang.org/packages/elm/json/1.1.3/Json-Decode#Decoder).

Use it by passing it to [`expectJsonApi`](#expectJsonApi)

-}
type DocumentDecoder included data
    = DocumentDecoder (Untyped.Document -> Result DocumentError (Document included data))


{-| Turn JSON:API compliant json representing a single resource into typed data.

Fails if the document has a list of resources.

-}
documentDecoderOne : IncludedDecoder included -> ResourceDecoder resource -> DocumentDecoder included resource
documentDecoderOne includedDecoder resourceDecoder =
    DocumentDecoder
        (\untypedDocument ->
            case untypedDocument of
                Untyped.DocumentOne { data, included } ->
                    Result.map2
                        (\decodedData decodedIncluded ->
                            { data = decodedData
                            , included = decodedIncluded
                            }
                        )
                        (decodeResource resourceDecoder data)
                        (decodeIncluded includedDecoder included)
                        |> Result.mapError ResourceError

                Untyped.DocumentMany _ ->
                    Err ExpectedOne

                Untyped.DocumentApiErrors errors ->
                    Err (ApiErrors errors)
        )


{-| Turn JSON:API compliant json representing a list of resources into typed data.

Fails if the document has only a single resource.

-}
documentDecoderMany : IncludedDecoder included -> ResourceDecoder resource -> DocumentDecoder included (List resource)
documentDecoderMany includedDecoder resourceDecoder =
    DocumentDecoder
        (\untypedDocument ->
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
                            |> List.map (decodeResource resourceDecoder)
                            |> Result.Extra.combine
                        )
                        (decodeIncluded includedDecoder included)
                        |> Result.mapError ResourceError

                Untyped.DocumentApiErrors errors ->
                    Err (ApiErrors errors)
        )


{-| A `ResourceDecoder` knows how to turn an untyped JSON:API resource into usable Elm data.

Note that this is a different type than [`Json.Decode.Decoder`](https://package.elm-lang.org/packages/elm/json/1.1.3/Json-Decode#Decoder).
A `JsonApi.ResourceDecoder` is specifically for working with JSON in the JSON:API format.
It does not know how to work on general JSON.

Create one with a [pipeline](#Pipelines)

Use it to create a [`DocumentDecoder`](#DocumentDecoder) with [`documentDecoderOne`](#documentDecoderOne) or [`documentDecoderMany`](#documentDecoderMany)

-}
type ResourceDecoder a
    = ResourceDecoder (Untyped.Resource -> Result ResourceError a)


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
type IdDecoder a
    = IdDecoder (Untyped.ResourceId -> Result IdError a)


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
    IdDecoder
        (\untypedResourceId ->
            if untypedResourceId.resourceType == typeString then
                Ok (idConstructor untypedResourceId.id)

            else
                Err
                    { expectedType = [ typeString ]
                    , actualType = untypedResourceId.resourceType
                    , actualIdValue = untypedResourceId.id
                    }
        )



-- Pipelines


{-| Start a decoding pipeline.

Just like [`NoRedInk/elm-json-decode-pipeline`](Pipeline) starts its [`Json.Decode.Decoder`](Decode) pipelines with [`Json.Decode.succeed`](Decodesucceed),
[`ResourceDecoder`](#ResourceDecoder) pipelines start with `succeed`.

    bookDecoder : ResourceDecoder Book
    bookDecoder =
        succeed Book
            |> id bookIdDecoder
            |> attribute "title" Decode.string

[Pipeline](https://package.elm-lang.org/packages/NoRedInk/elm-json-decode-pipeline/latest/Json-Decode-Pipeline)
[Decoder](https://package.elm-lang.org/packages/elm/json/latest/Json-Decode#Decoder)
[Decodesucceed](https://package.elm-lang.org/packages/elm/json/latest/Json-Decode#succeed)

It's named `succeed` because it can also be used to make a [`ResourceDecoder`](#ResourceDecoder) that ignores its input and always succeeds with the given value.

The type argument is named `constructor` because in its use in a pipeline,
the first value of the pipeline is the constructor function for the resulting data type,
which is then applied to later parts of the pieline.

-}
succeed : constructor -> ResourceDecoder constructor
succeed constructor =
    ResourceDecoder (\untypedResource -> Ok constructor)


{-| Use an id within a pipeline

This is for the id of the resource being decoded.
For the id of a related resource, use one of the `relationship` functions below.

TODO better name for idDecoder\_ (and everywhere else that name appears). Maybe name will become free with new way to make id decoders

-}
id : IdDecoder id -> ResourceDecoder (id -> rest) -> ResourceDecoder rest
id idDecoder_ =
    custom
        (ResourceDecoder
            (\untypedResource ->
                untypedResource.id
                    |> decodeId idDecoder_
                    |> Result.mapError ResourceIdError
            )
        )


{-| Use a resource's attribute within a pipeline

Since attributes can be arbitrary JSON, this function takes a general use [`Json.Decode.Decoder`](https://package.elm-lang.org/packages/elm/json/1.1.3/Json-Decode#Decoder).

-}
attribute : String -> Decode.Decoder attribute -> ResourceDecoder (attribute -> rest) -> ResourceDecoder rest
attribute attributeName attributeDecoder =
    custom
        (ResourceDecoder
            (\untypedResource ->
                case Dict.get attributeName untypedResource.attributes of
                    Just attributeJson ->
                        attributeJson
                            |> Decode.decodeValue attributeDecoder
                            |> Result.mapError (AttributeDecodeError attributeName)

                    Nothing ->
                        Err (AttributeMissing attributeName)
            )
        )


{-| Decodes `null` or missing attributes into `Nothing`.

Since attributes can be arbitrary JSON, this function takes a general use [`Json.Decode.Decoder`](https://package.elm-lang.org/packages/elm/json/1.1.3/Json-Decode#Decoder).

If decoding the attribute fails, the whole `ResourceDecoder` will fail, rather than silently returning a `Nothing`.

-}
attributeMaybe : String -> Decode.Decoder attribute -> ResourceDecoder (Maybe attribute -> rest) -> ResourceDecoder rest
attributeMaybe attributeName attributeDecoder =
    custom
        (ResourceDecoder
            (\untypedResource ->
                case Dict.get attributeName untypedResource.attributes of
                    Just attributeJson ->
                        attributeJson
                            |> Decode.decodeValue (Decode.nullable attributeDecoder)
                            |> Result.mapError (AttributeDecodeError attributeName)

                    Nothing ->
                        Ok Nothing
            )
        )


{-| Use a to-one relationship that must exist in a pipeline.

This will add an id to the result.
It will not look up the object in the `includes` and inline it.

-}
relationshipOne : String -> IdDecoder relatedId -> ResourceDecoder (relatedId -> rest) -> ResourceDecoder rest
relationshipOne relationshipName relatedIdDecoder =
    custom
        (ResourceDecoder
            (\untypedResource ->
                case Dict.get relationshipName untypedResource.relationships of
                    Just (Untyped.RelationshipOne relatedId) ->
                        relatedId
                            |> decodeId relatedIdDecoder
                            |> Result.mapError (RelationshipIdError relationshipName)

                    _ ->
                        Err (RelationshipNumberError relationshipName "Expected exactly one relationship")
            )
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
        (ResourceDecoder
            (\untypedResource ->
                case Dict.get relationshipName untypedResource.relationships of
                    Just (Untyped.RelationshipOne relatedId) ->
                        relatedId
                            |> decodeId relatedIdDecoder
                            |> Result.map Just
                            |> Result.mapError (RelationshipIdError relationshipName)

                    Just Untyped.RelationshipMissing ->
                        Ok Nothing

                    Nothing ->
                        Ok Nothing

                    Just (Untyped.RelationshipMany _) ->
                        Err (RelationshipNumberError relationshipName "Expected one or zero relationship but got a list")
            )
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
        (ResourceDecoder
            (\untypedResource ->
                case Dict.get relationshipName untypedResource.relationships of
                    Just (Untyped.RelationshipMany relatedIds) ->
                        relatedIds
                            |> List.map (decodeId relatedIdDecoder)
                            |> Result.Extra.combine
                            |> Result.mapError (RelationshipIdError relationshipName)

                    Nothing ->
                        Ok []

                    Just Untyped.RelationshipMissing ->
                        Err (RelationshipNumberError relationshipName "Expected a list of relationships but it was missing")

                    Just (Untyped.RelationshipOne _) ->
                        Err (RelationshipNumberError relationshipName "Expected a list of relationships but only got one")
            )
        )


{-| Run an arbitrary [`ResourceDecoder`](#ResourceDecoder) and include its result in the pipeline

Useful for decoding complex objects

-}
custom : ResourceDecoder a -> ResourceDecoder (a -> rest) -> ResourceDecoder rest
custom resourceDecoder constructorDecoder =
    ResourceDecoder
        (\untypedResource ->
            Result.map2
                (\x consructor -> consructor x)
                (decodeResource resourceDecoder untypedResource)
                (decodeResource constructorDecoder untypedResource)
        )



-- Fancy Resource Decoding


{-| Apply a function to the result of a [`ResourceDecoder`](#ResourceDecoder) if it succeeds
-}
map : (a -> b) -> ResourceDecoder a -> ResourceDecoder b
map f resourceDecoder =
    ResourceDecoder
        (\untypedResource ->
            decodeResource resourceDecoder untypedResource
                |> Result.map f
        )


{-| Run another [`ResourceDecoder`](#ResourceDecoder) that depends on a previous result.
-}
andThen : (a -> ResourceDecoder b) -> ResourceDecoder a -> ResourceDecoder b
andThen secondDecoder firstDecoder =
    ResourceDecoder
        (\untypedResource ->
            untypedResource
                |> decodeResource firstDecoder
                |> Result.andThen
                    (\first ->
                        decodeResource (secondDecoder first) untypedResource
                    )
        )


{-| If you have a resource object that may be one of multiple types,
this will choose the appropriate ResourceDecoder based on the JSON:API type of the object
(the same resource type as used by [`idDecoder`](#IdDecoder)),

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
oneOf resourceDecoders =
    ResourceDecoder
        (\untypedResource ->
            case Dict.get untypedResource.id.resourceType resourceDecoders of
                Just resourceDecoder ->
                    decodeResource resourceDecoder untypedResource

                Nothing ->
                    Err
                        (ResourceIdError
                            { expectedType = Dict.keys resourceDecoders
                            , actualType = untypedResource.id.resourceType
                            , actualIdValue = untypedResource.id.id
                            }
                        )
        )


{-| A [`ResourceDecoder`](#ResourceDecoder) that always fails with the given message
-}
fail : String -> ResourceDecoder a
fail message =
    ResourceDecoder
        (\untypedResource ->
            Err (Failure message)
        )


{-| -}
decodeResourceString : ResourceDecoder a -> String -> Result (DecodeError ResourceError) a
decodeResourceString resourceDecoder jsonString =
    decodeString Untyped.resourceDecoder decodeResource resourceDecoder jsonString


{-| -}
decodeResourceValue : ResourceDecoder a -> Decode.Value -> Result (DecodeError ResourceError) a
decodeResourceValue resourceDecoder jsonValue =
    decodeValue Untyped.resourceDecoder decodeResource resourceDecoder jsonValue



-- Fancy Id Decoding


{-| Apply a function to the result of a resourceDecoder if it succeeds
-}
mapId : (a -> b) -> IdDecoder a -> IdDecoder b
mapId f idDecoder_ =
    IdDecoder
        (\untypedId ->
            untypedId
                |> decodeId idDecoder_
                |> Result.map f
        )


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

-- TODO make it impossible for a conflict between the expected type in the Dict (used) and in the IdDecoder (ignored).
-- TODO maybe by passing in the constructor instead of an IdDecoder?

-}
oneOfId : Dict String (IdDecoder a) -> IdDecoder a
oneOfId idDecoders =
    IdDecoder
        (\untypedId ->
            case Dict.get untypedId.resourceType idDecoders of
                Just idDecoder_ ->
                    decodeId idDecoder_ untypedId

                Nothing ->
                    Err
                        { expectedType = Dict.keys idDecoders
                        , actualType = untypedId.resourceType
                        , actualIdValue = untypedId.id
                        }
        )


{-| -}
decodeIdString : IdDecoder a -> String -> Result (DecodeError IdError) a
decodeIdString idDecoder_ jsonString =
    decodeString Untyped.resourceIdDecoder decodeId idDecoder_ jsonString


{-| -}
decodeIdValue : IdDecoder a -> Decode.Value -> Result (DecodeError IdError) a
decodeIdValue idDecoder_ jsonValue =
    decodeValue Untyped.resourceIdDecoder decodeId idDecoder_ jsonValue



-- Decoding included resources


{-| The `included` field may contain multiple types of resource objects mixed together.
Elm cannot handle lists with multiple types, so you must define your own collection type,
and provide instructions for how to decode a resource and add it to the collection.

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

TODO opaque IncludedDecoder, and ways to build it.

-}
type alias IncludedDecoder included =
    { emptyIncluded : included
    , accumulator : ResourceDecoder (included -> included)
    }


{-| If you don't care about the included data, this will ignore it
-}
ignoreIncluded : IncludedDecoder ()
ignoreIncluded =
    { emptyIncluded = ()
    , accumulator = succeed (\() -> ())
    }


decodeIncluded : IncludedDecoder included -> List Untyped.Resource -> Result ResourceError included
decodeIncluded { emptyIncluded, accumulator } untypedResources =
    List.foldl
        (\untypedResource previousResult ->
            previousResult
                |> Result.andThen
                    (\previousIncluded ->
                        untypedResource
                            |> decodeResource accumulator
                            |> Result.map (\newAccumulator -> newAccumulator previousIncluded)
                    )
        )
        (Ok emptyIncluded)
        untypedResources



-- Error handling
-- TODO tolerate and recover from resource errors. new error type that returns a list of results


{-| What might go wrong when calling [`get`](#get)

-- TODO maybe name this back to GetError? (the getErrorToString has a confusing name)

-}
type HttpError
    = HttpError Http.Error
    | DecodeDocumentError (DecodeError DocumentError)


{-| -}
httpErrorToString : HttpError -> String
httpErrorToString httpError =
    case httpError of
        HttpError httpError_ ->
            Debug.toString httpError_

        DecodeDocumentError decodeDocumentError ->
            decodeErrorToString documentErrorToString decodeDocumentError


{-| When decoding from raw JSON, two things can go wrong:

  - `NoncompliantJson`: The JSON is not in the JSON:API format.
  - `JsonApiDecodeError`: The client-provided decoder failed to decode the untyped JSON:API data into a typed application-specific type.

`jsonApiDecodeError` is the error type for the thing that was being decoded, one of

  - [`DocumentError`](#DocumentError)
  - [`ResourceError`](#ResourceError)
  - [`IdError`](#IdError)

-}
type DecodeError jsonApiDecodeError
    = NoncompliantJson Decode.Error
    | JsonApiDecodeError jsonApiDecodeError


{-| -}
decodeErrorToString : (jsonApiDecodeError -> String) -> DecodeError jsonApiDecodeError -> String
decodeErrorToString jsonApiDecodeErrorToString error =
    case error of
        NoncompliantJson decodeError ->
            Decode.errorToString decodeError

        JsonApiDecodeError jsonApiDecodeError ->
            jsonApiDecodeErrorToString jsonApiDecodeError


{-| Describes what went wrong while trying to create a [`Document`](#Document)

This will happen if a document has valid JSON:API, but the provided [`DocumentDecoder`](#DocumentDecoder) and its [`ResourceDecoder`](#ResourceDecoder)s don't know how to understand it.

This is different from [`Json.Decode.Error`](#https://package.elm-lang.org/packages/elm/json/1.1.3/Json-Decode#Error),
which might happen if the raw json does not follow the JSON:API spec, and might show up as part of [`DecodeError`](#DecodeError).

Cases:

  - `ExpectedOne`: The [`DocumentDecoder`](#DocumentDecoder) expected the primary resource to be a single resource, but it was a list.
  - `ExpectedMany`: The [`DocumentDecoder`](#DocumentDecoder) expected the primary resource to be a list of resources, but got a single resource object.
  - `ApiErrors`: The API returned a document with an `errors` field instead of a `data` field.
  - `ResourceError`: A resource in the `data` or `included` fields could not be decoded.

TODO more information about the resource error: which resource, what index, in data or included, etc,

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
            "API returned errors:\n" ++ Encode.encode 2 (Encode.list identity errors)

        ResourceError resourceError ->
            resourceErrorToString resourceError


{-| When a [`ResourceDecoder`](#ResourceDecoder) fails.

Cases:

  - `ResourceIdError`: The resource's [`IdDecoder`](#IdDecoder) failed to decode the resource's `type` or `id` fields.
  - `AttributeMissing`: The [`ResourceDecoder`](#ResourceDecoder) expected this attribute to exist, but it didn't.
  - `AttributeDecodeError`: The given attribute exists, but the [`ResourceDecoder`](#ResourceDecoder)'s [`attribute` decoder](#attribute) failed.
  - `RelationshipNumberError`: The [`ResourceDecoder`](#ResourceDecoder) expected a different number of relationships at the given name.
    E.g. expected a list of relationships but it was missing.
    The parameters are the relationship name and a human-readable message
  - `RelationshipIdError`: The [`IdDecoder`](#IdDecoder) for the given relationship of the resource failed.
  - `Failure`: A custom error message provided to [`fail`](#fail)

-- TODO include the resource id and json in the error/string, so it's easier to track down

-}
type ResourceError
    = ResourceIdError IdError
    | AttributeMissing String
    | AttributeDecodeError String Decode.Error
    | RelationshipNumberError String String
    | RelationshipIdError String IdError
    | Failure String


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

        RelationshipNumberError relationshipName message ->
            String.concat
                [ "Error at relationship "
                , relationshipName
                , ": "
                , message
                ]

        RelationshipIdError relationshipName idError ->
            String.concat
                [ "Couldn't decode id of relationship "
                , relationshipName
                , ": "
                , idErrorToString idError
                ]

        Failure message ->
            message


{-| The [`IdDecoder`](#IdDecoder) didn't know how to decode the type it found.

There could be more than one `expectedType` if it was made with [`oneOf`](#oneOf) or [`oneOfId`](#oneOfId)

-}
type alias IdError =
    { expectedType : List String
    , actualType : String
    , actualIdValue : String
    }


{-| -}
idErrorToString : IdError -> String
idErrorToString idError =
    let
        expectedTypeMessage =
            case idError.expectedType of
                [] ->
                    "but the IdDecoder didn't know how to handle any types. Did you pass an empty Dict to oneOfId?"

                [ expectedType ] ->
                    "as type " ++ expectedType

                multipleTypes ->
                    "as any of these types: " ++ String.join ", " multipleTypes
    in
    String.concat
        [ "Tried to decode {type: "
        , idError.actualType
        , ", id: "
        , idError.actualIdValue
        , "} "
        , expectedTypeMessage
        ]



-- Internal Run Decoders


decodeDocument : DocumentDecoder included data -> Untyped.Document -> Result DocumentError (Document included data)
decodeDocument (DocumentDecoder documentDecoder) untypedDocument =
    documentDecoder untypedDocument


decodeResource : ResourceDecoder resource -> Untyped.Resource -> Result ResourceError resource
decodeResource (ResourceDecoder documentDecoder) untypedResource =
    documentDecoder untypedResource


decodeId : IdDecoder id -> Untyped.ResourceId -> Result IdError id
decodeId (IdDecoder documentDecoder) untypedId =
    documentDecoder untypedId


decodeString : Decode.Decoder untypedObject -> (objectDecoder -> untypedObject -> Result objectError object) -> objectDecoder -> String -> Result (DecodeError objectError) object
decodeString untypedObjectDecoder decodeObject objectDecoder jsonString =
    jsonString
        |> Decode.decodeString Decode.value
        |> Result.mapError NoncompliantJson
        |> Result.andThen
            (\jsonValue ->
                decodeValue untypedObjectDecoder decodeObject objectDecoder jsonValue
            )


decodeValue : Decode.Decoder untypedObject -> (objectDecoder -> untypedObject -> Result objectError object) -> objectDecoder -> Decode.Value -> Result (DecodeError objectError) object
decodeValue untypedObjectDecoder decodeObject objectDecoder jsonValue =
    jsonValue
        |> Decode.decodeValue untypedObjectDecoder
        |> Result.mapError NoncompliantJson
        |> Result.andThen
            (\untypedObject ->
                untypedObject
                    |> decodeObject objectDecoder
                    |> Result.mapError JsonApiDecodeError
            )
