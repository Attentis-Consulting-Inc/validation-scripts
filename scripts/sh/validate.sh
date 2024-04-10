#!/bin/sh

selected=0
VALIDATION_MODE=

display_help() {
    echo "Usage: $(basename "$0") <option> " >&2
    echo
    echo "Options:"
    echo "   -a, --all                  run validations for the entire project"
    echo "   -p, --package <name>       run validations on <name> package. If only one package, equivalent to --all"
    echo "   -s, --staged               run validations on staged files"
    echo "   -c, --commit               run validations on latest commit against parent"
    echo "   -d, --diff <hash>          run validations on <hash> commit against parent"
    echo
    echo "   -h, --help                 display this help"
    exit 1
}

check_if_in_git() {
    GIT_ROOT=$(git rev-parse --show-toplevel 2>&1)
    [ -d "$GIT_ROOT" ] || { echo "Not in a git repository" >&2 && exit 1; }
}

get_sfdx_root() {
    RESULT=$(find "$1" -maxdepth 1 -name "sfdx-project.json")
    if [ "$RESULT" ]; then
        SFDX_ROOT=$(realpath "$1")
        export SFDX_ROOT
        return 0
    elif [ "$(realpath "$1")" = "$HOME" ] || [ "$(realpath "$1")" = "/" ]; then
        echo "Not in an SFDX project" >&2 && exit 1
    else
        get_sfdx_root ../"$1"
    fi
}

validate_commit() {
    (git merge-base --is-ancestor "$COMMIT" HEAD 2>/dev/null) || {
        echo "$COMMIT is not a valid commit hash" >&2
        exit 1
    }
}

validate_package() {
    matching_packages=$(echo "$PROJECT_PACKAGES" | grep "$PACKAGE_NAME" --count --directories=read)
    [ "$matching_packages" -gt 0 ] || {
        echo "$PACKAGE_NAME is not a valid package name" >&2
        exit 1
    }
}

args() {
    options=$(getopt -o ap:scd:h --long 'all,package:,staged,commit,diff:,help' -- "$@" 2>&1)
    [ $? -eq 0 ] || {
        echo "Unrecognized option provided"
        exit 1
    }
    eval set -- "$options"
    while true; do
        case "$1" in
            -a | --all)
                selected=$((selected + 1))
                VALIDATION_MODE="all"
                shift
                continue
                ;;
            -p | --package)
                selected=$((selected + 1))
                VALIDATION_MODE="package"
                case "$2" in
                    -*)
                        echo "-p | --package requires a package name as argument" >&2
                        exit 1
                        ;;
                esac

                PACKAGE_NAME=$2
                validate_package
                shift 2
                continue
                ;;
            -s | --staged)
                selected=$((selected + 1))
                VALIDATION_MODE="staged"
                check_if_in_git
                shift
                continue
                ;;
            -c | --commit)
                selected=$((selected + 1))
                VALIDATION_MODE="commit"
                COMMIT="HEAD"
                check_if_in_git
                shift
                continue
                ;;
            -d | --diff)
                selected=$((selected + 1))
                VALIDATION_MODE="diff"
                case "$2" in
                    -*)
                        echo "-d | --diff requires a commit hash as argument" >&2
                        exit 1
                        ;;
                esac

                COMMIT=$2
                check_if_in_git
                validate_commit
                shift 2
                continue
                ;;
            -h | --help)
                display_help
                ;;
            --)
                shift
                break
                ;;
        esac
        shift
    done
}

get_sfdx_root .
SCRIPTS_DIR="$SFDX_ROOT"/scripts/sh
. "$SCRIPTS_DIR"/utils/getProjectPackages.sh

args "$0" "$@"

if [ $selected -eq 0 ]; then
    VALIDATION_MODE="all"
elif [ $selected -gt 1 ]; then
    echo "Only one of --all, --package, --staged, --commit, or --diff can be used" >&2 && exit 1
fi

exit 0

export VALIDATION_MODE
export COMMIT

. "$SCRIPTS_DIR"/utils/getFilesToValidate.sh

. "$SCRIPTS_DIR"/validations/validateProjectVersion.sh
. "$SCRIPTS_DIR"/validations/validateFormatting.sh
. "$SCRIPTS_DIR"/validations/validatePMD.sh
. "$SCRIPTS_DIR"/validations/validateLightningComponents.sh
