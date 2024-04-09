#!/bin/bash
# Omnistudio components need to be separated from core components 
# to work around this issue: https://issues.salesforce.com/issue/a028c00000iwcS5/
mkdir -p omnistudio/main/default
mv force-app/main/default/omni* omnistudio/main/default/

sf project generate manifest --source-dir force-app
sf project deploy validate --manifest package.xml --wait 180 --test-level RunLocalTests --target-org target --pre-destructive-changes manifest/preDestructiveChanges.xml --post-destructive-changes manifest/postDestructiveChanges.xml --verbose || exit 1
