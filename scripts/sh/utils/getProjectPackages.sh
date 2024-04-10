#!/bin/sh

{ [ -n "$SFDX_ROOT" ] && [ -d "$SFDX_ROOT" ] && [ -f "$SFDX_ROOT"/sfdx-project.json ]; } || {
    echo "SFDX_ROOT environment variable must point to an sfdx project root directory"
    exit 1
}

PROJECT_PACKAGES="$(jq .packageDirectories[].path "$SFDX_ROOT"/sfdx-project.json)"
export PROJECT_PACKAGES
