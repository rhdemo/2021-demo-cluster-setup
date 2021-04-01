#!/usr/bin/env bash

printf "\n\n######## ai/undeploy ########\n"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT=${PROJECT:-ai}

oc project ${PROJECT}
oc process -f "${DIR}/ai-model.yml" | oc delete -f -
oc process -f "${DIR}/ai-agent-server.yml" | oc delete -f -
oc process -f "${DIR}/common.yml"  | oc delete -f -
oc delete project ai