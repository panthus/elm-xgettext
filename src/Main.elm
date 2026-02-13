port module Main exposing (main)

import Base64
import MoEncoder
import Parser
import Platform
import Platform.Cmd as Cmd
import PoParser
import XGetText


port logError : String -> Cmd msg


port saveFile : { outputPath : String, content : String, encoding : String } -> Cmd msg


port generatePotFile : ({ outputPath : String } -> msg) -> Sub msg


port parseElmFile : ({ content : String } -> msg) -> Sub msg


port parsePoFile : ({ content : String, outputPath : String } -> msg) -> Sub msg


type Msg
    = ParseElmFile { content : String }
    | ParsePoFile { content : String, outputPath : String }
    | GeneratePotFile { outputPath : String }


main : Program () XGetText.Translations Msg
main =
    Platform.worker { init = init, update = update, subscriptions = subscriptions }


init : flags -> ( XGetText.Translations, Cmd Msg )
init _ =
    ( XGetText.empty, Cmd.none )


update : Msg -> XGetText.Translations -> ( XGetText.Translations, Cmd Msg )
update msg model =
    case msg of
        ParseElmFile { content } ->
            case XGetText.parse content model of
                Ok translations ->
                    ( translations, Cmd.none )

                Err error ->
                    ( model, logError error )

        ParsePoFile { content, outputPath } ->
            case Parser.run PoParser.parser content of
                Ok entries ->
                    ( model
                    , saveFile
                        { outputPath = outputPath
                        , content =
                            entries
                                |> MoEncoder.encode
                                |> Base64.fromBytes
                                |> Maybe.withDefault ""
                        , encoding = "base64"
                        }
                    )

                Err error ->
                    ( model, "Failed to parse PO file: " ++ Parser.deadEndsToString error |> logError )

        GeneratePotFile { outputPath } ->
            ( model, saveFile { content = XGetText.toPotFile model, encoding = "utf8", outputPath = outputPath } )


subscriptions : XGetText.Translations -> Sub Msg
subscriptions _ =
    Sub.batch [ parseElmFile ParseElmFile, parsePoFile ParsePoFile, generatePotFile GeneratePotFile ]
