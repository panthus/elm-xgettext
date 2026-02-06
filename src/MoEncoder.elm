module MoEncoder exposing (encode)

import Array
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Encode as Encode
import List
import PoParser exposing (PoEntry)


{-| Convert a list of PO entries to MO file format.
-}
encode : List PoEntry -> Bytes
encode poEntries =
    let
        headerSize =
            28

        numOfStrings =
            poEntries |> List.length

        stringTableSize =
            -- Length + offset of each string
            numOfStrings * 4 * 2

        offsetOriginalStringTable =
            headerSize

        offsetTranslationStringTable =
            headerSize + stringTableSize

        offsetHashingTable =
            headerSize + stringTableSize + stringTableSize

        offsetOriginalString =
            -- Hashing table is omitted so this offset is same
            offsetHashingTable

        {- File outline:
           - 28 bytes header
           - length + offset of original strings. Note NUL not included in length
           - length + offset of translation strings. Note only the last NUL is not included in length
           - hash table not included here, so offsetHashingTable == offsetOriginalString
           - original strings NUL terminated, if context then context + EOT + string
           - translation strings NUL separated and the whole is NUL terminated
        -}
        ( originalStrings, translationStrings ) =
            List.foldr
                (\poEntry ( o, t ) ->
                    let
                        originalString =
                            toOriginalString poEntry

                        translationString =
                            toTranslationString poEntry
                    in
                    ( { length = String.length originalString
                      , string = originalString ++ "\u{0000}" |> Encode.string
                      }
                        :: o
                    , { length = String.length translationString
                      , string = translationString ++ "\u{0000}" |> Encode.string
                      }
                        :: t
                    )
                )
                ( [], [] )
                -- lexicographical order
                (poEntries |> List.sortBy toOriginalString)

        header =
            Encode.sequence
                [ Encode.unsignedInt32 LE 0x950412DE -- magic number
                , Encode.unsignedInt32 LE 0 -- file format revision
                , Encode.unsignedInt32 LE numOfStrings -- number of strings
                , Encode.unsignedInt32 LE offsetOriginalStringTable -- offset of table with original strings
                , Encode.unsignedInt32 LE offsetTranslationStringTable -- offset of table with translation strings
                , Encode.unsignedInt32 LE 0 -- size of hashing table
                , Encode.unsignedInt32 LE offsetHashingTable -- offset of hashing table
                ]

        ( offsetTranslationString, originalStringTable ) =
            originalStrings |> toStringsTable offsetOriginalString

        ( _, translationStringTable ) =
            translationStrings |> toStringsTable offsetTranslationString
    in
    Encode.sequence
        [ header
        , originalStringTable |> Encode.sequence
        , translationStringTable |> Encode.sequence
        , originalStrings |> List.map .string |> Encode.sequence
        , translationStrings |> List.map .string |> Encode.sequence
        ]
        |> Encode.encode


toOriginalString : PoEntry -> String
toOriginalString poEntry =
    (poEntry.context
        |> Maybe.map (\c -> c ++ "\u{0004}" ++ poEntry.text)
        |> Maybe.withDefault poEntry.text
    )
        ++ (poEntry.pluralText
                |> Maybe.map (\p -> "\u{0000}" ++ p)
                |> Maybe.withDefault ""
           )


toTranslationString : PoEntry -> String
toTranslationString poEntry =
    poEntry.translations |> Array.toList |> String.join "\u{0000}"


toStringsTable : Int -> List { a | length : Int } -> ( Int, List Encode.Encoder )
toStringsTable initialOffset strings =
    strings
        |> List.foldl
            (\entry ( offset, result ) ->
                -- Note + 1 because NUL byte not included in length
                ( offset + entry.length + 1
                , Encode.sequence
                    [ Encode.unsignedInt32 LE entry.length
                    , Encode.unsignedInt32 LE offset
                    ]
                    :: result
                )
            )
            ( initialOffset, [] )
