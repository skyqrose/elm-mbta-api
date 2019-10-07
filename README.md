# Elm MBTA API

Elm interface for the [MBTA API](https://api-v3.mbta.com/)

Under construction.

Get an stream data, and work with it in a type safe way.

Functions for fetching and streaming data and in `Mbta.Api`,
and the resulting types are all in `Mbta`.

## Examples

Two of my apps, [which-bus](https://github.com/skyqrose/which-bus) and [mbta-old-colony-timetable](https://github.com/skyqrose/mbta-old-colony-timetable) use this library, and can be used as examples.

## Maintenance

The MBTA API is under active development,
and frequently sees new features and occasionally (with warning) breaking changes.
I follow API updates pretty closely,
but updates to this library will necessarily lag a little bit behind.

Follow the [Developer Google Group](https://groups.google.com/forum/#!forum/massdotdevelopers) to hear about API changes.

## JSON:API Decoding

The MBTA API uses JSON:API.
For this library, I wrote a system for decoding JSON:API data
that I may break out into its own package some day.
It's in `src/JsonApi.elm`,
and there's an example of its use in `src/Mbta/Decode.elm`.
If you're interested in decoding JSON:API data in Elm in any other contexts,
please take a look.

## Disclaimer

I have worked on the official MBTA API,
but this wrapper is an unofficial side project I made in my spare time.
