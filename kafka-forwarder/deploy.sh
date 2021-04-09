PROJECT=${PROJECT:-kafka-forwarder}
LOG_LEVEL=${LOG_LEVEL:-info}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

printf "\n\n######## $PROJECT/deploy ########\n"

oc project ${PROJECT} 2> /dev/null || oc new-project ${PROJECT}

oc process -f "${DIR}/common.yml" \
-p LOG_LEVEL="${LOG_LEVEL}" \
-p NODE_ENV="${NODE_ENV}" \
-p KAFKA_SVC_USERNAME="${KAFKA_SVC_USERNAME}" \
-p KAFKA_SVC_PASSWORD="${KAFKA_SVC_PASSWORD}" \
-p KAFKA_BOOTSTRAP_URL="${KAFKA_BOOTSTRAP_URL}" \
-p CLUSTER_NAME="${CLUSTER_NAME}" | oc create -f -

oc process -f "${DIR}/triggers.yaml" \
-p PROJECT="${PROJECT}" | oc create -n battleships-backend -f -

kn service create event-forwarder \
--image "quay.io/redhatdemo/2021-kafka-event-forwarder-nodejs" \
--env-from secret:kafka-forwarder-secret \
--env-from cm:kafka-forwarder-config \
-l app.openshift.io/runtime=nodejs
