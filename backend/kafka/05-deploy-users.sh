#!/bin/bash

#####################################################################################################
#                                                                                                   # 
# Deploys Kafka User
#                                                                                                   #
######################################################################################################

# Replace sed with gsed on macOS
if [[ $OSTYPE == "darwin"* ]]; then
   sed () { gsed "$@"; }
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source $DIR/temp-env.sh
source $DIR/functions.sh

NAMESPACE=${KAFKA_NAMESPACE:-game-kafka}
CLUSTER=${KAFKA_CLUSTER:-demo2021}



sed "s/my-cluster/$CLUSTER/" $DIR/cluster/kafka-users.yaml > $DIR/cluster/$CLUSTER-kafka-users.yaml

oc apply -f $DIR/cluster/$CLUSTER-kafka-users.yaml -n $NAMESPACE

rm $DIR/cluster/$CLUSTER-kafka-users.yaml