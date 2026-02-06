module MoEncoderTest exposing (..)

import Expect
import MoEncoder
import MoPoFile
import Parser
import PoParser
import Test


suite : Test.Test
suite =
    Test.test "Encode the given po file to mo file" <|
        \_ ->
            case Parser.run PoParser.parser MoPoFile.poFile of
                Ok po ->
                    Expect.equal MoPoFile.moFile (MoEncoder.encode po)

                Err e ->
                    e |> Debug.toString |> Expect.fail
