module Mbta.Mixed exposing
    ( Mixed
    , empty
    , insert
    , remove
    )

{-| A heterogenous collection of resources
-}

import AssocList
import Dict
import JsonApi
import Mbta exposing (..)
import Mbta.Decode


type alias Mixed =
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


empty : Mixed
empty =
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


insert : JsonApi.ResourceDecoder (Mixed -> Mixed)
insert =
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
                            | stops = AssocList.insert (stopId stop) stop included.stops
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
        |> JsonApi.byType


remove : JsonApi.IdDecoder (Mixed -> Mixed)
remove =
    [ ( "prediction"
      , Mbta.Decode.predictionId
            |> JsonApi.mapId
                (\predictionId ->
                    \included ->
                        { included
                            | predictions = AssocList.remove predictionId included.predictions
                        }
                )
      )
    , ( "vehicle"
      , Mbta.Decode.vehicleId
            |> JsonApi.mapId
                (\vehicleId ->
                    \included ->
                        { included
                            | vehicles = AssocList.remove vehicleId included.vehicles
                        }
                )
      )
    , ( "route"
      , Mbta.Decode.routeId
            |> JsonApi.mapId
                (\routeId ->
                    \included ->
                        { included
                            | routes = AssocList.remove routeId included.routes
                        }
                )
      )
    , ( "route_pattern"
      , Mbta.Decode.routePatternId
            |> JsonApi.mapId
                (\routePatternId ->
                    \included ->
                        { included
                            | routePatterns = AssocList.remove routePatternId included.routePatterns
                        }
                )
      )
    , ( "line"
      , Mbta.Decode.lineId
            |> JsonApi.mapId
                (\lineId ->
                    \included ->
                        { included
                            | lines = AssocList.remove lineId included.lines
                        }
                )
      )
    , ( "schedule"
      , Mbta.Decode.scheduleId
            |> JsonApi.mapId
                (\scheduleId ->
                    \included ->
                        { included
                            | schedules = AssocList.remove scheduleId included.schedules
                        }
                )
      )
    , ( "trip"
      , Mbta.Decode.tripId
            |> JsonApi.mapId
                (\tripId ->
                    \included ->
                        { included
                            | trips = AssocList.remove tripId included.trips
                        }
                )
      )
    , ( "service"
      , Mbta.Decode.serviceId
            |> JsonApi.mapId
                (\serviceId ->
                    \included ->
                        { included
                            | services = AssocList.remove serviceId included.services
                        }
                )
      )
    , ( "shape"
      , Mbta.Decode.shapeId
            |> JsonApi.mapId
                (\shapeId ->
                    \included ->
                        { included
                            | shapes = AssocList.remove shapeId included.shapes
                        }
                )
      )
    , ( "stop"
      , Mbta.Decode.stopId
            |> JsonApi.mapId
                (\stopId ->
                    \included ->
                        { included
                            | stops = AssocList.remove stopId included.stops
                        }
                )
      )
    , ( "facility"
      , Mbta.Decode.facilityId
            |> JsonApi.mapId
                (\facilityId ->
                    \included ->
                        { included
                            | facilities = AssocList.remove facilityId included.facilities
                        }
                )
      )
    , ( "live-facility"
      , Mbta.Decode.facilityId
            |> JsonApi.mapId
                (\facilityId ->
                    \included ->
                        { included
                            | liveFacilities = AssocList.remove facilityId included.liveFacilities
                        }
                )
      )
    , ( "alert"
      , Mbta.Decode.alertId
            |> JsonApi.mapId
                (\alertId ->
                    \included ->
                        { included
                            | alerts = AssocList.remove alertId included.alerts
                        }
                )
      )
    ]
        |> Dict.fromList
        |> JsonApi.idDecoderByType
