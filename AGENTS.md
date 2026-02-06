# Agent Guide for elm-xgettext

This document provides essential information for agents working with this Elm project that extracts gettext 
translations from Elm source code.

## Project Overview

This is an Elm command-line tool that parses Elm source files and extracts translation strings using the 
`panthus/elm-gettext` library. It generates POT (Portable Object Template) files that can be used by translation tools 
like Poedit or GNU gettext.

The project consists of:
- `index.js`: Node.js entry point that handles CLI arguments and file processing
- `src/XGetText.elm`: Main Elm application that parses Elm files and extracts translations
- `src/PoParser.elm`: Parser for PO files (currently unused in the main workflow)
- `src/MoEncoder.elm`: Placeholder module (currently empty)

## Code Structure

### Main Components

1. **CLI Interface** (`index.js`):
   - Command-line argument parsing
   - File system operations
   - Elm port communication
   - Usage instructions

2. **Elm Parser Application** (`src/XGetText.elm`):
   - Uses Elm's parser library to analyze source code
   - Walks through declarations and expressions
   - Identifies translation function calls (t, tn, tp, tpn)
   - Extracts context, text, and plural forms
   - Generates POT files

3. **PO Parser** (`src/PoParser.elm`):
   - Parser for PO files using Elm's Parser library
   - Currently not used in the main workflow but shows parsing capabilities

## Build and Development Commands

### Build
```bash
npm run build
```

This compiles the Elm code to JavaScript using `elm make`.

### Test
```bash
npm test
```

Runs tests using `elm-test-rs`.

### Development
The project uses Elm's standard workflow with:
- `elm` for compilation
- `elm-format` for code formatting
- `elm-test-rs` for testing

## Key Features and Patterns

### Translation Function Recognition

The parser recognizes translation functions from the `GetText` module (and aliased imports) with these patterns:
- `t` - simple translation
- `tn` - plural translation 
- `tp` - translation with context
- `tpn` - plural translation with context

### Translation Extraction Process

1. The tool parses Elm files using Elm's parser library
2. It identifies import statements to understand how translation functions are referenced
3. It walks through declarations and expressions looking for translation function calls
4. For each call, it extracts:
   - Context (optional)
   - Text to translate
   - Plural form text (for plural translations)
5. It generates a POT file with proper formatting

### File Processing Flow

1. CLI parses arguments (`-h`, `--help`, `-o`, `--output`)
2. For each input file, reads the content
3. Sends content to Elm application via port
4. Elm application processes the file and extracts translations
5. Final POT file is generated and saved to output location

## Testing Approach

The project uses `elm-test-rs` for testing. Tests are written in Elm and likely test:
- Translation extraction functionality
- Parser behavior with various input files
- POT file generation
- Edge cases in translation handling

## Important Gotchas

1. **Elm Syntax Parsing**: Uses Elm's official parser library to analyze syntax, which means it needs to handle all 
valid Elm constructs properly.

2. **Import Handling**: The tool correctly handles different import patterns:
   - `import GetText`
   - `import GetText as T`  
   - `import GetText exposing (t)`
   - `import GetText as T exposing (t)`

3. **Translation Function Parameters**: Translation functions are expected to have specific parameter positions for 
context, text, and plural text.

4. **POT File Format**: Generated files follow GNU gettext POT format with proper escaping of special characters.

5. **File Naming**: Uses the module name from Elm files as part of the filename reference in POT file comments.

## Development Workflow

1. Make changes to Elm code in `src/`
2. Limit line length to 120 characters. Use `cat <file> | fold -sw 120 | tee <file>` to do this.
3. Run `npm run build` to compile
4. Test with `npm test` 
5. Use `npm run build && node index.js src/**/*.elm -o translations.pot` to test with actual files

## Finding Elm packages docs

1. Read the `elm.json` file in the current project to get the package name in format <author>/<package> and <version>.
2. Then immediately read the specified documentation files using the exact path format:
   `$HOME/.elm/0.19.1/packages/<author>/<package>/<version>/README.md`
   `$HOME/.elm/0.19.1/packages/<author>/<package>/<version>/docs.json`

Important: Use shell commands (`cat`, `head`, etc.) instead of built-in file reading tools when accessing these paths, as built-in tools may not have access to the full system paths.

For example, if the package is elm/bytes with version 1.0.8:
- Read: $HOME/.elm/0.19.1/packages/elm/bytes/1.0.8/README.md
- Read: $HOME/.elm/0.19.1/packages/elm/bytes/1.0.8/docs.json

## Dependencies

- Node.js (for CLI)
- Elm (for parsing and compilation)
- elm-test-rs (for testing)
- elm-format (for code formatting)

## Related Tools

This project is designed to work with:
- panthus/elm-gettext library for translation in Elm applications
- GNU gettext tools for localization workflow
- Poedit or similar tools for translating POT files