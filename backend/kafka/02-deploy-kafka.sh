#!/bin/sh


#####################################################################################################
#                                                                                                   # 
# Deploys the latest released Strimzi Operator in the openshift-operators namespace.                #
#                                                                                                   #
######################################################################################################

# Replace sed with gsed on macOS
if [[ $(name) -eq Darwin ]]; then
   sed () { gsed "$@"; }
   #echo 'You are on a mac!'
   #type sed
fi

source temp-env.sh
source functions.sh

NAMESPACE=${KAFKA_NAMESPACE:-game-kafka}
CLUSTER=${KAFKA_CLUSTER:-demo2021}
EXPOSE=${KAFKA_EXPOSE:-false}
EXPORTER=${KAFKA_EXPORTER:-true}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

mk_environment() {
    NO_COLOR=${NO_COLOR:-""}
    if [ -z "$NO_COLOR" ]; then
    header=$'\e[1;33m'
    reset=$'\e[0m'
    else
    header=''
    reset=''
    fi
}

apply_kafka() {

  header_text "Installing Kafka instance $CLUSTER in namespace $NAMESPACE."

  cp $DIR/cluster/kafka-persistent-with-metrics.yaml $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml

  sed -i "s/my-cluster/$CLUSTER/" $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml
  
  # if Kafka Exporter is enabled, the corresponding YAML is added to the Kafka resource
  if [ "$EXPORTER" == "true" ]; then
    #yq m -i $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml $DIR/cluster/kafka-exporter.yaml
    yq -i eval-all 'select(fi == 0) * select(fi == 1)' $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml $DIR/cluster/kafka-exporter.yaml
  fi

  # if Kafka has to be exposed, an external listener is added
  if [ "$EXPOSE" == "true" ]; then
    #yq w -i $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml spec.kafka.listeners.external.type loadbalancer
    #yq w -i $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml spec.kafka.listeners.external.type route
    yq -i eval '.spec.kafka.listeners.external.type = "route"' $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml
    
    #yq w -i $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml spec.kafka.listeners.external.tls false
    yq -i eval '.spec.kafka.listeners.external.tls = false' $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml
    
    #yq w -i $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml spec.kafka.listeners.external.port 9094
    yq -i eval '.spec.kafka.listeners.external.port = 9094' $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml
  fi

  header_text "Strimzi Kafka instance install"
  apply_project $NAMESPACE
  
  header_text "Applying Strimzi Kafka Cluster file"
  
  #kafka = `cat $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml`
  #apply "$kafka"
  
  out=$(oc apply -f $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml -n $NAMESPACE 2>&1)
  header_text $out

  # delay for allowing cluster operator to create the ZooKeeper statefulset
  sleep 5


  #header_text "Waiting for Strimzi to become ready"
  #wait_for_all_deployments "$NAMESPACE"
  #header_text "Strimzi ready"
}


wait_for_kafka() {
    header_text "Wait for Kafka deployments to be ready."
    sleep 5
    zkReplicas=$(oc get kafka $CLUSTER -o jsonpath="{.spec.zookeeper.replicas}" -n $NAMESPACE)
    echo "Waiting for Zookeeper cluster to be ready..."
    readyReplicas="0"
    while [ "$readyReplicas" != "$zkReplicas" ]
    do
        sleep 2
        readyReplicas=$(oc get statefulsets $CLUSTER-zookeeper -o jsonpath="{.status.readyReplicas}" -n $NAMESPACE)
    done
    echo "...Zookeeper cluster ready"

    kReplicas=$(oc get kafka $CLUSTER -o jsonpath="{.spec.kafka.replicas}" -n $NAMESPACE)

    # # waiting for the LB address
    # if [ "$EXPOSE" == "true" ]; then
    #     echo "Waiting LB address for $CLUSTER-kafka-external-bootstrap service..."
    #     lbAddress=""
    #     while [ -z "$lbAddress" ]
    #     do
    #         # checking for ip or hostname (it would be different between AWS, GCP, Azure, ...)
    #         lbAddress=$(oc get svc $CLUSTER-kafka-external-bootstrap -o jsonpath="{.status.loadBalancer.ingress[]['ip', 'hostname']}")
    #         echo "... $lbAddress"
    #         sleep 5
    #     done
    #     echo "...LB address for $CLUSTER-kafka-external-bootstrap service ready"

    #     for ((i=0; i<kReplicas; i++))
    #     do
    #         echo "Waiting LB address for $CLUSTER-kafka-$i service..."
    #         lbAddress=""
    #         while [ -z "$lbAddress" ]
    #         do
    #             # checking for ip or hostname (it would be different between AWS, GCP, Azure, ...)
    #             lbAddress=$(oc get svc $CLUSTER-kafka-$i -o jsonpath="{.status.loadBalancer.ingress[]['ip', 'hostname']}")
    #             echo "... $lbAddress"
    #             sleep 5
    #         done
    #         echo "...LB address for $CLUSTER-kafka-$i service ready"
    #     done
    # fi

    # delay for allowing cluster operator to create the Kafka statefulset
    sleep 5

    echo "Waiting for Kafka cluster to be ready..."
    readyReplicas="0"
    while [ "$readyReplicas" != "$kReplicas" ]
    do
        sleep 2
        readyReplicas=$(oc get statefulsets $CLUSTER-kafka -o jsonpath="{.status.readyReplicas}" -n $NAMESPACE)
    done
    echo "...Kafka cluster ready"

    # delay for allowing cluster operator to create the Entity Operator deployment
    sleep 5

    echo "Waiting for entity operator to be ready..."
    wait_for_deployments_to_be_created $NAMESPACE $CLUSTER-entity-operator
    oc rollout status deployment/$CLUSTER-entity-operator -w -n $NAMESPACE
    echo "...entity operator ready"

    # delay for allowing cluster operator to create the Kafka Exporter deployment
    sleep 5

    echo "Waiting for Kafka exporter to be ready..."
    oc rollout status deployment/$CLUSTER-kafka-exporter -w -n $NAMESPACE
    echo "...Kafka exporter ready"

    #rm $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml

    # waiting finally Kafka is ready
    kStatus="NotReady"
    while [ "$kStatus" != "Ready" ]
    do
        kStatus=$(oc get kafka $CLUSTER -o jsonpath="{.status.conditions[].type}" -n $NAMESPACE)
        sleep 2
    done
}

deploy() {
    mk_environment
    apply_kafka
    wait_for_kafka
}


deploy




#------------------------------------------------------------------------------------------------------------------------------------------------------------------------


kafka_cluster_2020() {

    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

    sed "s/my-cluster/$CLUSTER/" $DIR/cluster/kafka-persistent-with-metrics.yaml > $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml
    sed -i "s/my-kafka-version/$VERSION/" $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml

    # if Kafka Exporter is enabled, the corresponding YAML is added to the Kafka resource
    if [ "$EXPORTER" == "true" ]; then
        yq m -i $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml $DIR/cluster/kafka-exporter.yaml
    fi

    # if Kafka has to be exposed, an external listener is added
    if [ "$EXPOSE" == "true" ]; then
        yq w -i $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml spec.kafka.listeners.external.type loadbalancer
        yq w -i $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml spec.kafka.listeners.external.tls false
    fi

    oc apply -f $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml -n $NAMESPACE

    # delay for allowing cluster operator to create the ZooKeeper statefulset
    sleep 5

    zkReplicas=$(oc get kafka $CLUSTER -o jsonpath="{.spec.zookeeper.replicas}" -n $NAMESPACE)
    echo "Waiting for Zookeeper cluster to be ready..."
    readyReplicas="0"
    while [ "$readyReplicas" != "$zkReplicas" ]
    do
        sleep 2
        readyReplicas=$(oc get statefulsets $CLUSTER-zookeeper -o jsonpath="{.status.readyReplicas}" -n $NAMESPACE)
    done
    echo "...Zookeeper cluster ready"

    kReplicas=$(oc get kafka $CLUSTER -o jsonpath="{.spec.kafka.replicas}" -n $NAMESPACE)

    # waiting for the LB address
    if [ "$EXPOSE" == "true" ]; then
        echo "Waiting LB address for $CLUSTER-kafka-external-bootstrap service..."
        lbAddress=""
        while [ -z "$lbAddress" ]
        do
            # checking for ip or hostname (it would be different between AWS, GCP, Azure, ...)
            lbAddress=$(oc get svc $CLUSTER-kafka-external-bootstrap -o jsonpath="{.status.loadBalancer.ingress[]['ip', 'hostname']}")
            echo "... $lbAddress"
            sleep 5
        done
        echo "...LB address for $CLUSTER-kafka-external-bootstrap service ready"

        for ((i=0; i<kReplicas; i++))
        do
            echo "Waiting LB address for $CLUSTER-kafka-$i service..."
            lbAddress=""
            while [ -z "$lbAddress" ]
            do
                # checking for ip or hostname (it would be different between AWS, GCP, Azure, ...)
                lbAddress=$(oc get svc $CLUSTER-kafka-$i -o jsonpath="{.status.loadBalancer.ingress[]['ip', 'hostname']}")
                echo "... $lbAddress"
                sleep 5
            done
            echo "...LB address for $CLUSTER-kafka-$i service ready"
        done
    fi

    # delay for allowing cluster operator to create the Kafka statefulset
    sleep 5

    echo "Waiting for Kafka cluster to be ready..."
    readyReplicas="0"
    while [ "$readyReplicas" != "$kReplicas" ]
    do
        sleep 2
        readyReplicas=$(oc get statefulsets $CLUSTER-kafka -o jsonpath="{.status.readyReplicas}" -n $NAMESPACE)
    done
    echo "...Kafka cluster ready"

    # delay for allowing cluster operator to create the Entity Operator deployment
    sleep 5

    echo "Waiting for entity operator to be ready..."
    oc rollout status deployment/$CLUSTER-entity-operator -w -n $NAMESPACE
    echo "...entity operator ready"

    # delay for allowing cluster operator to create the Kafka Exporter deployment
    sleep 5

    echo "Waiting for Kafka exporter to be ready..."
    oc rollout status deployment/$CLUSTER-kafka-exporter -w -n $NAMESPACE
    echo "...Kafka exporter ready"

    rm $DIR/cluster/$CLUSTER-kafka-persistent-with-metrics.yaml

    # waiting finally Kafka is ready
    kStatus="NotReady"
    while [ "$kStatus" != "Ready" ]
    do
        kStatus=$(oc get kafka $CLUSTER -o jsonpath="{.status.conditions[].type}")
        sleep 2
    done

    if [ "$EXPOSE" == "true" ]; then
        # printing external access service for Kafka Mirror Maker
        svcExternalBootstrapHostname=$(oc get kafka $CLUSTER -o jsonpath="{.status.listeners[?(@.type == 'external')].addresses[].host}")
        svcExternalBootstrapPort=$(oc get kafka $CLUSTER -o jsonpath="{.status.listeners[?(@.type == 'external')].addresses[].port}")
        echo "$CLUSTER - svc external bootstrap: $svcExternalBootstrapHostname:$svcExternalBootstrapPort"
        echo "$OC_ALIAS=$svcExternalBootstrapHostname:$svcExternalBootstrapPort" >> $DIR/clusters.lbs
    fi
}