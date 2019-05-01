module DecodeHelpers exposing (all, enum)

import Dict
import Json.Decode as Decode exposing (Decoder)


{-| Map a fixed number of potential values, e.g. string constants, onto elm values

    fruitDecoder : Decoder Fruit.Fruit
    fruitDecoder =
        enumDecoder string
            [ ( "apple", Fruit.Apple )
            , ( "orange", Fruit.Orange )
            ]

-}
enum : Decoder comparable -> List ( comparable, a ) -> Decoder a
enum primitiveDecoder cases =
    primitiveDecoder
        |> Decode.andThen
            (\primitive ->
                case Dict.get primitive (Dict.fromList cases) of
                    Just result ->
                        Decode.succeed result

                    Nothing ->
                        Decode.fail "unrecognized case"
            )


{-| Combines decoders into a list if all of them succeed.
-}
all : List (Decoder a) -> Decoder (List a)
all decoders =
    List.foldr
        (Decode.map2 (::))
        (Decode.succeed [])
        decoders
