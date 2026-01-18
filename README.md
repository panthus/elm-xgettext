# elm-xgettext

A tool similar to [GNU xgettext](https://www.gnu.org/software/gettext/manual/html_node/xgettext-Invocation.html) that
parses Elm source files to get the translatable strings and generate a PO template file. This PO template file can then
be used by tools like [POEdit](https://poedit.net/) to create the PO files for each language to translate your
application into.

This tool only works for translations specified by the panthus/elm-gettext library.

## Usage
Install with:
```
npm i --save-dev elm-xgettext
```

Run like this:
```
npx elm-xgettext src/**/*.elm -o locale/FE.pot
```