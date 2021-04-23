#!/usr/bin/env bash

printf "\n\n######## frontend/undeploy ########\n"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT=${PROJECT:-frontend}

oc project ${PROJECT}
oc process -p CLUSTER_NAME="${CLUSTER_NAME}" -p ADMIN_PASSWORD="nope" -p LOG_LEVEL='info' -f "${DIR}/common.yml" | oc delete -f -
oc process -f "${DIR}/admin.yml" | oc delete -f -
oc process -f "${DIR}/game-server.yml" -p APPLICATION_NAME='game-server' -p NAMESPACE="${PROJECT}" | oc delete -f -
oc process -f "${DIR}/game-ui.yml" -p APPLICATION_NAME='game' | oc delete -f -
oc process -f ${DIR}/knative.triggers.yml -p NAMESPACE="${PROJECT}" -p APPLICATION_NAME="game-server" | oc delete -f -