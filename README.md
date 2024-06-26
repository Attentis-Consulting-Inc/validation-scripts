# SFDX project validation scripts

Shell scripts with a single entry point for performing a series of code quality
validations on an SFDX project. These validations are:

- [Prettier](https://prettier.io/) code formatting, according to the project's
  local `prettierrc` and `prettierignore` files
- No trailing whitespace
- Space-based indentation only
- [PMD](https://pmd.github.io/) static code analysis on all apex files
- [ESLint](https://eslint.org/) static code analysis on all javascript files for
  Aura and LWC components
- Run all [Jest](https://jestjs.io/) tests for LWC components

## Prerequisites

The `validate` script has a few prerequisites you should check to make sure it
runs properly:

1. It must be run from within a UNIX shell. If in Windows, this can be `git
bash`, usually included when installing `git` in Windows, and easily
    accessible from VSCode. If in Linux or Mac, this is your regular shell.
2. [Prettier](https://prettier.io/) and [the Apex
    plugin](https://www.npmjs.com/package/prettier-plugin-apex), both can be
    installed using:

        npm install -D prettier prettier-plugin-apex

3. [Jest](https://jestjs.io/) and the
    [sfdx-lwc-jest](https://github.com/salesforce/sfdx-lwc-jest) wrapper. This
    can be set up using:

        sf force lightning lwc test setup

    or, if using the deprecated `sfdx` cli tool:

        sfdx force:lightning:lwc:test:setup

4. [jq](https://github.com/jqlang/jq), required to parse through the
    `sfdx-project.json` project definition. You can check if `jq` is available on
    your shell using

        command -v jq

    If no output is provided, you can install `jq` following the steps provided
    [here](https://jqlang.github.io/jq/download/), but the most common ways are:

    - Windows: Run `git bash` **as Administrator** and run

          curl -L -o /usr/bin/jq.exe https://github.com/stedolan/jq/releases/latest/download/jq-win64.exe

    - Mac:

            brew install jq

    - Linux: Install using your distribution's package manager, examples:

      - Debian based:

              sudo apt-get install jq

      - RHEL based:

              sudo dnf install jq

5. [PMD](https://pmd.github.io/) must be placed as a binary in the project
    directory under the name `./pmd`, along with a valid apex ruleset. To do this:

    1. Download PMD using

             curl -LO https://github.com/pmd/pmd/releases/download/pmd_releases%2F7.0.0/pmd-dist-7.0.0-bin.zip

    2. Unzip it:

             unzip pmd-dist-7.0.0-bin.zip

    3. Rename the extracted directory:

             mv pmd-bin-7.0.0 pmd

    4. Create a `rulesets` subdirectory:

             mkdir pmd/rulesets

    5. Download the Attentis Apex ruleset into this subdirectory:

         ```
         curl -L https://raw.githubusercontent.com/Attentis-Consulting-Inc/pmd/main/ruleset.xml -o pmd/rulesets/apex.xml
         ```

### Ignoring Omnistudio LWCs from Jest coverage

Since Omnistudio auto-generated LWCs do not contain Jest tests, these may
negatively affect Jest test results, especially when using the `coverageThreshold`
property in the Jest configuration. Ignoring these in the scripts themselves may
result in the commands to fail if too many of these paths must be concatenated.

As an alternative, these can be safely ignored directly in the `jest.config.js`
file, as follows:

1. Create an `omnistudio-components.json` file in the project root. This file
   also serves to indicate the validation scripts to ignore the auto-generated
components in other validations. This file should be a JSON encoded string,
where the top-level keys are the SFDX project's packages, each mapping to an
array of names of auto-generated LWCs that can be found inside that package.
For example, if the project consists of 2 packages named `base-app` (containing
the auto-generated component `cfFlexcard`) and
`additional-app` (containing the components `cfOtherFlexcard` and
`omniscriptEnglish`), then the file should look like:

        {
            "base-app": [ "cfFlexcard" ],
            "additional-app": [
                "cfOtherFlexcard",
                "omniscriptEnglish"
            ]
        }

2. Add the following snippet into your `jest.config.js` file, right after the
   imports:

        
        let omnistudioComponents;
        try {
          omnistudioComponents = require('./omnistudio-components.json');
        } catch {
          omnistudioComponents = {};
        }

        const ignorePaths = [];
        Object.entries(omnistudioComponents).forEach(([app, components]) => {
          const rootPath = `<rootDir>/${app}/main/default/lwc/`;
          components.forEach((component) => {
            ignorePaths.push(`${rootPath}${component}/`);
          })
        });

3. In the same file's `module.exports`, add the following key and value pair:

        coveragePathIgnorePatterns: [...ignorePaths]

    If your file already contains the key and is ignoring some paths, simply add
    to those.

## Usage

Get the latest release zip file from [here](https://github.com/Attentis-Consulting-Inc/validation-scripts/releases/download/latest/validation_scripts.zip) and unzip it into an
sfdx project. The zip file contains the following file structure:

    .
    ├── validate
    ├── .utils
    │   ├── getOmnistudio
    │   ├── getPackages
    │   └── getVersion
    └── .validations
        ├── eslint
        ├── jest
        ├── pmd
        ├── prettier
        ├── version
        └── whitespace

From within a UNIX shell, run the following command from the root of the
project:

    sh path/to/validate <option>

where `<option>` determines the set of files on which validations will be run.
A complete list of options and what each does can be seen in the scripts's help:

    sh path/to/validate --help

    Usage: validate <option>
    Run validations on an sfdx project for: Formatting, Prettier, PMD, ESLint, and run Jest tests
    Options are mutually exclusive and only one may be provided

    Options:
       -a, --all (default)                        run validations for the entire project
       -p, --package <name> [<name>...]           run validations on one or more packages by <name>
       -s, --staged                               run validations on staged files
       -c, --commit [<hash>]                      run validations on <hash> commit against parent (default: HEAD)
       -d, --diff <hash 1> [<hash 2>]             run validations on the diff between <hash 1> and <hash 2> (default: HEAD)

       -h, --help                                 display this help

**Note:** Validations are always run against the working tree version of each
file, and options such as `staged`, `commit`, and `diff` only determine which
files validations are run for.
