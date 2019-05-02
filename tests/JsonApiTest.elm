module DecodeHelpersTest exposing (suite)

import DecodeHelpers
import Expect
import Json.Decode as Decode
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


bookIdDecoder : ResourceId -> Decoder BookId
bookIdDecoder =
    idDecoder "book" BookId


authorIdDecoder : ResourceId -> Decoder AuthorId
authorIdDecoder =
    idDecoder "author" AuthorId


bookDecoder : Resource -> Decoder Book
bookDecoder =
    decode Book
        |> id bookIdDecoder
        |> relationshipOne "author" authorIdDecoder
        |> attribute "title" Decode.string
        |> relationshipMaybe "sequel" bookIdDecoder

authorDecoder : Resource -> Decoder Author
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
                    "type": "book",
                    "id": "book2"
                },
                "author": {
                    "type": "author",
                    "id": "author 1"
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
                "sequel": null,
                "author": {
                    "type": "author",
                    "id": "author1"
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
    "data": [
        {
            "id": "author1",
            "type": "author",
            "attributes": {},
            "relationships": {
                "books": [
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
    ]
}
"""

badTypeJson : String
badTypeJson =
    """
{
    "data": [
        {
            "id": "author1",
            "type": "not author",
            "attributes": {},
            "relationships": {
                "books": []
            }
        }
    ]
}
"""


suite : Test
suite =
    describe "JsonApi"
        [ describe "enum" <|
            [ test "decodes a value" <|
                \() ->
                    "\"apple\""
                        |> Decode.decodeString fruitDecoder
                        |> Expect.equal (Ok Apple)
            , todo "decodes book with id, attributes, relationshipOne, relationshipMaybe"
            , todo "decodes author with id, relationshipMany"
            , todo "catches mismatched id types"
            ]
        ]
