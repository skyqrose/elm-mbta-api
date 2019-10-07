module DecodeHelpersTest exposing (suite)

import Color
import DecodeHelpers
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (..)


type Fruit
    = Apple
    | Orange


fruitDecoder : Decode.Decoder Fruit
fruitDecoder =
    DecodeHelpers.enum Decode.string
        [ ( "apple", Apple )
        , ( "orange", Orange )
        ]


suite : Test
suite =
    describe "DecodeHelpers"
        [ describe "maybeEmptyString"
            [ test "decodes a nonempty string" <|
                \() ->
                    "something"
                        |> Encode.string
                        |> Decode.decodeValue DecodeHelpers.maybeEmptyString
                        |> Expect.equal (Ok (Just "something"))
            , test "turns an empty string into Nothing" <|
                \() ->
                    ""
                        |> Encode.string
                        |> Decode.decodeValue DecodeHelpers.maybeEmptyString
                        |> Expect.equal (Ok Nothing)
            ]
        , describe "enum"
            [ test "decodes a value" <|
                \() ->
                    "\"apple\""
                        |> Decode.decodeString fruitDecoder
                        |> Expect.equal (Ok Apple)
            , test "fails on unrecognized input" <|
                \() ->
                    "\"potato\""
                        |> Decode.decodeString fruitDecoder
                        |> Expect.err
            ]
        , describe "all"
            [ test "succeeds if all succeed" <|
                \() ->
                    Decode.decodeString
                        (DecodeHelpers.all
                            [ Decode.succeed 1
                            , Decode.succeed 2
                            ]
                        )
                        "{}"
                        |> Expect.equal (Ok [ 1, 2 ])
            , test "fails if any fail" <|
                \() ->
                    Decode.decodeString
                        (DecodeHelpers.all
                            [ Decode.succeed 1
                            , Decode.fail "fail"
                            ]
                        )
                        "{}"
                        |> Expect.err
            , test "succeeds if empty" <|
                \() ->
                    Decode.decodeString
                        (DecodeHelpers.all
                            []
                        )
                        "{}"
                        |> Expect.equal (Ok [])
            ]
        , describe "colorDecoder"
            [ test "0369BF" <|
                \() ->
                    Expect.equal
                        (Decode.decodeValue DecodeHelpers.colorDecoder (Encode.string "0369BF"))
                        (Ok (Color.rgb255 3 105 191))
            ]
        ]
