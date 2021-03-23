#!/usr/bin/env bash

printf "\n\n######## backend/deploy ########\n"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT=${PROJECT:-battleships-backend}
CLUSTER_NAME=${CLUSTER_NAME:-EDGE}
ROLLOUT_STRATEGY=${ROLLOUT_STRATEGY:-Rolling}

oc project ${PROJECT} 2> /dev/null || oc new-project ${PROJECT}

