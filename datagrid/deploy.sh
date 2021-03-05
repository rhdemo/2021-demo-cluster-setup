#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

. ./datagrid/common.sh

createProjectAndDeploy

waitForDeployment

executeBatchFile "batch"
