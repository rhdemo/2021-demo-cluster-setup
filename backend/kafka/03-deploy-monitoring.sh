#!/bin/sh

#####################################################################################################
#                                                                                                   # 
# Deploys Prometheus and Grafana                                                                    #
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
CLUSTER=${KAFKA_CLUSTER:-demo2020}
VERSION=${KAFKA_VERSION:-2.4.0}
EXPOSE=${KAFKA_EXPOSE:-false}
EXPORTER=${KAFKA_EXPORTER:-true}




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

apply_prometheus() {

  header_text "Installing Kafka instance $CLUSTER in namespace $NAMESPACE."

  header_text "Monitoring install"
  apply_project $NAMESPACE

  cat $DIR/monitoring/prometheus.yaml | sed -e "s/namespace: .*/namespace: $NAMESPACE/;s/regex: myproject/regex: $NAMESPACE/" > $DIR/monitoring/prometheus-deploy.yaml

  oc apply -f $DIR/monitoring/alerting-rules.yaml -n $NAMESPACE
  oc apply -f $DIR/monitoring/prometheus-deploy.yaml -n $NAMESPACE
  rm $DIR/monitoring/prometheus-deploy.yaml
  oc apply -f $DIR/monitoring/alertmanager.yaml -n $NAMESPACE
  oc expose service/prometheus -n $NAMESPACE
}

wait_for_prometheus() {
    
    echo "Waiting for Prometheus server to be ready..."
    oc rollout status deployment/prometheus -w -n $NAMESPACE
    oc rollout status deployment/alertmanager -w -n $NAMESPACE
    echo "...Prometheus server ready"
}


apply_grafana() {
    cp $DIR/monitoring/dashboards/strimzi-kafka.json $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json
    
    sed -i 's/${DS_PROMETHEUS}/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json
    sed -i 's/DS_PROMETHEUS/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json

    # build the Zookeeper dashboard
    cp $DIR/monitoring/dashboards/strimzi-zookeeper.json $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json

    sed -i 's/${DS_PROMETHEUS}/Prometheus/' $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json
    sed -i 's/DS_PROMETHEUS/Prometheus/' $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json

    ## build the Kafka Mirror Maker 2 dashboard
    #cp $DIR/monitoring/dashboards/strimzi-kafka-mirror-maker-2.json $DIR/monitoring/dashboards/strimzi-kafka-mirror-maker-2-dashboard.json

    #sed -i 's/${DS_PROMETHEUS}/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-mirror-maker-2-dashboard.json
    #sed -i 's/DS_PROMETHEUS/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-mirror-maker-2-dashboard.json

    # build the Kafka Exporter dashboard
    cp $DIR/monitoring/dashboards/strimzi-kafka-exporter.json $DIR/monitoring/dashboards/strimzi-kafka-exporter-dashboard.json
    
    sed -i 's/${DS_PROMETHEUS}/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-exporter-dashboard.json
    sed -i 's/DS_PROMETHEUS/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-exporter-dashboard.json

    oc create configmap grafana-config \
        --from-file=datasource.yaml=$DIR/monitoring/dashboards/datasource.yaml \
        --from-file=grafana-dashboard-provider.yaml=$DIR/monitoring/grafana-dashboard-provider.yaml \
        --from-file=strimzi-kafka-dashboard.json=$DIR/monitoring/dashboards/strimzi-kafka-dashboard.json \
        --from-file=strimzi-zookeeper-dashboard.json=$DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json \
        --from-file=strimzi-kafka-exporter-dashboard.json=$DIR/monitoring/dashboards/strimzi-kafka-exporter-dashboard.json \
        -n $NAMESPACE
        #--from-file=strimzi-kafka-mirror-maker-2-dashboard.json=$DIR/monitoring/dashboards/strimzi-kafka-mirror-maker-2-dashboard.json \

    oc label configmap grafana-config app=strimzi

    rm $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json
    rm $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json
    #rm $DIR/monitoring/dashboards/strimzi-kafka-mirror-maker-2-dashboard.json
    rm $DIR/monitoring/dashboards/strimzi-kafka-exporter-dashboard.json

    # Grafana
    oc apply -f $DIR/monitoring/grafana.yaml -n $NAMESPACE
    oc expose service/grafana -n $NAMESPACE

}

wait_for_grafana() {
    #echo "Waiting for Grafana server to be ready..."
    oc rollout status deployment/grafana -w -n $NAMESPACE
    echo "...Grafana server ready"
}


deploy() {
    mk_environment
    apply_prometheus
    wait_for_prometheus

    apply_grafana
    wait_for_grafana
}


deploy

#-----------------------------------------------------------------------------------------------------------------------------------------------

monitoring_2020() {
NAMESPACE=${KAFKA_NAMESPACE:-kafka-demo}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Prometheus
cat $DIR/monitoring/prometheus.yaml | sed -e "s/namespace: .*/namespace: $NAMESPACE/;s/regex: myproject/regex: $NAMESPACE/" > $DIR/monitoring/prometheus-deploy.yaml

oc apply -f $DIR/monitoring/alerting-rules.yaml -n $NAMESPACE
oc apply -f $DIR/monitoring/prometheus-deploy.yaml -n $NAMESPACE
rm $DIR/monitoring/prometheus-deploy.yaml
oc apply -f $DIR/monitoring/alertmanager.yaml -n $NAMESPACE
oc expose service/prometheus -n $NAMESPACE

echo "Waiting for Prometheus server to be ready..."
oc rollout status deployment/prometheus -w -n $NAMESPACE
oc rollout status deployment/alertmanager -w -n $NAMESPACE
echo "...Prometheus server ready"

# Preparing Grafana datasource and dashboards

# build the Kafka dashboard
cp $DIR/monitoring/dashboards/strimzi-kafka.json $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json

sed -i 's/${DS_PROMETHEUS}/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json
sed -i 's/DS_PROMETHEUS/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json

# build the Zookeeper dashboard
cp $DIR/monitoring/dashboards/strimzi-zookeeper.json $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json

sed -i 's/${DS_PROMETHEUS}/Prometheus/' $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json
sed -i 's/DS_PROMETHEUS/Prometheus/' $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json

# build the Kafka Mirror Maker 2 dashboard
cp $DIR/monitoring/dashboards/strimzi-kafka-mirror-maker-2.json $DIR/monitoring/dashboards/strimzi-kafka-mirror-maker-2-dashboard.json

sed -i 's/${DS_PROMETHEUS}/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-mirror-maker-2-dashboard.json
sed -i 's/DS_PROMETHEUS/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-mirror-maker-2-dashboard.json

# build the Kafka Exporter dashboard
cp $DIR/monitoring/dashboards/strimzi-kafka-exporter.json $DIR/monitoring/dashboards/strimzi-kafka-exporter-dashboard.json

sed -i 's/${DS_PROMETHEUS}/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-exporter-dashboard.json
sed -i 's/DS_PROMETHEUS/Prometheus/' $DIR/monitoring/dashboards/strimzi-kafka-exporter-dashboard.json

oc create configmap grafana-config \
    --from-file=datasource.yaml=$DIR/monitoring/dashboards/datasource.yaml \
    --from-file=grafana-dashboard-provider.yaml=$DIR/monitoring/grafana-dashboard-provider.yaml \
    --from-file=strimzi-kafka-dashboard.json=$DIR/monitoring/dashboards/strimzi-kafka-dashboard.json \
    --from-file=strimzi-zookeeper-dashboard.json=$DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json \
    --from-file=strimzi-kafka-mirror-maker-2-dashboard.json=$DIR/monitoring/dashboards/strimzi-kafka-mirror-maker-2-dashboard.json \
    --from-file=strimzi-kafka-exporter-dashboard.json=$DIR/monitoring/dashboards/strimzi-kafka-exporter-dashboard.json \
    -n $NAMESPACE

oc label configmap grafana-config app=strimzi

rm $DIR/monitoring/dashboards/strimzi-kafka-dashboard.json
rm $DIR/monitoring/dashboards/strimzi-zookeeper-dashboard.json
rm $DIR/monitoring/dashboards/strimzi-kafka-mirror-maker-2-dashboard.json
rm $DIR/monitoring/dashboards/strimzi-kafka-exporter-dashboard.json

# Grafana
oc apply -f $DIR/monitoring/grafana.yaml -n $NAMESPACE
oc expose service/grafana -n $NAMESPACE

#echo "Waiting for Grafana server to be ready..."
oc rollout status deployment/grafana -w -n $NAMESPACE
echo "...Grafana server ready"
}