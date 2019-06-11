module Mbta.Included exposing
    ( Included
    , includedDecoder
    )

{-| The sideloaded data returned by an api call

@docs Included

-}

import AssocList as Dict exposing (Dict)
import JsonApi
import Mbta exposing (..)
import Mbta.Decode


type alias Included =
    { predictions : Dict PredictionId Prediction
    , vehicles : Dict VehicleId Vehicle
    , routes : Dict RouteId Route
    , routePatterns : Dict RoutePatternId RoutePattern
    , lines : Dict LineId Line
    , schedules : Dict ScheduleId Schedule
    , trips : Dict TripId Trip
    , services : Dict ServiceId Service
    , shapes : Dict ShapeId Shape
    , stops : Dict StopId Stop
    , facilities : Dict FacilityId Facility
    , liveFacilities : Dict FacilityId LiveFacility
    , alerts : Dict AlertId Alert
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


accumulatorsByType : List ( String, JsonApi.ResourceDecoder (Included -> Included) )
accumulatorsByType =
    [ ( "prediction"
      , Mbta.Decode.prediction
            |> JsonApi.map
                (\prediction ->
                    \included ->
                        { included
                            | predictions = Dict.insert prediction.id prediction included.predictions
                        }
                )
      )
    , ( "vehicle"
      , Mbta.Decode.vehicle
            |> JsonApi.map
                (\vehicle ->
                    \included ->
                        { included
                            | vehicles = Dict.insert vehicle.id vehicle included.vehicles
                        }
                )
      )
    , ( "route"
      , Mbta.Decode.route
            |> JsonApi.map
                (\route ->
                    \included ->
                        { included
                            | routes = Dict.insert route.id route included.routes
                        }
                )
      )
    , ( "route_pattern"
      , Mbta.Decode.routePattern
            |> JsonApi.map
                (\routePattern ->
                    \included ->
                        { included
                            | routePatterns = Dict.insert routePattern.id routePattern included.routePatterns
                        }
                )
      )
    , ( "line"
      , Mbta.Decode.line
            |> JsonApi.map
                (\line ->
                    \included ->
                        { included
                            | lines = Dict.insert line.id line included.lines
                        }
                )
      )
    , ( "schedule"
      , Mbta.Decode.schedule
            |> JsonApi.map
                (\schedule ->
                    \included ->
                        { included
                            | schedules = Dict.insert schedule.id schedule included.schedules
                        }
                )
      )
    , ( "trip"
      , Mbta.Decode.trip
            |> JsonApi.map
                (\trip ->
                    \included ->
                        { included
                            | trips = Dict.insert trip.id trip included.trips
                        }
                )
      )
    , ( "service"
      , Mbta.Decode.service
            |> JsonApi.map
                (\service ->
                    \included ->
                        { included
                            | services = Dict.insert service.id service included.services
                        }
                )
      )
    , ( "shape"
      , Mbta.Decode.shape
            |> JsonApi.map
                (\shape ->
                    \included ->
                        { included
                            | shapes = Dict.insert shape.id shape included.shapes
                        }
                )
      )
    , ( "stop"
      , Mbta.Decode.stop
            |> JsonApi.map
                (\stop ->
                    \included ->
                        { included
                            | stops = Dict.insert stop.id stop included.stops
                        }
                )
      )
    , ( "facility"
      , Mbta.Decode.facility
            |> JsonApi.map
                (\facility ->
                    \included ->
                        { included
                            | facilities = Dict.insert facility.id facility included.facilities
                        }
                )
      )
    , ( "live-facility"
      , Mbta.Decode.liveFacility
            |> JsonApi.map
                (\liveFacility ->
                    \included ->
                        { included
                            | liveFacilities = Dict.insert liveFacility.id liveFacility included.liveFacilities
                        }
                )
      )
    , ( "alert"
      , Mbta.Decode.alert
            |> JsonApi.map
                (\alert ->
                    \included ->
                        { included
                            | alerts = Dict.insert alert.id alert included.alerts
                        }
                )
      )
    ]


includedDecoder : JsonApi.IncludedDecoder Included
includedDecoder =
    { emptyIncluded = emptyIncluded
    , accumulatorsByType = accumulatorsByType
    }
