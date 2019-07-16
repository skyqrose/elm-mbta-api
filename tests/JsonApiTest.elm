module JsonApiTest exposing (suite)

import DecodeHelpers
import Dict
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


bookResourceDecoder : ResourceDecoder Book
bookResourceDecoder =
    decode Book
        |> id bookIdDecoder
        |> relationshipOne "author" authorIdDecoder
        |> attribute "title" Json.Decode.string
        |> relationshipMaybe "sequel" bookIdDecoder


authorResourceDecoder : ResourceDecoder Author
authorResourceDecoder =
    decode Author
        |> id authorIdDecoder
        |> relationshipMany "books" bookIdDecoder


type alias Included =
    { books : List Book
    , authors : List Author
    }


includedDecoder : IncludedDecoder Included
includedDecoder =
    { emptyIncluded =
        { books = []
        , authors = []
        }
    , accumulator =
        [ ( "book"
          , bookResourceDecoder
                |> JsonApi.map
                    (\book ->
                        \included ->
                            { included
                                | books = book :: included.books
                            }
                    )
          )
        , ( "author"
          , authorResourceDecoder
                |> JsonApi.map
                    (\author ->
                        \included ->
                            { included
                                | authors = author :: included.authors
                            }
                    )
          )
        ]
            |> Dict.fromList
            |> JsonApi.oneOf
    }


booksDocumentDecoder : DocumentDecoder Included (List Book)
booksDocumentDecoder =
    JsonApi.documentDecoderMany includedDecoder bookResourceDecoder


authorDocumentDecoder : DocumentDecoder Included Author
authorDocumentDecoder =
    JsonApi.documentDecoderOne includedDecoder authorResourceDecoder


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
    "data": {
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
    },
    "included": [
        {
            "id": "book1",
            "type": "book",
            "attributes": {
                "title": "Book 1"
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
        [ test "documentDecoderMany with id, attributes, relationshipOne, relationshipMaybe" <|
            \() ->
                booksJson
                    |> JsonApi.decodeDocumentString booksDocumentDecoder
                    |> Result.map JsonApi.documentData
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
        , test "documentDecoderOne with id, relationshipMany" <|
            \() ->
                authorJson
                    |> JsonApi.decodeDocumentString authorDocumentDecoder
                    |> Result.map JsonApi.documentData
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
                badTypeJson
                    |> JsonApi.decodeDocumentString authorDocumentDecoder
                    |> Expect.equal
                        (Err
                            (DocumentError
                                (ResourceError
                                    (ResourceIdError
                                        { expectedType = "author"
                                        , actualType = "not author"
                                        , actualIdValue = "author1"
                                        }
                                    )
                                )
                            )
                        )
        , test "returns included data" <|
            \() ->
                authorJson
                    |> JsonApi.decodeDocumentString authorDocumentDecoder
                    |> Result.map JsonApi.documentIncluded
                    |> Expect.equal
                        (Ok
                            { books =
                                [ { id = BookId "book1"
                                  , author = AuthorId "author1"
                                  , title = "Book 1"
                                  , sequel = Nothing
                                  }
                                ]
                            , authors = []
                            }
                        )
        ]
