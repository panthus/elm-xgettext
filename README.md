# elm-xgettext

A tool similar to [GNU xgettext](https://www.gnu.org/software/gettext/manual/html_node/xgettext-Invocation.html) that
parses Elm source files to get the translatable strings and generate a PO template file. This PO template file can then
be used by tools like [POEdit](https://poedit.net/) to create the PO files for each language to translate your
application into.
It also includes a tool similar to
[GNU msgfmt](https://www.gnu.org/software/gettext/manual/html_node/msgfmt-Invocation.html) that converts PO files into
MO files.

This tool only works for translations specified by the panthus/elm-gettext library.

## Usage
Install with:
```
npm i --save-dev elm-xgettext
```

Create a POT file like this:
```
npx elm-xgettext src/**/*.elm -o locale/FE.pot
```

Convert PO files to a MO files like this:
```
npx elm-xgettext locale/**/*.po
```