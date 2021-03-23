#!/usr/bin/env bash

printf "\n\n######## frontend/deploy ########\n"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT=${PROJECT:-frontend}
CLUSTER_NAME=${CLUSTER_NAME:-EDGE}
ROLLOUT_STRATEGY=${ROLLOUT_STRATEGY:-Rolling}

oc project ${PROJECT} 2> /dev/null || oc new-project ${PROJECT}

oc process -f "${DIR}/common.yml" -p NODE_ENV="${NODE_ENV}" -p CLUSTER_NAME="${CLUSTER_NAME}" | oc create -f -
oc process -f "${DIR}/admin.yml" -p ADMIN_PASSWORD="${ADMIN_PASSWORD}" | oc create -f -
oc process -f "${DIR}/game-server.yml" -p AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -p AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -p ROLLOUT_STRATEGY="${ROLLOUT_STRATEGY}" | oc create -f -
oc process -f "${DIR}/game-ui.yml" -p ROLLOUT_STRATEGY="${ROLLOUT_STRATEGY}" | oc create -f -
oc process -f "${DIR}/game-routes.yml"  | oc create -f -
oc apply -f ${DIR}/knative.trigger.yml