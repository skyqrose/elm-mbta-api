module JsonApiTest exposing (suite)

import DecodeHelpers
import Expect
import Json.Decode
import JsonApi exposing (..)
import Test exposing (..)


type BookId
    = BookId String


type AuthorId
    = AuthorId String


type alias Book =
    { id : BookId
    , author : AuthorId
    , title : String
    , sequel : Maybe BookId
    }


type alias Author =
    { id : AuthorId
    , books : List BookId
    }


bookIdDecoder : IdDecoder BookId
bookIdDecoder =
    idDecoder "book" BookId


authorIdDecoder : IdDecoder AuthorId
authorIdDecoder =
    idDecoder "author" AuthorId


bookDecoder : Decoder Book
bookDecoder =
    decode Book
        |> id bookIdDecoder
        |> relationshipOne "author" authorIdDecoder
        |> attribute "title" Json.Decode.string
        |> relationshipMaybe "sequel" bookIdDecoder


authorDecoder : Decoder Author
authorDecoder =
    decode Author
        |> id authorIdDecoder
        |> relationshipMany "books" bookIdDecoder


booksJson : String
booksJson =
    """
{
    "data": [
        {
            "id": "book1",
            "type": "book",
            "attributes": {
                "title": "Book 1"
            },
            "relationships": {
                "sequel": {
                    "data": {
                        "type": "book",
                        "id": "book2"
                    }
                },
                "author": {
                    "data": {
                        "type": "author",
                        "id": "author1"
                    }
                }
            }
        },
        {
            "id": "book2",
            "type": "book",
            "attributes": {
                "title": "Book 2"
            },
            "relationships": {
                "sequel": {
                    "data": null
                },
                "author": {
                    "data": {
                        "type": "author",
                        "id": "author1"
                    }
                }
            }
        }
    ]
}
"""


authorJson : String
authorJson =
    """
{
    "data":
        {
            "id": "author1",
            "type": "author",
            "attributes": {},
            "relationships": {
                "books": {
                    "data": [
                        {
                            "type": "book",
                            "id": "book1"
                        },
                        {
                            "type": "book",
                            "id": "book2"
                        }
                    ]
                }
            }
        }
}
"""


badTypeJson : String
badTypeJson =
    """
{
    "data":
        {
            "id": "author1",
            "type": "not author",
            "attributes": {},
            "relationships": {
                "books": {
                    "data": []
                }
            }
        }
}
"""


suite : Test
suite =
    describe "JsonApi"
        [ test "decodeMany with id, attributes, relationshipOne, relationshipMaybe" <|
            \() ->
                Json.Decode.decodeString
                    (decoderMany bookDecoder)
                    booksJson
                    |> Expect.equal
                        (Ok
                            [ { id = BookId "book1"
                              , author = AuthorId "author1"
                              , title = "Book 1"
                              , sequel = Just (BookId "book2")
                              }
                            , { id = BookId "book2"
                              , author = AuthorId "author1"
                              , title = "Book 2"
                              , sequel = Nothing
                              }
                            ]
                        )
        , test "decodeOne with id, relationshipMany" <|
            \() ->
                Json.Decode.decodeString
                    (decoderOne authorDecoder)
                    authorJson
                    |> Expect.equal
                        (Ok
                            { id = AuthorId "author1"
                            , books =
                                [ BookId "book1"
                                , BookId "book2"
                                ]
                            }
                        )
        , test "catches mismatched id types" <|
            \() ->
                Json.Decode.decodeString
                    (decoderOne authorDecoder)
                    badTypeJson
                    |> Expect.err
        ]
