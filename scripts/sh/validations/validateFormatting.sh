#!/bin/sh

[ -n "$FILES_TO_VALIDATE" ] || return 0

env printf "\e[1;34m-----\n\u279C Checking whitespace\n-----\e[0m\n"

# Validate whitespace and indentation: This is done for the entire project

# Validate no lines with trailing whitespace
violations=0
while read -r line; do
    [ -n "$line" ] || continue

    filename=$(echo "$line" | cut -d ":" -f 1)
    line_number=$(echo "$line" | cut -d ":" -f 2)
    env printf "\e[1;31m\u274C\e[0m Trailing whitespace in %s (line %d)\n" "$filename" "$line_number" >&2
    violations=$((violations + 1))
done <<EOF1
$(echo "$FILES_TO_VALIDATE" | xargs grep --extended-regexp "[[:blank:]]+$" --with-filename --only-matching --line-number --recursive --binary-files=without-match --)
EOF1

# Validate indentation uses only spaces, no tabs or mixed
while read -r line; do
    [ -n "$line" ] || continue

    filename=$(echo "$line" | cut -d ":" -f 1)
    line_number=$(echo "$line" | cut -d ":" -f 2)
    env printf "\e[1;31m\u274C\e[0m Tab indentation found in %s (line %d)\n" "$filename" "$line_number" >&2
    violations=$((violations + 1))
done <<EOF2
$(echo "$FILES_TO_VALIDATE" | xargs grep --perl '^\s*\t+' --with-filename --only-matching --line-number --recursive --binary-files=without-match --)
EOF2

if [ $violations -eq 0 ]; then
    env printf "\e[1;32m\u2713\e[0m All files match project version\n"
else
    env printf "\n\e[1;31m\xE2\x9D\x8C %s total whitespace problems\e[0m\n" "$violations" >&2
    [ "$VALIDATION_MODE" = "merge" ] && return 1
fi

# Validate formatting with Prettier

env printf "\e[1;34m-----\n\u279C Running Prettier\n-----\e[0m\n"
# Build list of files to check with Prettier as a glob to go around spaces in paths
{ [ -n "$(npm ls -p prettier)" ] && [ -n "$(npm ls -p prettier-plugin-apex)" ]; } || npm install prettier prettier-plugin-apex
echo "$FILES_TO_VALIDATE" | xargs npx prettier --check --ignore-unknown || violations=$((violations + 1))
[ $violations -eq 0 ] || return 1
