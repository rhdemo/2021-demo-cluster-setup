PROJECT=${PROJECT:-kafka-streams}
QUARKUS_LOG_LEVEL=${QUARKUS_LOG_LEVEL:-INFO}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

printf "\n\n######## $PROJECT/deploy ########\n"

oc project ${PROJECT} 2> /dev/null || oc new-project ${PROJECT}

oc create secret generic truststore --from-file $DIR/truststore.jks

oc process -f "${DIR}/common.yml" \
-p LOG_LEVEL="${QUARKUS_LOG_LEVEL}" \
-p TRUSTSTORE_LOCATION="${TRUSTSTORE_LOCATION}" \
-p TRUSTSTORE_PASSWORD="${TRUSTSTORE_PASSWORD}" \
-p KAFKA_SVC_USERNAME="${KAFKA_SVC_USERNAME}" \
-p KAFKA_SVC_PASSWORD="${KAFKA_SVC_PASSWORD}" \
-p KAFKA_BOOTSTRAP_URL="${KAFKA_BOOTSTRAP_URL}" | oc create -f -

oc apply \
-f $DIR/matches-aggregator.is.yml \
-f $DIR/matches-aggregator.svc.yml \
-f $DIR/matches-aggregator.deployment.yml \
-f $DIR/matches-aggregator.route.yml

oc apply \
-f $DIR/player-aggregator.is.yml \
-f $DIR/player-aggregator.svc.yml \
-f $DIR/player-aggregator.deployment.yml \
-f $DIR/player-aggregator.route.yml
