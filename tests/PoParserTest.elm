module PoParserTest exposing (suite)

import Array
import Expect
import Parser
import PoParser
import Test


poFile : String
poFile =
    """#: Translation.elm:54
msgid "Hello {name}"
msgstr "Hoi {name}"

#: Translation.elm:55
msgctxt "food"
msgid "Spoiled"
msgstr "Bedorven"

msgctxt ""
msgid "Spoiled"
msgstr "Bedorven"

#: Translation.elm:56
msgid "Apple"
msgid_plural "Apples"
msgstr[0] "Appel"
msgstr[1] "Appels"

msgctxt ""
"first a \\" "
"second a 
"
msgid "First "
"Second"
msgstr "Eerste "
"Tweede\""""


poResult : List PoParser.PoEntry
poResult =
    [ { comments = [ ": Translation.elm:54" ]
      , context = Nothing
      , pluralText = Nothing
      , text = "Hello {name}"
      , translations = Array.fromList [ "Hoi {name}" ]
      }
    , { comments = [ ": Translation.elm:55" ]
      , context = Just "food"
      , pluralText = Nothing
      , text = "Spoiled"
      , translations = Array.fromList [ "Bedorven" ]
      }
    , { comments = []
      , context = Just ""
      , pluralText = Nothing
      , text = "Spoiled"
      , translations = Array.fromList [ "Bedorven" ]
      }
    , { comments = [ ": Translation.elm:56" ]
      , context = Nothing
      , pluralText = Just "Apples"
      , text = "Apple"
      , translations = Array.fromList [ "Appel", "Appels" ]
      }
    , { comments = []
      , context = Just "first a \" second a \n"
      , pluralText = Nothing
      , text = "First Second"
      , translations = Array.fromList [ "Eerste Tweede" ]
      }
    ]


suite : Test.Test
suite =
    Test.test "Parse the given po file" <|
        \_ ->
            Expect.equal (Ok poResult) (Parser.run PoParser.parser poFile)
