#!/usr/bin/env bash


# Turn colors in this script off by setting the NO_COLOR variable in your
# environment to any value:
#
# $ NO_COLOR=1 test.sh

mk_environment() {
NO_COLOR=${NO_COLOR:-""}
if [ -z "$NO_COLOR" ]; then
  header=$'\e[1;33m'
  reset=$'\e[0m'
else
  header=''
  reset=''
fi

strimzi_version=`curl https://github.com/strimzi/strimzi-kafka-operator/releases/latest |  awk -F 'tag/' '{print $2}' | awk -F '"' '{print $1}' 2>/dev/null`
serving_version="v0.20.0"
kourier_version="v0.20.0"
eventing_version="v0.20.1"
eventing_kafka_version="v0.20.0"

# Default version for subscriptions
VERSION_OPENSHIFT_SERVERLESS="1.13.0"

# Channel to use for subscriptions
OLM_CHANNEL="4.6"

#streams versioning
VERSION_OPENSHIFT_STREAMS="1.6.2"
STREAMS_OLM_CHANNEL="stable"
STRIMZI_OLM_CHANNEL="stable"

}
function header_text {
  echo "$header$*$reset"
}

apply_openshift_strimzi_subscription() {
    release=${1:-${strimzi_version}}
    channel=${2:-${STRIMZI_OLM_CHANNEL}}
    header_text "* Subscribing to Strimzi                   ${release}"
    header_text "* Using Strimzi OLM Channel                ${channel}"

  subscription=$(cat <<EOT
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: strimzi-kafka-operator
  namespace: openshift-operators
spec:
  channel: "$channel"
  installPlanApproval: Automatic
  name: strimzi-kafka-operator
  source: community-operators
  sourceNamespace: openshift-marketplace
  startingCSV: strimzi-cluster-operator.v$release
EOT
  )
  apply "$subscription"

  header_text "* Waiting for Strimzi operator to come up"
  wait_for_operators "strimzi-cluster-operator-v$release"

  # Wait for the CRD we need to actually be active
  oc wait crd --timeout=-1s kafkas.kafka.strimzi.io --for=condition=Established

}

apply_openshift_amq_streams_subscription() {
    release=${1:-${VERSION_OPENSHIFT_STREAMS}}
    channel=${2:-${STREAMS_OLM_CHANNEL}}
    header_text "* Subscribing to Openshift AMQ Streams        ${release}"
    header_text "* Using AMQ Stream OLM Channel                ${channel}"

  subscription=$(cat <<EOT
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: amq-streams
  namespace: openshift-operators
spec:
  channel: "$channel"
  installPlanApproval: Automatic
  name: amq-streams
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: amqstreams.v$release
EOT
  )
  apply "$subscription"

  header_text "* Waiting for AMQ Streams operators to come up"
  wait_for_operators "amq-streams-cluster-operator-v1.6.2"
}

apply_streams() {
    header_text "*applying kafka 2.6"
    kafka=$(cat <<EOT
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
  namespace: kafka
spec:
  kafka:
    version: 2.6.0
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
      log.message.format.version: "2.6"
      inter.broker.protocol.version: "2.6"
    storage:
      type: ephemeral
  zookeeper:
    replicas: 3
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOT
)
    apply "$kafka"
}

apply_openshift_serverless_subscription() {
  release=${1:-${VERSION_OPENSHIFT_SERVERLESS}}
  channel=${2:-$OLM_CHANNEL}
  header_text "Using Serverless Version:                   ${release}"
  header_text "Using OLM Channel Version:                  ${channel}"

  subscription=$(cat <<EOT
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: serverless-operator
  namespace: openshift-operators
spec:
  channel: "$channel"
  installPlanApproval: Automatic
  name: serverless-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: serverless-operator.v$release
EOT
  )
  apply "$subscription"

  header_text "* Waiting for OpenShift Serverless operators to come up"
  wait_for_operators "knative-openshift" "knative-openshift-ingress" "knative-operator"
}

apply_serving() {
  header_text "* Applying Serving in knative-serving"
  apply_project knative-serving

  serving="$(cat <<EOT
apiVersion: operator.knative.dev/v1alpha1
kind: KnativeServing
metadata:
  name: knative-serving
  namespace: knative-serving
EOT
)"
  apply "$serving"
  wait_for_all_deployments knative-serving
}

apply_eventing() {
  header_text "* Applying Eventing in knative-eventing"
  apply_project knative-eventing

  eventing="$(cat <<EOT
apiVersion: operator.knative.dev/v1alpha1
kind: KnativeEventing
metadata:
  name: knative-eventing
  namespace: knative-eventing
EOT
  )"
  apply "$eventing"
  wait_for_all_deployments knative-eventing

}

apply_knativekafka() {
    bootstrapServers=${1:-"my-cluster-kafka-bootstrap.kafka:9092"}
    header_text "* Applying Kafka Source in knative-eventing"
    apply_project knative-eventing

    knativekafka=$(cat <<EOT
apiVersion: operator.serverless.openshift.io/v1alpha1
kind: KnativeKafka
metadata:
  name: knative-kafka
  namespace: knative-eventing
spec:
  channel:
    bootstrapServers: "$bootstrapServers"
    enabled: true
  source:
    enabled: false
EOT
                )
    apply "$knativekafka"
    wait_for_all_deployments knative-eventing
}

apply_project() {
  project=$1
  set +e
  oc get project $project >/dev/null 2>&1
  rc="$?"
  set -e
  if [ "$rc" -ne "0" ]; then
    header_text "* Creating namespace $project"
    oc new-project $project >/dev/null
  fi
}

apply() {
  out=$(echo "$1" | oc apply -f - 2>&1)
  header_text $out
}

wait_for_operators() {
  operators="$@"
  #run_with_timeout 60 wait_for_deployments_to_be_created $operators
  sleep 15
  wait_for_deployments_to_be_created $operators
  for operator in $operators; do
    out=$(oc wait deploy/$operator -n openshift-operators --for=condition=Available --timeout 60s >/dev/null)
    header_text "$out"
  done
}

wait_for_all_deployments() {
  ns=$1
  sleep 15
  out=$(oc wait deployment --all --timeout=-1s --for=condition=Available -n "$ns" 2>&1)
  header_text $out
}

# Check that resource exists before start waiting
wait_for_deployments_to_be_created() {
  while true; do
    set +e
    oc get -n openshift-operators deployment $@ >/dev/null 2>&1
    rc=$?
    set -e
    if [ $rc -eq 0 ]; then
      return
    fi
    sleep 2
  done
}

run_with_timeout () {
    local time=10
    if [[ $1 =~ ^[0-9]+$ ]]; then time=$1; shift; fi
    # Run in a subshell to avoid job control messages
    ( "$@" &
      child=$!
      # Avoid default notification in non-interactive shell for SIGTERM
      trap -- "" SIGTERM
      ( sleep $time
        kill $child 2> /dev/null ) &
      wait $child
    )
}

install_serverless() {
    mk_environment

    apply_openshift_strimzi_subscription
    apply_strimzi

    #apply_openshift_amq_streams_subscription
    #apply_streams

    apply_openshift_serverless_subscription
    apply_serving
    apply_eventing
    apply_knativekafka
    adjust_serverless_operator_defaults

    #kafka_default_channel
    #kafka_default_broker_channel

}

apply_strimzi() {

  kafka=$(cat <<EOT
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
  namespace: kafka
spec:
  kafka:
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
        authentication:
          type: tls
      - name: external
        port: 9094
        type: nodeport
        tls: false
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        size: 100Gi
        deleteClaim: false
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
  zookeeper:
    replicas: 3
    storage:
      type: persistent-claim
      size: 100Gi
      deleteClaim: false
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOT
)
  header_text "Strimzi install"
  apply_project kafka

  header_text "Applying Strimzi Cluster file"
  apply "$kafka"
  header_text "Waiting for Strimzi to become ready"
  oc wait kafka --all --timeout=-1s --for=condition=Ready -n kafka

}

kafka_default_channel() {
  default_channel="$(cat <<EOT
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-default-ch-webhook
  namespace: knative-eventing
data:
  # Configuration for defaulting channels that do not specify CRD implementations.
  default-ch-config: |
    clusterDefault:
      apiVersion: messaging.knative.dev/v1beta1
      kind: KafkaChannel
      spec:
        numPartitions: 100
        replicationFactor: 1
EOT
  )"
  apply "$default_channel"
}

adjust_serverless_operator_defaults() {
  adjust_knative_eventing="$(cat <<EOT
apiVersion: operator.knative.dev/v1alpha1
kind: KnativeEventing
metadata:
  name: knative-eventing
  namespace: knative-eventing
spec:
  config:
    default-ch-webhook:
      default-ch-config: |
        clusterDefault:
          apiVersion: messaging.knative.dev/v1beta1
          kind: KafkaChannel
          spec:
            numPartitions: 100
            replicationFactor: 1
    config-br-default-channel:
      channelTemplateSpec: |
        apiVersion: messaging.knative.dev/v1beta1
        kind: KafkaChannel
        spec:
          numPartitions: 100
          replicationFactor: 1
EOT
)"
  header_text "* Applying defaults to knative-eventing kafkachannel defaults"
  apply "$adjust_knative_eventing"

  header_text "* increase mt-broker-filter deployment replicas to 5"
  oc -n knative-eventing patch deployment/mt-broker-filter --patch='{"spec": {"replicas": 5}}'
  header_text "* increase mt-broker-ingress deployment replicas to 5"
  oc -n knative-eventing patch deployment/mt-broker-ingress --patch='{"spec": {"replicas": 5}}'

  header_text "* updating default maxIdleConns and maxIdleConnsPerHost settings"
  oc -n knative-eventing patch configmap/config-kafka --type=merge --patch='{"data": {"maxIdleConns": "1000", "maxIdleConnsPerHost": "1000"}}'

  header_text "* update image of the kafka-dispatcher"
  oc -n openshift-operators get csv/serverless-operator.v1.13.0 -oyaml | sed -e 's,registry.redhat.io/openshift-serverless-1-tech-preview/eventing-kafka-channel-dispatcher-rhel8@sha256:20efa1a9b5178340120325ade89818a2d08f0301234a45782dfd6a9471c36691,registry.ci.openshift.org/openshift/knative-v0.19.1@sha256:e3cc1571db4f6d3f4eb2ae1fd3dfad66bb2de0c2da271a10b12568d763892998,g' | oc replace -f -
}

kafka_default_broker_channel() {
  default_broker_channel=$(cat <<EOT
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-config-br-default-channel
  namespace: knative-eventing
data:
  channelTemplateSpec: |
    apiVersion: messaging.knative.dev/v1beta1
    kind: KafkaChannel
    spec:
      numPartitions: 100
      replicationFactor: 1
EOT
  )
  apply "$default_broker_channel"
}

setup_eventing_broker() {
  project_ns=${1:-"default"}
  apply_project "$project_ns"
  default_broker=$(cat <<EOT
apiVersion: eventing.knative.dev/v1
kind: Broker
metadata:
 name: default
 namespace: "$project_ns"
spec:
 config:
  apiVersion: v1
  kind: ConfigMap
  name: demo-config-br-default-channel
  namespace: knative-eventing
EOT
  )

  apply "$default_broker"
}

install_serverless
