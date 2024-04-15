#!/bin/sh

VALIDATION_MODE=
parsed_hash=

display_help() {
    echo "Usage: $(basename "$0") [option] " >&2
    echo "Run validations on an sfdx project for: Formatting, Prettier, PMD, ESLint, and run Jest tests"
    echo "Options are mutually exclusive and only one may be provided"
    echo
    echo "Options:"
    echo "   -a, --all (default)                run validations for the entire project"
    echo "   -p, --package <name>               run validations on <name> package."
    echo "   -s, --staged                       run validations on staged files"
    echo "   -c, --commit [<hash>]              run validations on <hash> commit against parent (default: HEAD)"
    echo "   -d, --diff <hash 1> [<hash 2>]     run validations on the diff between <hash 1> and <hash 2> (default: HEAD)"
    echo
    echo "   -h, --help                         display this help"
    exit 1
}

get_sfdx_root() {
    RESULT=$(find "$1" -maxdepth 1 -name "sfdx-project.json")
    if [ "$RESULT" ]; then
        SFDX_ROOT=$(realpath "$1") && export SFDX_ROOT && return 0
    elif [ "$(realpath "$1")" = "$HOME" ] || [ "$(realpath "$1")" = "/" ]; then
        echo "Not in an SFDX project" >&2 && exit 1
    else
        get_sfdx_root ../"$1"
    fi
}

validate_package() {
    matching_packages=$(echo "$PROJECT_PACKAGES" | grep "$PACKAGE_NAME" --line-regexp --count --directories=read)
    [ "$matching_packages" -gt 0 ] || { echo "$PACKAGE_NAME is not a valid package name" >&2 && exit 1; }
}

check_if_in_git() {
    GIT_ROOT=$(git rev-parse --show-toplevel 2>&1)
    [ -d "$GIT_ROOT" ] || { echo "Not in a git repository" >&2 && exit 1; }
}

validate_commit() {
    parsed_hash=$(git rev-parse --short "$1" 2>/dev/null) || return 1
}

validate_diff() {
    (git merge-base --is-ancestor "$1" "$2" 2>/dev/null) || return 1
}

validate_exclusive_options() {
    [ -z $VALIDATION_MODE ] || { echo "Only one option may be provided" >&2 && echo && display_help; }
}

args() {
    options=$(getopt -o apscdh --long 'all,package,staged,commit,diff,help' -- "$@") || exit 1
    eval set -- "$options"
    while true; do
        case "$1" in
            -a | --all)
                validate_exclusive_options
                VALIDATION_MODE="all"
                shift
                ;;
            -p | --package)
                validate_exclusive_options
                VALIDATION_MODE="package"
                shift
                ;;
            -s | --staged)
                validate_exclusive_options
                check_if_in_git
                VALIDATION_MODE="staged"
                shift
                ;;
            -c | --commit)
                validate_exclusive_options
                VALIDATION_MODE="commit"
                check_if_in_git
                shift
                ;;
            -d | --diff)
                validate_exclusive_options
                VALIDATION_MODE="diff"
                check_if_in_git
                shift
                ;;
            -h | --help)
                validate_exclusive_options
                display_help
                ;;
            --)
                shift && break
                ;;
        esac
    done

    shift

    [ -n "$VALIDATION_MODE" ] || VALIDATION_MODE="all"

    case "$VALIDATION_MODE" in
        "package")
            [ -n "$1" ] || { echo "--package requires a name to be provided" >&2 && exit 1; }
            PACKAGE_NAME=$1
            validate_package
            ;;
        "commit")
            if [ -n "$1" ]; then
                hash=$1
            else
                hash="HEAD"
            fi
            validate_commit "$hash" || { echo "$hash is not a valid commit hash" >&2 && exit 1; }
            COMMIT="$parsed_hash"
            if [ ! "$(git rev-parse --short "$COMMIT^1" 2>/dev/null)" ]; then
                echo "$COMMIT does not have a parent to validate against" >&2
                exit 1
            fi
            ;;
        "diff")
            [ -n "$1" ] || { echo "--diff requires at least one commit hash" >&2 && exit 1; }
            hash="$1"
            if [ -n "$2" ]; then
                hash_2=$2
            else
                hash_2=$(git rev-parse --short HEAD)
            fi
            validate_commit "$hash" || { echo "$hash is not a valid commit hash" >&2 && exit 1; }
            HASH1="$parsed_hash"
            validate_commit "$hash_2" || { echo "$hash_2 is not a valid commit hash" >&2 && exit 1; }
            HASH2="$parsed_hash"
            validate_diff "$HASH1" "$HASH2"
            ;;

    esac
}

get_sfdx_root .
SCRIPTS_DIR="$SFDX_ROOT"/scripts/sh
. "$SCRIPTS_DIR"/utils/getProjectPackages.sh

args "$0" "$@"

export VALIDATION_MODE
export COMMIT
export PACKAGE_NAME
export HASH1
export HASH2

. "$SCRIPTS_DIR"/utils/getFilesToValidate.sh

. "$SCRIPTS_DIR"/validations/validateProjectVersion.sh
. "$SCRIPTS_DIR"/validations/validateFormatting.sh
. "$SCRIPTS_DIR"/validations/validatePMD.sh
. "$SCRIPTS_DIR"/validations/validateLightningComponents.sh
