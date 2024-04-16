#!/bin/sh

PROJECT_PACKAGES="$(jq .packageDirectories[].path sfdx-project.json | sed 's/"//g')"
export PROJECT_PACKAGES
