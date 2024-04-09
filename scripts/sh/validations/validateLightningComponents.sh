#!/bin/sh

[ -n "$FILES_TO_VALIDATE" ] || return 0

env printf "\e[1;34m-----\n\u279C Running ESLint\n-----\e[0m\n"

if [ "$FILES_TO_VALIDATE" = "force-app" ]; then
    lightning_files=$(find "$SFDX_ROOT"/force-app -type f -path "$SFDX_ROOT/force-app/*/lwc/*/*.js" -or -path "$SFDX_ROOT/force-app/*/aura/*/*.js")
else
    lightning_files=$(echo "$FILES_TO_VALIDATE" | grep --extended-regexp ".*/(lwc|aura)/.*.js$" -)
fi

[ -n "$lightning_files" ] || { env printf "\e[1;32m\u2713\e[0m No files for ESLint to check\n" && return 0; }

eslint_success=true
# Validate ES Lint
echo "$lightning_files" | xargs npx eslint -- || eslint_success=false

[ $eslint_success = false ] && [ "$VALIDATION_MODE" = "merge" ] && return 1
# # Run jest tests
# npm run test:unit:coverage || exit 1
