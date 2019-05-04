module Mbta.DecodeTest exposing (suite)

import DecodeHelpers
import Expect
import Json.Decode exposing (Decoder)
import JsonApi
import Mbta exposing (..)
import Mbta.Decode
import Test exposing (..)


testOne : String -> String -> String -> (JsonApi.Resource -> Decoder a) -> Test
testOne description url json decoder =
    test description <|
        \() ->
            json
                |> Json.Decode.decodeString (JsonApi.decoderOne decoder)
                |> Expect.ok


testMany : String -> String -> String -> (JsonApi.Resource -> Decoder a) -> Test
testMany description url json decoder =
    test description <|
        \() ->
            json
                |> Json.Decode.decodeString (JsonApi.decoderMany decoder)
                |> Expect.ok


suite : Test
suite =
    describe "stop"
        [ testOne
            "bus stop"
            "/stops/1"
            """
            {"data":{"attributes":{"address":null,"description":null,"latitude":42.330957,"location_type":0,"longitude":-71.082754,"name":"Washington St opp Ruggles St","platform_code":null,"platform_name":null,"wheelchair_boarding":1},"id":"1","links":{"self":"/stops/1"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=1"}},"parent_station":{"data":null},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},"jsonapi":{"version":"1.0"}}
            """
            Mbta.Decode.stop
        , testOne
            "subway child stop"
            "/stops/70070"
            """
            {"data":{"attributes":{"address":null,"description":"Central - Red Line - Alewife","latitude":42.365379,"location_type":0,"longitude":-71.103554,"name":"Central","platform_code":null,"platform_name":"Alewife","wheelchair_boarding":1},"id":"70070","links":{"self":"/stops/70070"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=70070"}},"parent_station":{"data":{"id":"place-cntsq","type":"stop"}},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},"jsonapi":{"version":"1.0"}}
            """
            Mbta.Decode.stop
        , testOne
            "subway parent stop"
            "/stops/place-cntsq"
            """
            {"data":{"attributes":{"address":"Massachusetts Avenue and Prospect Street, Cambridge, MA 02139","description":null,"latitude":42.365486,"location_type":1,"longitude":-71.103802,"name":"Central","platform_code":null,"platform_name":null,"wheelchair_boarding":1},"id":"place-cntsq","links":{"self":"/stops/place-cntsq"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=place-cntsq"}},"parent_station":{"data":null},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},"jsonapi":{"version":"1.0"}}
            """
            Mbta.Decode.stop
        , testOne
            "entrance"
            "/stops/door-cntsq-pearl"
            """
            {"data":{"attributes":{"address":null,"description":"Central - Pearl St","latitude":42.364831,"location_type":2,"longitude":-71.102989,"name":"Central - Pearl St","platform_code":null,"platform_name":null,"wheelchair_boarding":2},"id":"door-cntsq-pearl","links":{"self":"/stops/door-cntsq-pearl"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=door-cntsq-pearl"}},"parent_station":{"data":{"id":"place-cntsq","type":"stop"}},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},"jsonapi":{"version":"1.0"}}
            """
            Mbta.Decode.stop
        , testOne
            "parent with children included"
            "/stops/place-cntsq?include=child_stops"
            """
            {"data":{"attributes":{"address":"Massachusetts Avenue and Prospect Street, Cambridge, MA 02139","description":null,"latitude":42.365486,"location_type":1,"longitude":-71.103802,"name":"Central","platform_code":null,"platform_name":null,"wheelchair_boarding":1},"id":"place-cntsq","links":{"self":"/stops/place-cntsq"},"relationships":{"child_stops":{"data":[{"id":"70069","type":"stop"},{"id":"70070","type":"stop"},{"id":"door-cntsq-essex","type":"stop"},{"id":"door-cntsq-ibmass","type":"stop"},{"id":"door-cntsq-obmass","type":"stop"},{"id":"door-cntsq-pearl","type":"stop"},{"id":"door-cntsq-prospect","type":"stop"},{"id":"door-cntsq-western","type":"stop"}]},"facilities":{"links":{"related":"/facilities/?filter[stop]=place-cntsq"}},"parent_station":{"data":null},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},"included":[{"attributes":{"address":null,"description":"Central - Red Line - Ashmont/Braintree","latitude":42.365304,"location_type":0,"longitude":-71.103621,"name":"Central","platform_code":null,"platform_name":"Ashmont/Braintree","wheelchair_boarding":1},"id":"70069","links":{"self":"/stops/70069"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=70069"}},"parent_station":{"data":{"id":"place-cntsq","type":"stop"}},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},{"attributes":{"address":null,"description":"Central - Red Line - Alewife","latitude":42.365379,"location_type":0,"longitude":-71.103554,"name":"Central","platform_code":null,"platform_name":"Alewife","wheelchair_boarding":1},"id":"70070","links":{"self":"/stops/70070"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=70070"}},"parent_station":{"data":{"id":"place-cntsq","type":"stop"}},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},{"attributes":{"address":null,"description":"Central - Essex St","latitude":42.364991,"location_type":2,"longitude":-71.102811,"name":"Central - Essex St","platform_code":null,"platform_name":null,"wheelchair_boarding":2},"id":"door-cntsq-essex","links":{"self":"/stops/door-cntsq-essex"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=door-cntsq-essex"}},"parent_station":{"data":{"id":"place-cntsq","type":"stop"}},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},{"attributes":{"address":null,"description":"Central - Mass Ave","latitude":42.36519,"location_type":2,"longitude":-71.103557,"name":"Central - Mass Ave","platform_code":null,"platform_name":null,"wheelchair_boarding":1},"id":"door-cntsq-ibmass","links":{"self":"/stops/door-cntsq-ibmass"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=door-cntsq-ibmass"}},"parent_station":{"data":{"id":"place-cntsq","type":"stop"}},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},{"attributes":{"address":null,"description":"Central - Mass Ave","latitude":42.365541,"location_type":2,"longitude":-71.103749,"name":"Central - Mass Ave","platform_code":null,"platform_name":null,"wheelchair_boarding":1},"id":"door-cntsq-obmass","links":{"self":"/stops/door-cntsq-obmass"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=door-cntsq-obmass"}},"parent_station":{"data":{"id":"place-cntsq","type":"stop"}},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},{"attributes":{"address":null,"description":"Central - Pearl St","latitude":42.364831,"location_type":2,"longitude":-71.102989,"name":"Central - Pearl St","platform_code":null,"platform_name":null,"wheelchair_boarding":2},"id":"door-cntsq-pearl","links":{"self":"/stops/door-cntsq-pearl"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=door-cntsq-pearl"}},"parent_station":{"data":{"id":"place-cntsq","type":"stop"}},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},{"attributes":{"address":null,"description":"Central - Prospect St","latitude":42.365778,"location_type":2,"longitude":-71.104131,"name":"Central - Prospect St","platform_code":null,"platform_name":null,"wheelchair_boarding":2},"id":"door-cntsq-prospect","links":{"self":"/stops/door-cntsq-prospect"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=door-cntsq-prospect"}},"parent_station":{"data":{"id":"place-cntsq","type":"stop"}},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},{"attributes":{"address":null,"description":"Central - Western Ave","latitude":42.365635,"location_type":2,"longitude":-71.104304,"name":"Central - Western Ave","platform_code":null,"platform_name":null,"wheelchair_boarding":2},"id":"door-cntsq-western","links":{"self":"/stops/door-cntsq-western"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=door-cntsq-western"}},"parent_station":{"data":{"id":"place-cntsq","type":"stop"}},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"}],"jsonapi":{"version":"1.0"}}
            """
            Mbta.Decode.stop
        , testMany
            "multiple"
            "/stops?filter[route]=746"
            """
            {"data":[{"attributes":{"address":"Silver Line Way and Starboard Way, Boston, MA 02210","description":"Silver Line Way before Manulife Building - Silver Line - South Station","latitude":42.347188,"location_type":0,"longitude":-71.038846,"name":"Silver Line Way before Manulife Building","platform_code":null,"platform_name":"South Station","wheelchair_boarding":1},"id":"74614","links":{"self":"/stops/74614"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=74614"}},"parent_station":{"data":null},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},{"attributes":{"address":"Congress St and World Trade Center Ave, Boston, MA","description":null,"latitude":42.34863,"location_type":1,"longitude":-71.04246,"name":"World Trade Center","platform_code":null,"platform_name":null,"wheelchair_boarding":1},"id":"place-wtcst","links":{"self":"/stops/place-wtcst"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=place-wtcst"}},"parent_station":{"data":null},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},{"attributes":{"address":"Seaport Blvd and Pittsburg St, Boston, MA","description":null,"latitude":42.35245,"location_type":1,"longitude":-71.04685,"name":"Courthouse","platform_code":null,"platform_name":null,"wheelchair_boarding":1},"id":"place-crtst","links":{"self":"/stops/place-crtst"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=place-crtst"}},"parent_station":{"data":null},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"},{"attributes":{"address":"700 Atlantic Ave, Boston, MA 02110","description":null,"latitude":42.352271,"location_type":1,"longitude":-71.055242,"name":"South Station","platform_code":null,"platform_name":null,"wheelchair_boarding":1},"id":"place-sstat","links":{"self":"/stops/place-sstat"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=place-sstat"}},"parent_station":{"data":null},"recommended_transfers":{},"zone":{"data":{"id":"CR-zone-1A","type":"zone"}}},"type":"stop"},{"attributes":{"address":"Silver Line Way and Starboard Way, Boston, MA 02210","description":"Silver Line Way after Manulife Building - Silver Line - Airport/Design Center/Chelsea","latitude":42.347056,"location_type":0,"longitude":-71.038814,"name":"Silver Line Way after Manulife Building","platform_code":null,"platform_name":"Airport/Design Center/Chelsea","wheelchair_boarding":1},"id":"74624","links":{"self":"/stops/74624"},"relationships":{"child_stops":{},"facilities":{"links":{"related":"/facilities/?filter[stop]=74624"}},"parent_station":{"data":null},"recommended_transfers":{},"zone":{"data":null}},"type":"stop"}],"jsonapi":{"version":"1.0"}}
            """
            Mbta.Decode.stop
        ]
