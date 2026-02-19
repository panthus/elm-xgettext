#!/usr/bin/env node

const { Elm } = require('./dist/xgettext.js');
const fs = require('node:fs/promises');
const path = require('node:path');
const { parseArgs } = require('node:util');
const packageJson = require('./package.json');

const app = Elm.Main.init();

const options = {
    help: { short: 'h', long: 'help', type: 'boolean' },
    output: { short: 'o', long: 'output', type: 'string' },
};

let values, positionals;
try {
    ({ values, positionals } = parseArgs({
        options,
        allowPositionals: true,
        strict: true,
    }));
} catch (err) {
    console.error(err.message);
    process.exit(1);
}

if (values.help || positionals.length === 0) {
    console.log(`Version: ${packageJson.version}

Usage:
\telm-xgettext [FILE] [OPTIONS]

Dependening on the input file type, this tool can be used in two ways:

1. To convert a PO file to a MO file:
   Parses the translations from the given PO file and outputs a MO file.

2. To extract translations from Elm files and outputs a POT file.
   The translations must be defined using the panthus/elm-gettext Elm library.

FILE The glob pattern for the input Elm/PO files, for example "src/**/*.elm".

Arguments:
    -h, --help\t\tDisplay this help text.
    -o, --output\tSpecify the name of the resulting POT file.
                \tNote for PO to MO the MO file is always put next to the PO file.`);
} else if (positionals.length > 0) {
    parse(positionals, values.output);
} else {
    console.error("Invalid arguments, see --help for details.");
    process.exit(1);
}

async function parse(inputs, output) {
    const extInput = path.extname(inputs[0]);

    for (const input of inputs) {
        if (path.extname(input) !== extInput) {
            console.error("Invalid arguments, all input files must have the same extension. See --help for details.");
            process.exit(1);
        }
    }

    app.ports.logError.subscribe(function(error) {
        console.error(error);
        process.exit(1);
    });

    app.ports.saveFile.subscribe(async function(data) {
        try {
            await fs.writeFile(data.outputPath, data.content, { encoding: data.encoding });
        } catch (err) {
            console.error(`Could not save file: ${output}. ${err}`);
            process.exit(1);
        }
    });

    if (extInput === ".po") {
        if (output) {
            console.error("Invalid arguments, output is not supported for PO input. See --help for details.");
            process.exit(1);
        }

        for (const input of inputs) {
            for await (const entry of fs.glob(input)) {
                const content = await fs.readFile(entry, { encoding: "utf8" });
                app.ports.parsePoFile.send({ content, outputPath: entry.replace(/\.po$/, ".mo") });
            }
        }
    } else if (extInput === ".elm") {
        if (!output) {
            console.error("Invalid arguments, specify the output POT file. See --help for details.");
            process.exit(1);
        }
        if (path.extname(output) !== ".pot") {
            console.error("Invalid arguments, the output must be a POT file. See --help for details.");
            process.exit(1);
        }

        for (const input of inputs) {
            for await (const entry of fs.glob(input)) {
                const content = await fs.readFile(entry, { encoding: "utf8" });
                app.ports.parseElmFile.send({ content });
            }
        }

        app.ports.generatePotFile.send({ outputPath: output });
    } else {
        console.error(
            `Unsupported file type: ${extInput}. Only .elm and .po files are supported. See --help for details.`);
        process.exit(1);
    }
}