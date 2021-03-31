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

mk_environment() {
    NO_COLOR=${NO_COLOR:-""}
    if [ -z "$NO_COLOR" ]; then
    header=$'\e[1;33m'
    reset=$'\e[0m'
    else
    header=''
    reset=''
    fi

    NAMESPACE=${KAFKA_NAMESPACE:-game-kafka}
    PROMETHEUS_OLM_CHANNEL=${PROMETHEUS_OLM_CHANNEL:-beta}
    PROMETHEUS_IMAGE=quay.io/openshift/origin-prometheus:4.7
    PROMETHEUS_AUTH_PROXY_IMAGE=quay.io/openshift/origin-oauth-proxy:4.7
    PROMETHEUS_TLS_SECRET=prometheus-k8s-tls
    PROMETHEUS_OAUTH_PROXY_SECRET=prometheus-k8s-proxy
    PROMETHEUS_ROUTE=prometheus-route
    PROMETHEUS_SERVICE_ACCOUNT=prometheus-service-account
    PROMETHEUS_NAME=strimzi

    GRAFANA_OLM_CHANNEL=alpha
    GRAFANA_OAUTH_PROXY_SECRET=grafana-k8s-proxy
    GRAFANA_AUTH_PROXY_IMAGE=quay.io/openshift/origin-oauth-proxy:4.7
    GRAFANA_NAME=grafana

    MONITORING_LABEL_VALUE=strimzi
}

apply_operator_group() {
  name=${1:-${NAMESPACE}}
  namespace=${2:-${NAMESPACE}}
  target_namespace=${3:-${NAMESPACE}}

  header_text "Installing operator group in namespace ${namespace}."
  apply_project $NAMESPACE

  operatorgroup=$(cat <<EOT
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: ${name}
  namespace: ${namespace}
spec:
  targetNamespaces:
  - ${target_namespace}
EOT
  )

  apply "$operatorgroup"

}

apply_prometheus_operator() {
  namespace=${1:-${NAMESPACE}}
  channel=${2:-${PROMETHEUS_OLM_CHANNEL}}
  starting_csv=${3:-""}

  header_text "Installing Prometheus in namespace ${namespace}."

  header_text "Prometheus operator install"

  subscription=$(cat <<EOT
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: prometheus-operator
  namespace: ${namespace}
spec:
  channel: "${channel}"
  installPlanApproval: Automatic
  name: prometheus
  source: community-operators
  sourceNamespace: openshift-marketplace
  startingCSV: ${starting_csv}
EOT
  )
  apply "$subscription"

  header_text "* Waiting for Prometheus operator to come up"
  wait_for_operator ${namespace} "prometheus-operator"
}

apply_prometheus() {
  namespace=${1:-${NAMESPACE}}
  
  header_text "Prometheus server install"

  header_text "Prometheus service account"
  service_account=$(cat <<EOT
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${PROMETHEUS_SERVICE_ACCOUNT}
  namespace: ${namespace}
  annotations:
    serviceaccounts.openshift.io/oauth-redirectreference.primary: '{"kind":"OAuthRedirectReference","apiVersion":"v1","reference":{"kind":"Route","name":"${PROMETHEUS_ROUTE}"}}'  
EOT
  )
  apply "${service_account}"

  header_text "Prometheus service account role"
  service_account_role=$(cat <<EOT
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: prometheus-monitoring
rules:
- apiGroups:
  - authentication.k8s.io
  resources:
  - tokenreviews
  verbs:
  - create
- apiGroups:
  - authorization.k8s.io
  resources:
  - subjectaccessreviews
  verbs:
  - create
- apiGroups: [""]
  resources:
  - nodes
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources:
  - configmaps
  - namespaces # Required to get through the alertmanager oauth proxy
  verbs: ["get"]  
EOT
  )
  apply "${service_account_role}"

  out=$(oc adm policy add-role-to-user prometheus-monitoring -z ${PROMETHEUS_SERVICE_ACCOUNT} --rolebinding-name=prometheus-monitoring --role-namespace=${namespace} -n ${namespace} 2>&1)
  header_text ${out}

  header_text "Prometheus oauth secret"
  oauth_session=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 43 | head -n 1)
  oauth_secret=$(cat << EOT
apiVersion: v1
kind: Secret
metadata:
  name: ${PROMETHEUS_OAUTH_PROXY_SECRET}
  namespace: ${namespace}
stringData:
  session_secret: ${oauth_session}
EOT
  )
  apply "${oauth_secret}"

  header_text "Prometheus service"
  prometheus_service=$(cat << EOT
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
  namespace: ${namespace}
  annotations:
    service.alpha.openshift.io/serving-cert-secret-name: ${PROMETHEUS_TLS_SECRET}
spec:
  type: ClusterIP
  ports:
    - name: web
      port: 9091
      protocol: TCP
      targetPort: oproxy
    - name: upstream
      port: 9090
      protocol: TCP
      targetPort: web
  selector:
    app: prometheus
  sessionAffinity: None
EOT
  )
  apply "${prometheus_service}"

  header_text "Prometheus route"
  prometheus_route=$(cat <<EOT
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: prometheus-route
  namespace: ${namespace}
spec:
  port:
    targetPort: web
  tls:
    termination: Reencrypt
  to:
    kind: Service
    name: prometheus-service
  wildcardPolicy: None  
EOT
  )
  apply "${prometheus_route}"

  header_text "Prometheus custom resource"
  mkdir -p $DIR/monitoring/work
  cp $DIR/monitoring/prometheus-cr.yaml $DIR/monitoring/work/prometheus-cr.yaml

  prometheus_external_url=$(oc get route prometheus-route -o jsonpath="{.spec.host}")
  
  sed -i "s|{{ prometheus_name }}|${PROMETHEUS_NAME}|g" $DIR/monitoring/work/prometheus-cr.yaml
  sed -i "s|{{ prometheus_image }}|${PROMETHEUS_IMAGE}|g" $DIR/monitoring/work/prometheus-cr.yaml
  sed -i "s|{{ prometheus_auth_proxy_image }}|${PROMETHEUS_AUTH_PROXY_IMAGE}|g" $DIR/monitoring/work/prometheus-cr.yaml
  sed -i "s|{{ prometheus_tls_secret }}|${PROMETHEUS_TLS_SECRET}|g" $DIR/monitoring/work/prometheus-cr.yaml
  sed -i "s|{{ prometheus_oauth_proxy_secret }}|${PROMETHEUS_OAUTH_PROXY_SECRET}|g" $DIR/monitoring/work/prometheus-cr.yaml
  sed -i "s|{{ prometheus_external_url }}|${prometheus_external_url}|g" $DIR/monitoring/work/prometheus-cr.yaml

  out=$(oc apply -f $DIR/monitoring/work/prometheus-cr.yaml -n ${namespace} 2>&1)
  header_text $out

  wait_for_prometheus

}

wait_for_prometheus() {
  name=${1:-${PROMETHEUS_NAME}}
  namespace=${1:-${NAMESPACE}}
  
  header_text "* Waiting for Prometheus StatefulSet to be ready..."
  readyReplicas="0"
  prometheusReplicas=$(oc get prometheus ${name} -o jsonpath="{.spec.replicas}" -n ${namespace})
  while [ "$readyReplicas" != "$prometheusReplicas" ]
  do
    sleep 2
    readyReplicas=$(oc get statefulset prometheus-${name} -o jsonpath="{.status.readyReplicas}" -n ${namespace})
  done
  header_text "  Prometheus statefulset ready"
}


apply_grafana_operator() {
  namespace=${1:-${NAMESPACE}}
  channel=${2:-${GRAFANA_OLM_CHANNEL}}
  starting_csv=${3:-""}

  header_text "Installing Grafana in namespace ${namespace}."

  header_text "Grafana operator install"

  subscription=$(cat <<EOT
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: grafana-operator
  namespace: ${namespace}
spec:
  channel: "${channel}"
  installPlanApproval: Automatic
  name: grafana-operator
  source: community-operators
  sourceNamespace: openshift-marketplace
  startingCSV: ${starting_csv}
EOT
  )
  apply "$subscription"

  header_text "* Waiting for Grafana operator to come up"
  wait_for_operator ${namespace} "grafana-operator"
}

apply_grafana() {
  namespace=${1:-${NAMESPACE}}

  header_text "Grafana server install"

  header_text "Grafana oauth secret"
  oauth_session=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 43 | head -n 1)
  oauth_secret=$(cat << EOT
apiVersion: v1
kind: Secret
metadata:
  name: ${GRAFANA_OAUTH_PROXY_SECRET}
  namespace: ${namespace}
stringData:
  session_secret: ${oauth_session}
EOT
  )
  apply "${oauth_secret}"

  header_text "Grafana datasource"
  datasource=$(cat << EOT
apiVersion: integreatly.org/v1alpha1
kind: GrafanaDataSource
metadata:
  name: prometheus
spec:
  name: prometheus.yaml
  datasources:
    - name: Prometheus
      type: prometheus
      access: proxy
      url: http://prometheus-service:9090
      isDefault: true
      version: 1
      editable: true
      jsonData:
        timeInterval: "5s"
EOT
  )
  apply "${datasource}"

  header_text "Grafana custom resource"
  
  mkdir -p $DIR/monitoring/work 
  cp $DIR/monitoring/grafana-cr.yaml $DIR/monitoring/work/grafana-cr.yaml

  sed -i "s|{{ grafana_name }}|${GRAFANA_NAME}|g" $DIR/monitoring/work/grafana-cr.yaml
  sed -i "s|{{ grafana_auth_proxy_image }}|${GRAFANA_AUTH_PROXY_IMAGE}|g" $DIR/monitoring/work/grafana-cr.yaml
  sed -i "s|{{ monitoring_label_value }}|${MONITORING_LABEL_VALUE}|g" $DIR/monitoring/work/grafana-cr.yaml

  out=$(oc apply -f $DIR/monitoring/work/grafana-cr.yaml -n ${namespace} 2>&1)
  header_text $out
  
  wait_for_grafana
}

wait_for_grafana() {
  name=${1:-${GRAFANA_NAME}-deployment}
  namespace=${2:-${NAMESPACE}}

  header_text "* Waiting for Grafana deployment to be ready..."
  wait_for_deployment ${namespace} ${name}
  header_text "  Grafana deployment ready"
}

apply_kafka_dashboards() {
  namespace=${1:-${NAMESPACE}}

  # update namespace with monitoring label
  out=$(oc label --overwrite=true namespace ${namespace} monitoring-key=${MONITORING_LABEL_VALUE})
  header_text $out

  # create kafka PodMonitor
  mkdir -p $DIR/monitoring/work
  cp $DIR/monitoring/kafka-podmonitor.yaml $DIR/monitoring/work/kafka-podmonitor.yaml
  sed -i "s|{{ namespace }}|${namespace}|g" $DIR/monitoring/work/kafka-podmonitor.yaml

  out=$(oc apply -f $DIR/monitoring/work/kafka-podmonitor.yaml -n ${namespace} 2>&1)
  header_text $out

  # create kafka cluster dashboard
  cp $DIR/monitoring/dashboards/kafka-cluster-dashboard.yaml $DIR/monitoring/work/kafka-cluster-dashboard.yaml
  sed -i "s|{{ monitoring_label_value }}|${MONITORING_LABEL_VALUE}|g" $DIR/monitoring/work/kafka-cluster-dashboard.yaml

  out=$(oc apply -f $DIR/monitoring/work/kafka-cluster-dashboard.yaml -n ${namespace} 2>&1)
  header_text $out

  # create kafka zookeeper dashboard
  cp $DIR/monitoring/dashboards/kafka-zookeeper-dashboard.yaml $DIR/monitoring/work/kafka-zookeeper-dashboard.yaml
  sed -i "s|{{ monitoring_label_value }}|${MONITORING_LABEL_VALUE}|g" $DIR/monitoring/work/kafka-zookeeper-dashboard.yaml

  out=$(oc apply -f $DIR/monitoring/work/kafka-zookeeper-dashboard.yaml -n ${namespace} 2>&1)
  header_text $out

  # create kafka exporter dashboard
  cp $DIR/monitoring/dashboards/kafka-exporter-dashboard.yaml $DIR/monitoring/work/kafka-exporter-dashboard.yaml
  sed -i "s|{{ monitoring_label_value }}|${MONITORING_LABEL_VALUE}|g" $DIR/monitoring/work/kafka-exporter-dashboard.yaml

  out=$(oc apply -f $DIR/monitoring/work/kafka-exporter-dashboard.yaml -n ${namespace} 2>&1)
  header_text $out

}


deploy() {
    mk_environment

    apply_operator_group

    apply_prometheus_operator

    apply_prometheus
    
    apply_grafana_operator

    apply_grafana

    apply_kafka_dashboards

}


deploy
