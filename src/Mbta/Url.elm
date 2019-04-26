module Mbta.Url exposing (url)


url : String -> List ( String, String ) -> String
url path params =
    let
        base =
            "https://api-v3.mbta.com/"

        apiKey =
            ""

        paramsWithKey =
            ( "api_key", apiKey ) :: params
    in
    String.concat
        [ base
        , path
        , "?"
        , paramsWithKey
            |> List.map (\( param, value ) -> param ++ "=" ++ value)
            |> String.join "&"
        ]
