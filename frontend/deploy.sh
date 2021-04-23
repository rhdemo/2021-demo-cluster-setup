#!/usr/bin/env bash

printf "\n\n######## frontend/deploy ########\n"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT=${PROJECT:-frontend}
CLUSTER_NAME=${CLUSTER_NAME:-Default}
ROLLOUT_STRATEGY=${ROLLOUT_STRATEGY:-Rolling}

# Log level for Node.js service must be converted to lowercase
LOG_LEVEL=$(echo "${LOG_LEVEL:-info}" | tr "[:upper:]" "[:lower:]")

GAME_BACKEND_NAME=game-server
GAME_FRONTEND_NAME=game

oc project ${PROJECT} 2> /dev/null || oc new-project ${PROJECT}

# Creates secret and config map containing reused variables/params
oc process -f "${DIR}/common.yml" \
-p NODE_ENV="${NODE_ENV}" \
-p LOG_LEVEL="${LOG_LEVEL}" \
-p ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
-p KAFKA_BOOTSTRAP_URL="${KAFKA_BOOTSTRAP_URL}" \
-p KAFKA_SVC_PASSWORD="${KAFKA_SVC_PASSWORD}" \
-p KAFKA_SVC_USERNAME="${KAFKA_SVC_USERNAME}" \
-p CLUSTER_NAME="${CLUSTER_NAME}" | oc create -f -

# Deploys the admin interface used to play/pause/stop the game
oc process -f "${DIR}/admin.yml" | oc create -f -

# Deploys the game websocket server
oc process -f "${DIR}/game-server.yml" \
-p NAMESPACE="${PROJECT}" \
-p APPLICATION_NAME="${GAME_BACKEND_NAME}" \
-p AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
-p AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
-p ROLLOUT_STRATEGY="${ROLLOUT_STRATEGY}" | oc create -f -

# Deploys the NGINX UI serving bits
oc process -f "${DIR}/game-ui.yml" \
-p APPLICATION_NAME="${GAME_FRONTEND_NAME}" \
-p ROLLOUT_STRATEGY="${ROLLOUT_STRATEGY}" | oc create -f -

# Apply knative triggers in backend to forward score updates to the game server
oc process -f "${DIR}/knative.triggers.yml" \
-p NAMESPACE="${PROJECT}" \
-p APPLICATION_NAME="${GAME_BACKEND_NAME}" | oc create -n battleships-backend -f -
