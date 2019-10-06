module ResultHelpers exposing (combine)

{-| Combine a list of results into a single result (holding a list).

Ok if all inputs are ok

Copied from elm-community/Result.Extra
[docs](https://package.elm-lang.org/packages/elm-community/result-extra/latest/Result-Extra#combine)
[source](https://github.com/elm-community/result-extra/blob/2.2.1/src/Result/Extra.elm#L111)

-}


combine : List (Result x a) -> Result x (List a)
combine =
    List.foldr (Result.map2 (::)) (Ok [])
