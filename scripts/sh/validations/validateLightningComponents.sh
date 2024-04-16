#!/bin/sh

[ -n "$FILES_TO_VALIDATE" ] || return 0

echo "$FILES_TO_VALIDATE"
env printf "\e[1;34m-----\n\u279C Running ESLint\n-----\e[0m\n"

if [ "$VALIDATION_MODE" = "all" ]; then
    lightning_files=$(find . -type f -path "*/lwc/*/*.js" -or -path "*/aura/*/*.js")
elif [ "$VALIDATION_MODE" = "package" ]; then
    lightning_files=$(find "$PACKAGE_NAME" -type f -path "$PACKAGE_NAME/*/lwc/*/*.js" -or -path "$PACKAGE_NAME/*/aura/*/*.js")
else
    lightning_files=$(echo "$FILES_TO_VALIDATE" | grep --extended-regexp ".*/(lwc|aura)/.*.js$" -)
fi

[ -n "$lightning_files" ] || { env printf "\e[1;32m\u2713\e[0m No files for ESLint to check\n" && return 0; }

eslint_success=true
# Validate ES Lint
echo "$lightning_files" | xargs npx eslint -- || eslint_success=false

[ $eslint_success = false ] && [ "$PIPELINE_MODE" ] && return 1

# Run jest tests
npm run test:unit:coverage || exit 1
