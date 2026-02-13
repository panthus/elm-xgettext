# Agent Guide for elm-xgettext

## Overview

elm-xgettext is an Elm command-line tool that parses Elm source files to extract translation strings using the
`panthus/elm-gettext` library, generating POT (Portable Object Template) files for use with translation tools
like Poedit or GNU gettext. And it can convert PO files into MO files.

## Tools

- Build command: `npm run build`
- Test command: `npm test`

## Finding Elm packages docs

1. Read the `elm.json` file in the current project to get the package name in format <author>/<package> and <version>.
2. Then immediately read the specified documentation files using the exact path format:
   `$HOME/.elm/0.19.1/packages/<author>/<package>/<version>/README.md`
   `$HOME/.elm/0.19.1/packages/<author>/<package>/<version>/docs.json`

Important: Use shell commands (`cat`, `head`, etc.) instead of built-in file reading tools when accessing these paths, as built-in tools may not have access to the full system paths.

For example, if the package is elm/bytes with version 1.0.8:
- Read: $HOME/.elm/0.19.1/packages/elm/bytes/1.0.8/README.md
- Read: $HOME/.elm/0.19.1/packages/elm/bytes/1.0.8/docs.json