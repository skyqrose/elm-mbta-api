module Mbta.Include exposing
    ( Included
    , include, Include, Relationship, andIts
    , predictionVehicle, predictionRoute, predictionSchedule, predictionTrip, predictionStop, predictionAlerts
    , vehicleRoute, vehicleTrip, vehicleStop
    , routeRoutePatterns, routeLine, routeStop
    , routePatternRoute, routePatternRepresentativeTrip
    , lineRoutes
    , schedulePrediction, scheduleRoute, scheduleTrip, scheduleStop
    , tripPredictions, tripVehicle, tripRoute, tripRoutePattern, tripService, tripShape
    , shapeRoute, shapeStops
    , stopParentStation, stopChildStops, stopRecommendedTransfers, stopFacilities
    , facilityStop
    , liveFacilityFacility
    , alertRoutes, alertTrips, alertStops, alertFacilities
    , queryParameter
    )

{-| For specifying which additional resources to sideload during an api call

Use it like

    Mbta.Api.getTrip
        ReceiveTrip
        apiConfig
        [ Mbta.Include.include Mbta.Include.tripRoute ]

Any sideloaded resources are put in the [`Included`](#Included) object returned by the Api


# Results

@docs Included


# Specifying what to include

@docs include, Include, Relationship, andIts


## Realtime Data


### [Prediction](#Mbta.Prediction)

@docs predictionVehicle, predictionRoute, predictionSchedule, predictionTrip, predictionStop, predictionAlerts


### [Vehicle](#Mbta.Vehicle)

@docs vehicleRoute, vehicleTrip, vehicleStop


## Schedule Data


### [Route](#Mbta.Route)

@docs routeRoutePatterns, routeLine, routeStop


### [RoutePattern](#Mbta.RoutePattern)

@docs routePatternRoute, routePatternRepresentativeTrip


### [Line](#Mbta.Line)

@docs lineRoutes


### [Schedule](#Mbta.Schedule)

@docs schedulePrediction, scheduleRoute, scheduleTrip, scheduleStop


### [Trip](#Mbta.Trip)

@docs tripPredictions, tripVehicle, tripRoute, tripRoutePattern, tripService, tripShape


### [Service](#Mbta.Service)

`Service` does not currently have any relationships to include.


### [Shape](#Mbta.Shape)

@docs shapeRoute, shapeStops


## Stops


### [Stop](#Mbta.Stop)

@docs stopParentStation, stopChildStops, stopRecommendedTransfers, stopFacilities


### [Facility](#Mbta.Facility)

@docs facilityStop


### [LiveFacility](#Mbta.LiveFacility)

@docs liveFacilityFacility


## Alerts


### [Alert](#Mbta.Alert)

@docs alertRoutes, alertTrips, alertStops, alertFacilities

-}

import AssocList exposing (Dict)
import Mbta exposing (..)
import Url.Builder


{-| The sideloaded data returned by an api call
-}
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


{-| -}
type Include mainResource
    = Include String


{-| -}
type Relationship from to
    = Relationship String


{-| -}
include : Relationship from to -> Include from
include (Relationship s) =
    Include s


{-| For internal use. You won't need this unless you're constructing your own urls.
-}
queryParameter : List (Include a) -> List Url.Builder.QueryParameter
queryParameter includes =
    case includes of
        [] ->
            []

        _ ->
            includes
                |> List.map (\(Include s) -> s)
                |> String.join ","
                |> Url.Builder.string "include"
                |> List.singleton


{-| For chaining includes

Adds an included resource's relationships into the sideloaded results.

Uses the `.` syntax from JSON:API's `?include=` options.

    includeRouteAndLineForAVehicle : Include Vehicle
    includeRouteAndLineForAVehicle =
        Include.include
            (Include.vehicleRoute
                |> Include.andIts Include.routeLine
            )

-}
andIts : Relationship b c -> Relationship a b -> Relationship a c
andIts (Relationship string1) (Relationship string2) =
    Relationship (string1 ++ "." ++ string2)



-- Realtime Data
-- Prediction


predictionVehicle : Relationship Prediction Vehicle
predictionVehicle =
    Relationship "vehicle"


predictionRoute : Relationship Prediction Route
predictionRoute =
    Relationship "route"


predictionSchedule : Relationship Prediction Schedule
predictionSchedule =
    Relationship "schedule"


predictionTrip : Relationship Prediction Trip
predictionTrip =
    Relationship "trip"


predictionStop : Relationship Prediction Stop
predictionStop =
    Relationship "stop"


predictionAlerts : Relationship Prediction Alert
predictionAlerts =
    Relationship "alerts"



-- Vehicle


vehicleRoute : Relationship Vehicle Route
vehicleRoute =
    Relationship "route"


vehicleTrip : Relationship Vehicle Trip
vehicleTrip =
    Relationship "trip"


vehicleStop : Relationship Vehicle Trip
vehicleStop =
    Relationship "stop"



-- Schedule Data
-- Route


routeRoutePatterns : Relationship Route RoutePattern
routeRoutePatterns =
    Relationship "route_patterns"


routeLine : Relationship Route Line
routeLine =
    Relationship "line"


{-| Only valid when getting a list of routes with [`getRoutes`](#Mbta.Api.getRoutes), and when [`filter stop TODO`](TODO) is used.

If this relationship is given when invalid, the result will be a TODO error

-}
routeStop : Relationship Route Stop
routeStop =
    Relationship "stop"



-- RoutePattern


routePatternRoute : Relationship RoutePattern Route
routePatternRoute =
    Relationship "route"


routePatternRepresentativeTrip : Relationship RoutePattern Trip
routePatternRepresentativeTrip =
    Relationship "representative_trip"



-- Line


lineRoutes : Relationship Line Route
lineRoutes =
    Relationship "routes"



-- Schedule


scheduleStop : Relationship Schedule Stop
scheduleStop =
    Relationship "stop"


scheduleTrip : Relationship Schedule Trip
scheduleTrip =
    Relationship "trip"


schedulePrediction : Relationship Schedule Prediction
schedulePrediction =
    Relationship "prediction"


scheduleRoute : Relationship Schedule Route
scheduleRoute =
    Relationship "route"



-- Trip


tripPredictions : Relationship Trip Prediction
tripPredictions =
    Relationship "predictions"


tripVehicle : Relationship Trip Vehicle
tripVehicle =
    Relationship "vehicle"


tripRoute : Relationship Trip Route
tripRoute =
    Relationship "route"


tripRoutePattern : Relationship Trip RoutePattern
tripRoutePattern =
    Relationship "route_pattern"


tripService : Relationship Trip Service
tripService =
    Relationship "service"


tripShape : Relationship Trip Shape
tripShape =
    Relationship "shape"



-- Service
-- (no includes from Service)
-- Shape


shapeRoute : Relationship Shape Route
shapeRoute =
    Relationship "route"


shapeStops : Relationship Shape Stop
shapeStops =
    Relationship "stops"



-- Stops
-- Stop


stopParentStation : Relationship Stop Stop
stopParentStation =
    Relationship "parent_station"


stopChildStops : Relationship Stop Stop
stopChildStops =
    Relationship "child_stops"


stopRecommendedTransfers : Relationship Stop Stop
stopRecommendedTransfers =
    Relationship "recommended_transfers"


stopFacilities : Relationship Stop Facility
stopFacilities =
    Relationship "facilities"



-- Facility


facilityStop : Relationship Facility Stop
facilityStop =
    Relationship "stop"



-- LiveFacility


liveFacilityFacility : Relationship LiveFacility Facility
liveFacilityFacility =
    Relationship "facility"



-- Alerts
-- Alert


alertRoutes : Relationship Alert Route
alertRoutes =
    Relationship "routes"


alertTrips : Relationship Alert Trip
alertTrips =
    Relationship "trips"


alertStops : Relationship Alert Stop
alertStops =
    Relationship "stops"


alertFacilities : Relationship Alert Facility
alertFacilities =
    Relationship "facilities"
