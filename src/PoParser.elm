module PoParser exposing (PoEntry, parser)

import Array exposing (Array)
import Parser exposing ((|.), (|=))


type alias PoEntry =
    { comments : List String
    , context : Maybe String
    , text : String
    , pluralText : Maybe String

    -- The translations for text and pluralText. The array index indicates which plural form it is.
    , translations : Array String
    }


parser : Parser.Parser (List PoEntry)
parser =
    Parser.loop []
        (\result ->
            Parser.oneOf
                [ Parser.succeed (\s -> Parser.Loop (s :: result))
                    |= entry
                    |. Parser.spaces
                , Parser.end
                    |> Parser.map (\_ -> Parser.Done (List.reverse result))
                ]
        )


entry : Parser.Parser PoEntry
entry =
    Parser.succeed (\c ctx t pt tr -> { comments = c, context = ctx, text = t, pluralText = pt, translations = tr })
        |= comments
        |= optional (field "msgctxt")
        |= field "msgid"
        |= optional (field "msgid_plural")
        |= Parser.loop Array.empty
            (\result ->
                Parser.oneOf
                    [ Parser.succeed (\s -> Parser.Loop (Array.push s result))
                        |= field ("msgstr[" ++ (result |> Array.length |> String.fromInt) ++ "]")
                    , Parser.succeed (\s -> Parser.Loop (Array.push s result))
                        |= field "msgstr"
                    , if result == Array.empty then
                        Parser.problem "At least one msgstr field is required."

                      else
                        Parser.succeed ()
                            |> Parser.map (\_ -> Parser.Done result)
                    ]
            )


optional : Parser.Parser a -> Parser.Parser (Maybe a)
optional parser_ =
    Parser.oneOf [ Parser.map Just parser_, Parser.succeed Nothing ]


comments : Parser.Parser (List String)
comments =
    Parser.loop []
        (\result ->
            Parser.oneOf
                [ Parser.succeed (\s -> Parser.Loop (s :: result))
                    |. Parser.symbol "#"
                    |= (Parser.chompUntilEndOr "\n" |> Parser.getChompedString)
                    |. Parser.spaces
                , Parser.succeed ()
                    |> Parser.map (\_ -> Parser.Done (List.reverse result))
                ]
        )


field : String -> Parser.Parser String
field name =
    Parser.succeed identity
        |. Parser.keyword name
        |. Parser.chompWhile (\c -> c == ' ')
        |= Parser.loop []
            (\result ->
                Parser.oneOf
                    [ Parser.succeed (\s -> Parser.Loop (s :: result))
                        |= string
                        |. Parser.spaces
                    , if result == [] then
                        "Field " ++ name ++ " must be followed by a string on the same line." |> Parser.problem

                      else
                        Parser.succeed ()
                            |> Parser.map (\_ -> result |> List.reverse |> String.join "" |> Parser.Done)
                    ]
            )


string : Parser.Parser String
string =
    Parser.succeed identity
        |. Parser.symbol "\""
        |= Parser.loop ""
            (\result ->
                Parser.oneOf
                    [ Parser.symbol "\\\""
                        |> Parser.map (\_ -> Parser.Loop (result ++ "\""))
                    , Parser.symbol "\""
                        |> Parser.map (\_ -> Parser.Done result)
                    , Parser.symbol "\\\\"
                        |> Parser.map (\_ -> Parser.Loop (result ++ "\\\\"))
                    , Parser.symbol "\\"
                        |> Parser.map (\_ -> Parser.Loop (result ++ "\\"))
                    , Parser.chompWhile (\char -> char /= '\\' && char /= '"')
                        |> Parser.getChompedString
                        |> Parser.map (\s -> Parser.Loop (result ++ s))
                    ]
            )
