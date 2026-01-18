module XGetTextTest exposing (suite)

import Expect
import Test
import XGetText


src : String
src =
    """module Foo exposing (t)

import Html exposing (..)
import GetText as T

main =
    main_ []
        [ p [] [ T.t [] "some\\"Text\\n" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "someText" |> text ]
        , p [] [ T.t [] "some long line that I do not know the length of when do you think I need to end it hallo some long line that I do not know the length of when do you think I\\n need to \\nend it hallo" |> text ]
        , p [] [ T.tpn [] "contextsome" 1 "textsome" "pluralsome" |> text ]
        ]
"""


pot : String
pot =
    """#: Foo.elm:8
msgid "some\\"Text\\n"
msgstr ""

#: Foo.elm:9 Foo.elm:10 Foo.elm:11 Foo.elm:12 Foo.elm:13 Foo.elm:14 Foo.elm:15 
#: Foo.elm:16 Foo.elm:17 Foo.elm:18 Foo.elm:19 Foo.elm:20 Foo.elm:21 Foo.elm:22 
#: Foo.elm:23
msgid "someText"
msgstr ""

#: Foo.elm:24
msgid ""
"some long line that I do not know the length of when do you think I need to "
"end it hallo some long line that I do not know the length of when do you "
"think I\\n"
" need to \\n"
"end it hallo"
msgstr ""

#: Foo.elm:25
msgctxt "contextsome"
msgid "textsome"
msgid_plural "pluralsome"
msgstr[0] ""
msgstr[1] \"\""""


suite : Test.Test
suite =
    Test.test "elm-xgettext should create a correct pot file" <|
        \_ ->
            Expect.equal pot
                (XGetText.parse src XGetText.empty |> Result.withDefault XGetText.empty |> XGetText.toPotFile)
