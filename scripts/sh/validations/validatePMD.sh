#!/bin/sh

[ -n "$FILES_TO_VALIDATE" ] || return 0

env printf "\e[1;34m-----\n\u279C Running PMD\n-----\e[0m\n"

if [ "$VALIDATION_MODE" = "all" ]; then
    apex_files=$(find "$SFDX_ROOT" -type f -name "*.cls" -or -name "*.trigger")
elif [ "$VALIDATION_MODE" = "package" ]; then
    apex_files=$(find "$SFDX_ROOT"/"$FILES_TO_VALIDATE" -type f -name "*.cls" -or -name "*.trigger")
else
    apex_files=$(echo "$FILES_TO_VALIDATE" | grep --extended-regexp ".*\.(cls|trigger)$" -)
fi

[ -n "$apex_files" ] || { env printf "\e[1;32m\u2713\e[0m No files for PMD to check\n" && return 0; }

pmd_success=true

mkfifo pmd_files.fifo
echo "$apex_files" >pmd_files.fifo &
bash "$SFDX_ROOT"/pmd/bin/pmd check --rulesets "$SFDX_ROOT"/pmd/rulesets/apex.xml --format textcolor --no-cache --no-progress --file-list pmd_files.fifo || pmd_success=false

rm pmd_files.fifo
if [ $pmd_success = true ]; then
    env printf "\e[1;32m\u2713\e[0m PMD found no violations"
    return 0
else
    return 1
fi
