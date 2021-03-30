#!/bin/sh

#####################################################################################################
#                                                                                                   # 
# Deploys the latest released Strimzi Operator in the openshift-operators namespace.                #
#                                                                                                   #
######################################################################################################

source temp-env.sh
source functions.sh

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
    #serving_version="v0.20.0"
    #kourier_version="v0.20.0"
    #eventing_version="v0.20.1"
    #eventing_kafka_version="v0.20.0"

    # Default version for subscriptions
    #VERSION_OPENSHIFT_SERVERLESS="1.13.0"

    # Channel to use for subscriptions
    #OLM_CHANNEL="4.6"
    OLM_CHANNEL=${OLM_CHANNEL:-4.6}


    #streams versioning
    #VERSION_OPENSHIFT_STREAMS="1.6.2"
    #STREAMS_OLM_CHANNEL="stable"
    #STRIMZI_OLM_CHANNEL="stable"
    STRIMZI_OLM_CHANNEL=${STRIMZI_OLM_CHANNEL:-stable}
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

install() {
    mk_environment
    apply_openshift_strimzi_subscription
}

install
