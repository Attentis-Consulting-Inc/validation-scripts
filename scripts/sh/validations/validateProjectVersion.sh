#!/bin/sh

[ -n "$FILES_TO_VALIDATE" ] || return 0

env printf "\e[1;34m-----\n\u279C Checking project version\n-----\e[0m\n"

sfdx_version="$(grep '"sourceApiVersion": "\K.*(?=")' "$SFDX_ROOT"/sfdx-project.json -Po)"
env printf "\e[1;33m\u2731\e[0m Project version is v%s\n" "$sfdx_version"

violations=0

while read -r line; do
    [ -n "$line" ] || continue

    filename="$(echo "$line" | cut -d ">" -f 1 | cut -d ":" -f 1)"
    file_api_version="$(echo "$line" | cut -d ">" -f 2)"
    if [ "$file_api_version" != "$sfdx_version" ]; then
        env printf "\e[1;31m\xE2\x9D\x8C\e[0m %s (v%s) doesn't match project version\n" "$filename" "$file_api_version" >&2
        violations=$((violations + 1))
    fi
done <<EOF
$(echo "$FILES_TO_VALIDATE" | xargs grep --perl "<(apiV|v)ersion\K.*(?=</(apiV|v)ersion>)" --with-filename --only-matching --recursive --include="*.xml" --)
EOF

if [ $violations -eq 0 ]; then
    env printf "\e[1;32m\u2713\e[0m All files match project version\n"
else
    env printf "\n\e[1;31m\xE2\x9D\x8C %s total project verion problems\e[0m\n" "$violations" >&2
    return 1
fi
