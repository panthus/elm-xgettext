module MoEncoderTest exposing (..)

import Base64
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
                    Expect.equal
                        (MoPoFile.moFile |> Base64.fromBytes)
                        (po |> MoEncoder.encode |> Base64.fromBytes)

                Err e ->
                    e |> Debug.toString |> Expect.fail
