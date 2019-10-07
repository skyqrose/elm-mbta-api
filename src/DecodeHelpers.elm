module DecodeHelpers exposing
    ( all
    , colorDecoder
    , enum
    , fromResult
    , maybeEmptyString
    )

import Color
import Dict
import Json.Decode as Decode exposing (Decoder)


{-| Decodes "" into Nothing
-}
maybeEmptyString : Decoder (Maybe String)
maybeEmptyString =
    Decode.string
        |> Decode.map
            (\string ->
                case string of
                    "" ->
                        Nothing

                    _ ->
                        Just string
            )


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


{-| -}
fromResult : Result String x -> Decoder x
fromResult result =
    case result of
        Ok x ->
            Decode.succeed x

        Err e ->
            Decode.fail e


colorDecoder : Decoder Color.Color
colorDecoder =
    Decode.string
        |> Decode.andThen
            (\chars ->
                case String.toList chars of
                    [ r1, r2, g1, g2, b1, b2 ] ->
                        case
                            ( hex2ToInt r1 r2
                            , hex2ToInt g1 g2
                            , hex2ToInt b1 b2
                            )
                        of
                            ( Just r, Just g, Just b ) ->
                                Decode.succeed (Color.rgb255 r g b)

                            _ ->
                                Decode.fail "Expected color to be in hex /[0-9a-fA-F]{6}/"

                    _ ->
                        Decode.fail "Expected a color to be in the form \"RRGGBB\""
            )


hex2ToInt : Char -> Char -> Maybe Int
hex2ToInt char1 char2 =
    Maybe.map2
        (\int1 int2 -> int1 * 16 + int2)
        (hexToInt char1)
        (hexToInt char2)


hexToInt : Char -> Maybe Int
hexToInt char =
    case Char.toLower char of
        '0' ->
            Just 0

        '1' ->
            Just 1

        '2' ->
            Just 2

        '3' ->
            Just 3

        '4' ->
            Just 4

        '5' ->
            Just 5

        '6' ->
            Just 6

        '7' ->
            Just 7

        '8' ->
            Just 8

        '9' ->
            Just 9

        'a' ->
            Just 10

        'b' ->
            Just 11

        'c' ->
            Just 12

        'd' ->
            Just 13

        'e' ->
            Just 14

        'f' ->
            Just 15

        _ ->
            Nothing
