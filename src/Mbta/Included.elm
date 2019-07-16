module Mbta.Included exposing
    ( Included
    , includedDecoder
    )

{-| The sideloaded data returned by an api call

@docs Included

-}

import AssocList
import Dict
import JsonApi
import Mbta exposing (..)
import Mbta.Decode


type alias Included =
    { predictions : AssocList.Dict PredictionId Prediction
    , vehicles : AssocList.Dict VehicleId Vehicle
    , routes : AssocList.Dict RouteId Route
    , routePatterns : AssocList.Dict RoutePatternId RoutePattern
    , lines : AssocList.Dict LineId Line
    , schedules : AssocList.Dict ScheduleId Schedule
    , trips : AssocList.Dict TripId Trip
    , services : AssocList.Dict ServiceId Service
    , shapes : AssocList.Dict ShapeId Shape
    , stops : AssocList.Dict StopId Stop
    , facilities : AssocList.Dict FacilityId Facility
    , liveFacilities : AssocList.Dict FacilityId LiveFacility
    , alerts : AssocList.Dict AlertId Alert
    }


emptyIncluded : Included
emptyIncluded =
    { predictions = AssocList.empty
    , vehicles = AssocList.empty
    , routes = AssocList.empty
    , routePatterns = AssocList.empty
    , lines = AssocList.empty
    , schedules = AssocList.empty
    , trips = AssocList.empty
    , services = AssocList.empty
    , shapes = AssocList.empty
    , stops = AssocList.empty
    , facilities = AssocList.empty
    , liveFacilities = AssocList.empty
    , alerts = AssocList.empty
    }


accumulator : JsonApi.ResourceDecoder (Included -> Included)
accumulator =
    [ ( "prediction"
      , Mbta.Decode.prediction
            |> JsonApi.map
                (\prediction ->
                    \included ->
                        { included
                            | predictions = AssocList.insert prediction.id prediction included.predictions
                        }
                )
      )
    , ( "vehicle"
      , Mbta.Decode.vehicle
            |> JsonApi.map
                (\vehicle ->
                    \included ->
                        { included
                            | vehicles = AssocList.insert vehicle.id vehicle included.vehicles
                        }
                )
      )
    , ( "route"
      , Mbta.Decode.route
            |> JsonApi.map
                (\route ->
                    \included ->
                        { included
                            | routes = AssocList.insert route.id route included.routes
                        }
                )
      )
    , ( "route_pattern"
      , Mbta.Decode.routePattern
            |> JsonApi.map
                (\routePattern ->
                    \included ->
                        { included
                            | routePatterns = AssocList.insert routePattern.id routePattern included.routePatterns
                        }
                )
      )
    , ( "line"
      , Mbta.Decode.line
            |> JsonApi.map
                (\line ->
                    \included ->
                        { included
                            | lines = AssocList.insert line.id line included.lines
                        }
                )
      )
    , ( "schedule"
      , Mbta.Decode.schedule
            |> JsonApi.map
                (\schedule ->
                    \included ->
                        { included
                            | schedules = AssocList.insert schedule.id schedule included.schedules
                        }
                )
      )
    , ( "trip"
      , Mbta.Decode.trip
            |> JsonApi.map
                (\trip ->
                    \included ->
                        { included
                            | trips = AssocList.insert trip.id trip included.trips
                        }
                )
      )
    , ( "service"
      , Mbta.Decode.service
            |> JsonApi.map
                (\service ->
                    \included ->
                        { included
                            | services = AssocList.insert service.id service included.services
                        }
                )
      )
    , ( "shape"
      , Mbta.Decode.shape
            |> JsonApi.map
                (\shape ->
                    \included ->
                        { included
                            | shapes = AssocList.insert shape.id shape included.shapes
                        }
                )
      )
    , ( "stop"
      , Mbta.Decode.stop
            |> JsonApi.map
                (\stop ->
                    \included ->
                        { included
                            | stops = AssocList.insert stop.id stop included.stops
                        }
                )
      )
    , ( "facility"
      , Mbta.Decode.facility
            |> JsonApi.map
                (\facility ->
                    \included ->
                        { included
                            | facilities = AssocList.insert facility.id facility included.facilities
                        }
                )
      )
    , ( "live-facility"
      , Mbta.Decode.liveFacility
            |> JsonApi.map
                (\liveFacility ->
                    \included ->
                        { included
                            | liveFacilities = AssocList.insert liveFacility.id liveFacility included.liveFacilities
                        }
                )
      )
    , ( "alert"
      , Mbta.Decode.alert
            |> JsonApi.map
                (\alert ->
                    \included ->
                        { included
                            | alerts = AssocList.insert alert.id alert included.alerts
                        }
                )
      )
    ]
        |> Dict.fromList
        |> JsonApi.oneOf


includedDecoder : JsonApi.IncludedDecoder Included
includedDecoder =
    { emptyIncluded = emptyIncluded
    , accumulator = accumulator
    }
