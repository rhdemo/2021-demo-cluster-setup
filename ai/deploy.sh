printf "\n\n######## ai/deploy ########\n"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT=${PROJECT:-ai}
CLUSTER_NAME=${CLUSTER_NAME:-EDGE}
ROLLOUT_STRATEGY=${ROLLOUT_STRATEGY:-Rolling}

oc project ${PROJECT} 2> /dev/null || oc new-project ${PROJECT}

oc process -f "${DIR}/common.yml" -p NODE_ENV="${NODE_ENV}" -p CLUSTER_NAME="${CLUSTER_NAME}" | oc create -f -
oc process -f "${DIR}/ai-model.yml" | oc create -f -
oc process -f "${DIR}/ai-agent-server.yml" -p NAMESPACE="${PROJECT}" | oc create -f -
