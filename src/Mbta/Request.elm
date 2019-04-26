module Mbta.Request exposing (getStops)

import Mbta.Decoders
import Mbta as Mbta
import Mbta.Url
import Http
import Json.Decode as Decode


getStops : (Result Http.Error (List Mbta.Stop) -> msg) -> List Mbta.StopId -> Cmd msg
getStops msg stopIds =
    let
        stopIdsParam =
            stopIds
                |> List.map (\(Mbta.StopId stopId) -> stopId)
                |> String.join ","

        url =
            Mbta.Url.url "stops" [ ( "filter[id]", stopIdsParam ) ]
    in
    Http.get
        { url = url
        , expect =
            Http.expectJson msg
                (Mbta.Decoders.stopDecoder
                    |> Decode.list
                    |> Decode.at [ "data" ]
                )
        }
