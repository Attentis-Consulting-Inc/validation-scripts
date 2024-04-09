#!/bin/sh

get_sfdx_root() {
    RESULT=$(find "$1" -maxdepth 1 -name "sfdx-project.json")
    if [ "$RESULT" ]; then
        SFDX_ROOT=$(realpath "$1")
        return 0
    elif [ "$(realpath "$1")" = "$HOME" ] || [ "$(realpath "$1")" = "/" ]; then
        env printf "\e[1;33m\u25B2\e[0m Not in an SFDX project\n"
        return 1
    else
        get_sfdx_root ../"$1"
    fi
}

get_sfdx_root .
[ -n "$SFDX_ROOT" ] || exit 1

export SFDX_ROOT
SCRIPTS_DIR="$SFDX_ROOT"/scripts/sh

export VALIDATION_MODE="all"
. "$SCRIPTS_DIR"/utils/getFilesToValidate.sh

. "$SCRIPTS_DIR"/validations/validateProjectVersion.sh
. "$SCRIPTS_DIR"/validations/validateFormatting.sh
. "$SCRIPTS_DIR"/validations/validatePMD.sh
. "$SCRIPTS_DIR"/validations/validateLightningComponents.sh
