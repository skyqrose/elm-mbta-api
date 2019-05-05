module JsonApi exposing
    ( Decoder
    , IdDecoder
    , attribute
    , custom
    , decode
    , decoderMany
    , decoderOne
    , id
    , idDecoder
    , relationshipMany
    , relationshipMaybe
    , relationshipOne
    )

{-| This module serves as a middle point between the raw json in JSON API
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
            |> attribute "title" Decode.string

    Http.get
        { url = url
        , expect = expectJson toMsg (decoderOne bookDecoder)
        }

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
    = RelationshipOneEmpty
    | RelationshipOne ResourceId
    | RelationshipManyEmpty
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
                [ Decode.null RelationshipOneEmpty
                , Decode.map RelationshipOne resourceIdDecoder
                , Decode.map RelationshipMany (Decode.list resourceIdDecoder)
                ]
        , Decode.succeed RelationshipManyEmpty
        ]


resourceIdDecoder : Decode.Decoder ResourceId
resourceIdDecoder =
    Decode.succeed ResourceId
        |> Pipeline.required "type" Decode.string
        |> Pipeline.required "id" Decode.string



-- Pipeline for decoding internal resources into more specific types


{-| -}
type alias Decoder a =
    Resource -> Decode.Decoder a


type alias IdDecoder a =
    ResourceId -> Decode.Decoder a


{-| -}
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


decode : constructor -> Decoder constructor
decode constructor =
    \resource -> Decode.succeed constructor


id : IdDecoder id -> Decoder (id -> rest) -> Decoder rest
id idDecoder_ =
    custom
        (\resource ->
            idDecoder_ resource.id
        )


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


relationshipMaybe : String -> IdDecoder relatedId -> Decoder (Maybe relatedId -> rest) -> Decoder rest
relationshipMaybe relationshipName relatedIdDecoder =
    custom
        (\resource ->
            case Dict.get relationshipName resource.relationships of
                Just (RelationshipOne relatedResourceId) ->
                    relatedIdDecoder relatedResourceId
                        |> Decode.map Just

                Just RelationshipOneEmpty ->
                    Decode.succeed Nothing

                Nothing ->
                    Decode.succeed Nothing

                Just _ ->
                    Decode.fail
                        (String.concat
                            [ "Expected resource to have exactly one relationship "
                            , relationshipName
                            , ", but got a list"
                            ]
                        )
        )


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
                    fail "it was missing"

                Just RelationshipManyEmpty ->
                    fail "it was missing"

                Just RelationshipOneEmpty ->
                    fail "only got one"

                Just (RelationshipOne _) ->
                    fail "only got one"
        )


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


custom : Decoder a -> Decoder (a -> rest) -> Decoder rest
custom decoder constructorDecoder =
    \resource ->
        Decode.map2
            (\x consructor -> consructor x)
            (decoder resource)
            (constructorDecoder resource)



-- Run it


decoderOne : Decoder a -> Decode.Decoder a
decoderOne decoder =
    resourceDecoder
        |> Decode.field "data"
        |> Decode.andThen decoder


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
