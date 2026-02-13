module XGetText exposing (Translations, empty, parse, toPotFile)

import Dict exposing (Dict)
import Elm.Parser
import Elm.Syntax.Declaration as Decl
import Elm.Syntax.Exposing as Exposing
import Elm.Syntax.Expression as Expr
import Elm.Syntax.Import as Import
import Elm.Syntax.Module as Module
import Elm.Syntax.Node as Node
import Json.Encode as Encode


parse : String -> Translations -> Result String Translations
parse input translations =
    case Elm.Parser.parseToFile input of
        Err _ ->
            Err "Failed to parse, please check for any compilation errors in your Elm code."

        Ok file ->
            walkDeclarations
                ([ ( "GetText"
                   , [ ( "t", { context = Nothing, text = 2, pluralText = Nothing } )
                     , ( "tn", { context = Nothing, text = 3, pluralText = Just 4 } )
                     , ( "tp", { context = Just 2, text = 3, pluralText = Nothing } )
                     , ( "tpn", { context = Just 2, text = 4, pluralText = Just 5 } )
                     ]
                        |> Dict.fromList
                   )
                 ]
                    |> Dict.fromList
                    |> addTargets file.imports
                )
                (toFileName file.moduleDefinition)
                file.declarations
                translations
                |> Ok


toFileName : Node.Node Module.Module -> String
toFileName (Node.Node _ moduleDefinition) =
    Module.moduleName moduleDefinition ++ [ "elm" ] |> String.join "."


{-| Given the import statements in the file add the variations of the fully qualified targets
(eg <moduleName>.<functionName>) to the targets as indicated by the import statements.

The given targets outer key is the moduleName and inner key is the functionName. This function will then add multiple
keys in the returned Targets dict based on the import statements in the file, for example for fully qualified
moduleName `GetText` and functionName `t` it will add the variations like this:

    import GetText -> key: GetText.t

    import GetText as T -> key: T.t

    import GetText as T exposing (t) -> key: t and key: T.t

    import GetText exposing (t) -> key: t and key: GetText.t

-}
addTargets : List (Node.Node Import.Import) -> Dict String Targets -> Targets
addTargets imports targets =
    imports
        |> List.foldl
            (\(Node.Node _ imp) result ->
                let
                    moduleName =
                        imp.moduleName |> Node.value |> String.join "."
                in
                case Dict.get moduleName targets of
                    Just target ->
                        imp.moduleAlias
                            |> Maybe.map
                                (\(Node.Node _ a) ->
                                    target |> Dict.foldl (\k -> Dict.insert (a ++ [ k ] |> String.join ".")) result
                                )
                            |> Maybe.withDefault
                                (target
                                    |> Dict.foldl (\k -> Dict.insert ([ moduleName, k ] |> String.join ".")) result
                                )
                            |> (\r ->
                                    imp.exposingList
                                        |> Maybe.map
                                            (\(Node.Node _ a) ->
                                                case a of
                                                    Exposing.All _ ->
                                                        r

                                                    Exposing.Explicit expl ->
                                                        expl
                                                            |> List.foldl
                                                                (\(Node.Node _ e) re ->
                                                                    case e of
                                                                        Exposing.FunctionExpose f ->
                                                                            case Dict.get f target of
                                                                                Just targetArgs ->
                                                                                    Dict.insert f targetArgs re

                                                                                Nothing ->
                                                                                    re

                                                                        _ ->
                                                                            re
                                                                )
                                                                r
                                            )
                                        |> Maybe.withDefault r
                               )

                    Nothing ->
                        result
            )
            Dict.empty


{-| The translation functions that we need to extract the context, text and pluralText for.
The key is the function name as it occurs in the module in format:

  - <moduleName>.<functionName>
  - <moduleAlias>.<functionName>
  - <functionName>

Note that `addTargets` will add the relevant keys based on the import statements in the file that is parsed.

The value record contains the one-based-indexes of the parameters that contains the respective value.

-}
type alias Targets =
    Dict String (TranslationEntry Int)


type alias TranslationEntry a =
    { context : Maybe a
    , text : a
    , pluralText : Maybe a
    }


{-| The parsed translations.

We need to maintain the sorting as in the source because the context of translations entries is then better to
understand by the translator (for example for split sentences over multiple translation entries).
Note the list is in reverse order so reverse it when creating the POT file.

The `text` or in case context is provided `context\\u{0004}text` must be unique.
Note that no-context and empty-context are treated differently.

-}
type alias Translations =
    ( Dict String (List { fileName : String, lineNumber : Int }), List (TranslationEntry String) )


empty : Translations
empty =
    ( Dict.empty, [] )


insert : Maybe String -> String -> Maybe String -> String -> Int -> Translations -> Translations
insert context text pluralText fileName lineNumber ( dict, list ) =
    let
        key =
            toKey context text

        reference =
            { fileName = fileName, lineNumber = lineNumber }
    in
    case Dict.get key dict of
        Just references ->
            ( Dict.insert key (reference :: references) dict, list )

        Nothing ->
            ( Dict.insert key [ reference ] dict
            , { context = context, text = text, pluralText = pluralText } :: list
            )


toKey : Maybe String -> String -> String
toKey context text =
    (context |> Maybe.map (\c -> c ++ "\u{0004}") |> Maybe.withDefault "") ++ text


sliceOnIndexes : String -> List Int -> List String
sliceOnIndexes string indexes =
    String.length string
        :: indexes
        |> List.sort
        |> List.foldl
            (\i ( iPrev, r ) ->
                if iPrev == i then
                    ( iPrev, r )

                else
                    ( i + 1, String.slice iPrev (i + 1) string :: r )
            )
            ( 0, [] )
        |> Tuple.second
        |> List.reverse


breakOnNewLine : String -> List String
breakOnNewLine string =
    string |> String.indexes "\n" |> sliceOnIndexes string


{-| Break a string on the closest space before the max character.
-}
breakAt : Int -> String -> List String
breakAt max string =
    string
        |> String.indexes " "
        |> List.foldl
            (\i ( iPrev, rPrev, r ) ->
                if i - rPrev < max then
                    ( i, rPrev, r )

                else if i - rPrev == max then
                    ( i, i, i :: r )

                else
                    ( i, iPrev, iPrev :: r )
            )
            ( 0, 0, [] )
        |> (\( iPrev, rPrev, r ) ->
                if String.length string - rPrev > max then
                    iPrev :: r

                else
                    r
           )
        |> sliceOnIndexes string


breakOnNewLineAndAt : Int -> String -> List String
breakOnNewLineAndAt max string =
    string |> breakOnNewLine |> List.map (breakAt max) |> List.concat


{-| Make sure strings are escaped for things like ", \\n etc
Note that this also inserts quotes around the string
-}
encode : String -> String
encode =
    Encode.string >> Encode.encode 0


formatPotElement : Int -> String -> List String -> String
formatPotElement max prefix list =
    let
        multi =
            (prefix ++ " \"\"") :: (list |> List.map encode) |> String.join "\n"
    in
    case list of
        [ one ] ->
            let
                single =
                    prefix ++ " " ++ encode one
            in
            if String.length single > max then
                multi

            else
                single

        _ ->
            multi


{-| A file in format: <https://www.gnu.org/software/gettext/manual/gettext.html#The-Format-of-PO-Files>
-}
toPotFile : Translations -> String
toPotFile ( referenceDict, translations ) =
    translations
        |> List.map
            (\t ->
                let
                    max =
                        80

                    references =
                        Dict.get (toKey t.context t.text) referenceDict
                            |> Maybe.map
                                (List.map (\r -> r.fileName ++ ":" ++ String.fromInt r.lineNumber)
                                    >> List.reverse
                                    >> String.join " "
                                )
                            |> Maybe.withDefault ""
                            -- -3 for `#: `
                            |> breakOnNewLineAndAt (max - 3)
                            |> List.map (\r -> "#: " ++ r)
                            |> String.join "\n"

                    context =
                        t.context
                            -- -2 for the quotes
                            |> Maybe.map (breakOnNewLineAndAt (max - 2) >> formatPotElement max "msgctxt")
                            |> Maybe.withDefault ""

                    text =
                        -- -2 for the quotes
                        t.text |> breakOnNewLineAndAt (max - 2) |> formatPotElement max "msgid"

                    pluralText =
                        t.pluralText
                            |> Maybe.map
                                -- -2 for the quotes
                                (breakOnNewLineAndAt (max - 2)
                                    >> formatPotElement max "msgid_plural"
                                    >> (\p -> p ++ "\nmsgstr[0] \"\"\nmsgstr[1] \"\"")
                                )
                            |> Maybe.withDefault "msgstr \"\""
                in
                [ references, context, text, pluralText ] |> List.filter (String.isEmpty >> not) |> String.join "\n"
            )
        |> List.reverse
        |> String.join "\n\n"


walkDeclarations : Targets -> String -> List (Node.Node Decl.Declaration) -> Translations -> Translations
walkDeclarations targets fileName declarations translations =
    declarations
        |> List.foldl
            (\(Node.Node _ decl) result ->
                case decl of
                    Decl.FunctionDeclaration func ->
                        result
                            |> (func.declaration
                                    |> Node.value
                                    |> .expression
                                    |> walkExpression targets fileName
                               )

                    Decl.AliasDeclaration _ ->
                        result

                    Decl.CustomTypeDeclaration _ ->
                        result

                    Decl.PortDeclaration _ ->
                        result

                    Decl.InfixDeclaration _ ->
                        result

                    Decl.Destructuring _ e ->
                        result |> walkExpression targets fileName e
            )
            translations


walkExpression : Targets -> String -> Node.Node Expr.Expression -> Translations -> Translations
walkExpression targets fileName (Node.Node _ expr) translations =
    case expr of
        Expr.UnitExpr ->
            translations

        Expr.Application ((Node.Node { start } (Expr.FunctionOrValue moduleName name)) :: args) ->
            case Dict.get (moduleName ++ [ name ] |> String.join ".") targets of
                Just t ->
                    let
                        ( _, p ) =
                            args
                                |> List.foldl
                                    (\(Node.Node _ exp) ( i, result ) ->
                                        ( i + 1
                                        , case exp of
                                            Expr.Literal x ->
                                                if Just i == t.context then
                                                    { result | context = Just x }

                                                else if i == t.text then
                                                    { result | text = Just x }

                                                else if Just i == t.pluralText then
                                                    { result | pluralText = Just x }

                                                else
                                                    result

                                            _ ->
                                                result
                                        )
                                    )
                                    ( 1, { context = Nothing, text = Nothing, pluralText = Nothing } )
                    in
                    p.text
                        |> Maybe.map
                            (\text ->
                                insert
                                    p.context
                                    text
                                    p.pluralText
                                    fileName
                                    start.row
                                    translations
                            )
                        |> Maybe.withDefault translations

                Nothing ->
                    args |> List.foldl (\n -> walkExpression targets fileName n) translations

        Expr.Application l ->
            l |> List.foldl (\n -> walkExpression targets fileName n) translations

        Expr.OperatorApplication _ _ left right ->
            translations |> walkExpression targets fileName left |> walkExpression targets fileName right

        Expr.FunctionOrValue _ _ ->
            translations

        Expr.IfBlock c t e ->
            translations
                |> walkExpression targets fileName c
                |> walkExpression targets fileName t
                |> walkExpression targets fileName e

        Expr.PrefixOperator _ ->
            translations

        Expr.Operator _ ->
            translations

        Expr.Hex _ ->
            translations

        Expr.Integer _ ->
            translations

        Expr.Floatable _ ->
            translations

        Expr.Negation x ->
            translations |> walkExpression targets fileName x

        Expr.Literal _ ->
            translations

        Expr.CharLiteral _ ->
            translations

        Expr.TupledExpression xs ->
            xs |> List.foldl (\n -> walkExpression targets fileName n) translations

        Expr.ListExpr xs ->
            xs |> List.foldl (\n -> walkExpression targets fileName n) translations

        Expr.ParenthesizedExpression x ->
            translations |> walkExpression targets fileName x

        Expr.LetExpression x ->
            (x.declarations
                |> List.foldl
                    (\(Node.Node _ decl) ->
                        case decl of
                            Expr.LetFunction f ->
                                f.declaration |> Node.value |> .expression |> walkExpression targets fileName

                            Expr.LetDestructuring _ e ->
                                walkExpression targets fileName e
                    )
                    translations
            )
                |> walkExpression targets fileName x.expression

        Expr.CaseExpression c ->
            translations
                |> walkExpression targets fileName c.expression
                |> (\t -> c.cases |> List.foldl (\( _, x ) -> walkExpression targets fileName x) t)

        Expr.LambdaExpression x ->
            translations |> walkExpression targets fileName x.expression

        Expr.RecordAccess exp _ ->
            translations |> walkExpression targets fileName exp

        Expr.RecordAccessFunction _ ->
            translations

        Expr.RecordExpr xs ->
            xs |> List.foldl (\(Node.Node _ ( _, x )) -> walkExpression targets fileName x) translations

        Expr.RecordUpdateExpression _ updates ->
            updates |> List.foldl (\(Node.Node _ ( _, x )) -> walkExpression targets fileName x) translations

        Expr.GLSLExpression _ ->
            translations
