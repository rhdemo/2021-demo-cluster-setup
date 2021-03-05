#!/bin/bash
. common.sh

createProjectAndDeploy

oc create -f service-external.yaml

waitForDeployment

executeBatchFile "batch"
