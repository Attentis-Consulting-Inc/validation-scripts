#!/bin/sh

[ -n "$FILES_TO_VALIDATE" ] || return 0

env printf "\e[1;34m-----\n\u279C Running PMD\n-----\e[0m\n"

if [ "$VALIDATION_MODE" = "all" ]; then
    apex_files=$(find . -type f -name "*.cls" -or -name "*.trigger")
elif [ "$VALIDATION_MODE" = "package" ]; then
    apex_files=$(echo "$PACKAGE_NAMES" | sed 's| |\n|g' | xargs -I {} find {} -type f -name "*.cls" -or -name "*.trigger")
else
    apex_files=$(echo "$FILES_TO_VALIDATE" | grep --extended-regexp ".*\.(cls|trigger)$" -)
fi

[ -n "$apex_files" ] || { env printf "\e[1;32m\u2713\e[0m No files for PMD to check\n" && return 0; }

pmd_success=true

temp_pmd_file=/tmp/pmd_files_to_check
trap "rm -f $temp_pmd_file" EXIT

echo "$apex_files" >"$temp_pmd_file"
if [ -z "$(command -v pmd)" ]; then
    bash pmd/bin/pmd check --rulesets pmd/rulesets/apex.xml --format textcolor --no-cache --no-progress --file-list "$temp_pmd_file" || pmd_success=false
else
    pmd --rulesets pmd/rulesets/apex.xml --format textcolor --no-cache --no-progress --file-list "$temp_pmd_file" || pmd_success=false
fi

if [ $pmd_success = true ]; then
    env printf "\e[1;32m\u2713\e[0m PMD found no violations\n"
    return 0
else
    return 1
fi
