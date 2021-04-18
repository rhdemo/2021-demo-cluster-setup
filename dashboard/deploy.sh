#!/usr/bin/env bash

printf "\n\n######## dashboard/deploy ########\n"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT=${PROJECT:-battleships-dashboard}

oc project ${PROJECT} 2> /dev/null || oc new-project ${PROJECT}

# Apply knative triggers in backend to forward score updates to the game server
oc process -f "${DIR}/template.yml" \
-p NAMESPACE="${PROJECT}" \ 
-p REPLAY_SERVER="${DASHBOARD_REPLAY_SERVER}" \
-p GAME_SERVER="${DASHBOARD_GAME_SERVER}" | oc create -n $PROJECT -f -