module JsonApi exposing
    ( Attributes
    , Relationship
    , Relationships
    , Resource
    , ResourceId
    , attribute
    , custom
    , decode
    , finish
    , id
    , idDecoder
    , relationshipMany
    , relationshipMaybe
    , relationshipOne
    , resourceDecoder
    )

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline



-- TODO make these types opaque


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


decode : Resource -> constructor -> Decoder ( Resource, constructor )
decode resource constructor =
    Decode.succeed ( resource, constructor )


finish : Decoder ( Resource, result ) -> Decoder result
finish =
    Decode.map Tuple.second


id : (ResourceId -> Decoder id) -> Decoder ( Resource, id -> rest ) -> Decoder ( Resource, rest )
id idDecoder_ =
    Decode.andThen
        (\( resource, rest ) ->
            idDecoder_ resource.id
                |> Decode.map (\id_ -> ( resource, rest id_ ))
        )


relationshipOne : String -> (ResourceId -> Decoder relatedId) -> Decoder ( Resource, relatedId -> rest ) -> Decoder ( Resource, rest )
relationshipOne relationshipName relatedIdDecoder =
    Decode.andThen
        (\( resource, rest ) ->
            case Dict.get relationshipName resource.relationships of
                Just (One relatedResourceId) ->
                    relatedIdDecoder relatedResourceId
                        |> Decode.map (\relatedId -> ( resource, rest relatedId ))

                _ ->
                    Decode.fail ("Expected resource to have exactly one relationship " ++ relationshipName)
        )


relationshipMaybe : String -> (ResourceId -> Decoder relatedId) -> Decoder ( Resource, Maybe relatedId -> rest ) -> Decoder ( Resource, rest )
relationshipMaybe relationshipName relatedIdDecoder =
    Decode.andThen
        (\( resource, rest ) ->
            let
                maybeRelatedIdDecoder =
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
            in
            maybeRelatedIdDecoder
                |> Decode.map (\maybeRelatedId -> ( resource, rest maybeRelatedId ))
        )


relationshipMany : String -> (ResourceId -> Decoder relatedId) -> Decoder ( Resource, List relatedId -> rest ) -> Decoder ( Resource, rest )
relationshipMany relationshipName relatedIdDecoder =
    Decode.andThen
        (\( resource, rest ) ->
            case Dict.get relationshipName resource.relationships of
                Just (Many relatedResourceIds) ->
                    relatedResourceIds
                        |> List.map relatedIdDecoder
                        |> all
                        |> Decode.map (\relatedIds -> ( resource, rest relatedIds ))

                _ ->
                    Decode.fail ("Expected resource to have a list of relationships " ++ relationshipName)
        )


attribute : String -> Decoder attribute -> Decoder ( Resource, attribute -> rest ) -> Decoder ( Resource, rest )
attribute attributeName attributeDecoder =
    Decode.andThen
        (\( resource, rest ) ->
            case Dict.get attributeName resource.attributes of
                Just attributeJson ->
                    case Decode.decodeValue attributeDecoder attributeJson of
                        Ok attribute_ ->
                            Decode.succeed ( resource, rest attribute_ )

                        Err error ->
                            Decode.fail (Decode.errorToString error)

                Nothing ->
                    Decode.fail ("Expected attribute " ++ attributeName ++ ", but it's missing")
        )


custom : (Resource -> Decoder a) -> Decoder ( Resource, a -> rest ) -> Decoder ( Resource, rest )
custom decoder =
    Decode.andThen
        (\( resource, rest ) ->
            decoder resource
                |> Decode.map (\x -> ( resource, rest x ))
        )


{-| Combines decoders into a list if all of them succeed.
-}
all : List (Decoder a) -> Decoder (List a)
all decoders =
    List.foldl
        (Decode.map2 (::))
        (Decode.succeed [])
        decoders
