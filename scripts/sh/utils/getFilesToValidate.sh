#!/bin/sh

FILES_TO_VALIDATE=
case "$VALIDATION_MODE" in
    "merge")
        FILES_TO_VALIDATE=$(git diff --name-only --diff-filter=AM HEAD^1..HEAD | sed 's| |\\ |g')
        ;;
    "commit")
        FILES_TO_VALIDATE=$(git diff --cached --name-only --diff-filter=AM | sed 's| |\\ |g')
        ;;
    "all")
        FILES_TO_VALIDATE="force-app"
        ;;
    *)
        echo "\$VALIDATION_MODE must be one of merge|commit|all" >&2 && exit 1
        ;;
esac

[ -n "$FILES_TO_VALIDATE" ] || env printf "\e[1;33m\uff01\e[0m No files to check\n"

export FILES_TO_VALIDATE
