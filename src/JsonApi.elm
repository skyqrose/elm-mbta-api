module JsonApi exposing
    ( Attributes
    , Document
    , Relationship
    , Relationships
    , Resource
    , ResourceId
    , attribute
    , custom
    , decode
    , documentManyDecoder
    , documentOneDecoder
    , id
    , idDecoder
    , relationshipMany
    , relationshipMaybe
    , relationshipOne
    , resourceDecoder
    )

import DecodeHelpers
import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline



-- TODO make these types opaque


type alias Document howManyResources =
    { data : howManyResources
    }


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
    = NoData
    | OneEmpty
    | One ResourceId
    | Many (List ResourceId)


documentOneDecoder : Decoder (Document Resource)
documentOneDecoder =
    resourceDecoder
        |> Decode.field "data"
        |> Decode.map (\resource -> { data = resource })


documentManyDecoder : Decoder (Document (List Resource))
documentManyDecoder =
    resourceDecoder
        |> Decode.list
        |> Decode.field "data"
        |> Decode.map (\resources -> { data = resources })


resourceDecoder : Decoder Resource
resourceDecoder =
    Decode.succeed Resource
        |> Pipeline.custom resourceIdDecoder
        |> Pipeline.required "attributes" (Decode.dict Decode.value)
        |> Pipeline.required "relationships" (Decode.dict relationshipDecoder)


relationshipDecoder : Decoder Relationship
relationshipDecoder =
    Decode.value
        |> Decode.field "data"
        |> Decode.maybe
        |> Decode.andThen
            (\maybeDataValue ->
                case maybeDataValue of
                    Nothing ->
                        Decode.succeed NoData

                    Just dataValue ->
                        Decode.oneOf
                            [ Decode.null OneEmpty
                            , Decode.map One resourceIdDecoder
                            , Decode.map Many (Decode.list resourceIdDecoder)
                            ]
            )


resourceIdDecoder : Decoder ResourceId
resourceIdDecoder =
    Decode.succeed ResourceId
        |> Pipeline.required "type" Decode.string
        |> Pipeline.required "id" Decode.string


idDecoder : String -> (String -> id) -> ResourceId -> Decoder id
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



-- For decoding resources into more specific types


decode : constructor -> Resource -> Decoder constructor
decode constructor =
    \resource -> Decode.succeed constructor


id : (ResourceId -> Decoder id) -> (Resource -> Decoder (id -> rest)) -> Resource -> Decoder rest
id idDecoder_ =
    custom
        (\resource ->
            idDecoder_ resource.id
        )


relationshipOne : String -> (ResourceId -> Decoder relatedId) -> (Resource -> Decoder (relatedId -> rest)) -> Resource -> Decoder rest
relationshipOne relationshipName relatedIdDecoder =
    custom
        (\resource ->
            case Dict.get relationshipName resource.relationships of
                Just (One relatedResourceId) ->
                    relatedIdDecoder relatedResourceId

                _ ->
                    Decode.fail ("Expected resource to have exactly one relationship " ++ relationshipName)
        )


relationshipMaybe : String -> (ResourceId -> Decoder relatedId) -> (Resource -> Decoder (Maybe relatedId -> rest)) -> Resource -> Decoder rest
relationshipMaybe relationshipName relatedIdDecoder =
    custom
        (\resource ->
            case Dict.get relationshipName resource.relationships of
                Just (One relatedResourceId) ->
                    relatedIdDecoder relatedResourceId
                        |> Decode.map Just

                Just OneEmpty ->
                    Decode.succeed Nothing

                Nothing ->
                    Decode.succeed Nothing

                _ ->
                    Decode.fail ("Expected resource to have exactly one relationship " ++ relationshipName)
        )


relationshipMany : String -> (ResourceId -> Decoder relatedId) -> (Resource -> Decoder (List relatedId -> rest)) -> Resource -> Decoder rest
relationshipMany relationshipName relatedIdDecoder =
    custom
        (\resource ->
            case Dict.get relationshipName resource.relationships of
                Just (Many relatedResourceIds) ->
                    relatedResourceIds
                        |> List.map relatedIdDecoder
                        |> DecodeHelpers.all

                _ ->
                    Decode.fail ("Expected resource to have a list of relationships " ++ relationshipName)
        )


attribute : String -> Decoder attribute -> (Resource -> Decoder (attribute -> rest)) -> Resource -> Decoder rest
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


custom : (Resource -> Decoder a) -> (Resource -> Decoder (a -> rest)) -> Resource -> Decoder rest
custom decoder constructorDecoder =
    \resource ->
        Decode.map2
            (\x consructor -> consructor x)
            (decoder resource)
            (constructorDecoder resource)
