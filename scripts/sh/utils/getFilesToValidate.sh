#!/bin/sh

FILES_TO_VALIDATE=
case "$VALIDATION_MODE" in
    "all")
        FILES_TO_VALIDATE=$(echo "$PROJECT_PACKAGES" | sed 's| |\\ |g')
        ;;
    "package")
        FILES_TO_VALIDATE="$PACKAGE_NAME"
        ;;
    "staged")
        FILES_TO_VALIDATE=$(git diff --cached --name-only --diff-filter=AM | sed 's| |\\ |g')
        ;;
    "commit")
        FILES_TO_VALIDATE=$(git diff --name-only --diff-filter=AM "$COMMIT"^1.."$COMMIT" | sed 's| |\\ |g')
        ;;
    "diff")
        FILES_TO_VALIDATE=$(git diff --name-only --diff-filter=AM "$HASH1".."$HASH2" | sed 's| |\\ |g')
        ;;
    *)
        echo "\$VALIDATION_MODE must be one of merge|commit|all" >&2 && exit 1
        ;;
esac

[ -n "$FILES_TO_VALIDATE" ] || env printf "\e[1;33m\uff01\e[0m No files to check\n"

export FILES_TO_VALIDATE
