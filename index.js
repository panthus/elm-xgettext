#!/usr/bin/env node

const { Elm } = require('./dist/xgettext.js');
const fs = require('node:fs/promises');

const app = Elm.XGetText.init();

const action = process.argv.slice(2).reduce(
    (result, curr) => {
        if ((curr == "-h" || curr == "--help"))
            return Object.assign(result, { help: true });
        else if ((curr == "-o" || curr == "--output") && result.output === undefined)
            return Object.assign(result, { output: null });
        else if (result.output === null && !curr.startsWith("-"))
            return Object.assign(result, { output: curr });
        else if (result.input === undefined && !curr.startsWith("-"))
            return Object.assign(result, { input: curr });
        else
            return { error: "Unknown argument, see --help for the allowed arguments."};
    },
    {});

if (action.help || action.length === 0) {
    console.log("Usage:\n\
\telm-xgettext [FILE] [OPTIONS]\n\
\n\
Parses the translations from the given Elm files and outputs a POT file.\n\
The translations must be defined using the panthus/elm-gettext Elm library.\n\
\n\
FILE The glob pattern for the input Elm files, for example \"src/**/*.elm\".\n\
\n\
Arguments:\n\
    -h, --help\t\tDisplay this help text.\n\
    -o, --output\tSpecify the name of the resulting POT file.")
} else if (action.input && action.output) {
    parse(action.input, action.output);
} else if (action.error) {
    console.error(action.error);
    process.exit(1);
} else {
    console.error("Invalid arguments, both an input and output path need to be specified, see --help for details.");
    process.exit(1);
}

async function parse(input, output) {
    app.ports.logError.subscribe(function(error) {
        console.error(error);
        process.exit(1);
    });


    app.ports.savePotFile.subscribe(async function(potFile) {
        if (potFile) {
            try {
                await fs.writeFile(output, potFile);
            } catch (err) {
                console.error("Could not save the POT file: " + err);
                process.exit(1);
            }
        } else {
            console.log("No translations found.");
        }
    });

    for await (const entry of fs.glob(input)) {
        const file = await fs.readFile(entry, { encoding: "utf8" });
        app.ports.parseFile.send(file);
    }
    app.ports.generatePotFile.send(null);
}