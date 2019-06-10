module Mbta.Included exposing (Included)

{-| The sideloaded data returned by an api call

@docs Included

-}

import AssocList as Dict exposing (Dict)
import JsonApi
import Mbta exposing (..)
import Mbta.Decode


type alias Included =
    { predictions : Dict PredictionId (List Prediction)
    , vehicles : Dict VehicleId (List Vehicle)
    , routes : Dict RouteId (List Route)
    , routePatterns : Dict RoutePatternId (List RoutePattern)
    , lines : Dict LineId (List Line)
    , schedules : Dict ScheduleId (List Schedule)
    , trips : Dict TripId (List Trip)
    , services : Dict ServiceId (List Service)
    , shapes : Dict ShapeId (List Shape)
    , stops : Dict StopId (List Stop)
    , facilities : Dict FacilityId (List Facility)
    , liveFacilities : Dict FacilityId (List LiveFacility)
    , alerts : Dict AlertId (List Alert)
    }


emptyIncluded : Included
emptyIncluded =
    { predictions = Dict.empty
    , vehicles = Dict.empty
    , routes = Dict.empty
    , routePatterns = Dict.empty
    , lines = Dict.empty
    , schedules = Dict.empty
    , trips = Dict.empty
    , services = Dict.empty
    , shapes = Dict.empty
    , stops = Dict.empty
    , facilities = Dict.empty
    , liveFacilities = Dict.empty
    , alerts = Dict.empty
    }


accumulatorForType : String -> JsonApi.Decoder (Included -> Included)
accumulatorForType resourceType =
    case resourceType of
        "prediction" ->
            Mbta.Decode.predictionDecoder
                |> JsonApi.map
                    (\prediction ->
                        \included ->
                            { included
                                | predictions = Dict.insert prediction.id prediction
                            }
                    )

        "vehicle" ->
            Mbta.Decode.vehicleDecoder
                |> JsonApi.map
                    (\vehicle ->
                        \included ->
                            { included
                                | vehicles = Dict.insert vehicle.id vehicle
                            }
                    )

        "route" ->
            Mbta.Decode.routeDecoder
                |> JsonApi.map
                    (\route ->
                        \included ->
                            { included
                                | routes = Dict.insert route.id route
                            }
                    )

        "route_pattern" ->
            Mbta.Decode.routePatternDecoder
                |> JsonApi.map
                    (\routePattern ->
                        \included ->
                            { included
                                | routePatterns = Dict.insert routePattern.id routePattern
                            }
                    )

        "line" ->
            Mbta.Decode.lineDecoder
                |> JsonApi.map
                    (\line ->
                        \included ->
                            { included
                                | lines = Dict.insert line.id line
                            }
                    )

        "schedule" ->
            Mbta.Decode.scheduleDecoder
                |> JsonApi.map
                    (\schedule ->
                        \included ->
                            { included
                                | schedules = Dict.insert schedule.id schedule
                            }
                    )

        "trip" ->
            Mbta.Decode.tripDecoder
                |> JsonApi.map
                    (\trip ->
                        \included ->
                            { included
                                | trips = Dict.insert trip.id trip
                            }
                    )

        "service" ->
            Mbta.Decode.serviceDecoder
                |> JsonApi.map
                    (\service ->
                        \included ->
                            { included
                                | services = Dict.insert service.id service
                            }
                    )

        "shape" ->
            Mbta.Decode.shapeDecoder
                |> JsonApi.map
                    (\shape ->
                        \included ->
                            { included
                                | shapes = Dict.insert shape.id shape
                            }
                    )

        "stop" ->
            Mbta.Decode.stopDecoder
                |> JsonApi.map
                    (\stop ->
                        \included ->
                            { included
                                | stops = Dict.insert stop.id stop
                            }
                    )

        "facility" ->
            Mbta.Decode.facilityDecoder
                |> JsonApi.map
                    (\facility ->
                        \included ->
                            { included
                                | facilities = Dict.insert facility.id facility
                            }
                    )

        "live-facility" ->
            Mbta.Decode.liveFacilityDecoder
                |> JsonApi.map
                    (\liveFacility ->
                        \included ->
                            { included
                                | liveFacilities = Dict.insert liveFacility.id liveFacility
                            }
                    )

        "alert" ->
            Mbta.Decode.alertDecoder
                |> JsonApi.map
                    (\alert ->
                        \included ->
                            { included
                                | alerts = Dict.insert alert.id alert
                            }
                    )
