module Mbta.Api exposing
    ( ApiKey(..)
    , Config
    , Host(..)
    )


type Host
    = Default
    | CustomUrl String


type ApiKey
    = NoApiKey
    | ApiKey String


type alias Config =
    { host : Host
    , apiKey : ApiKey
    }
