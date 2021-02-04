#!/usr/bin/env bash

printf "\n\n######## frontend/undeploy ########\n"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT=${PROJECT:-frontend}

oc project ${PROJECT}
oc process -f "${DIR}/common.yml" | oc delete -f -
oc process -f "${DIR}/admin.yml"  | oc delete -f -
oc process -f "${DIR}/game-server.yml" | oc delete -f -
oc process -f "${DIR}/game-ui.yml" | oc delete -f -
oc process -f "${DIR}/game-routes.yml" | oc delete -f -
