#!/bin/bash
INSTANCES=${1:-2}
RESOURCE_DIR=$(dirname "$0")
PROJECT="datagrid-demo"
REST_USER="lnd1-ffm1"
REST_PASS="lnd1-ffm1"
FAILOVER_SITE="summit-aws-lnd1"
BACKUP_SITE="summit-gcp-ffm1"
set -e

waitForDeployment() {
    while [ "$(oc get statefulset datagrid-service -o jsonpath='{.status.readyReplicas}')" != "$INSTANCES" ]; do
        echo "Waiting for statefulset to have $INSTANCES readyReplicas"
        sleep 5
    done
}

createProjectAndDeploy() {
    oc new-project $PROJECT || true
    oc project $PROJECT
    oc create -f $RESOURCE_DIR/datagrid-service.yaml
    oc create configmap datagrid-configuration --from-file=$RESOURCE_DIR/config
    oc new-app --template=datagrid-service -p NUMBER_OF_INSTANCES=$INSTANCES
}

executeBatchFile() {
    oc exec datagrid-service-0 -- /opt/infinispan/bin/cli.sh -c http://$REST_USER:$REST_PASS@datagrid-service.$PROJECT.svc.cluster.local:11222 --file=/config/$1
}
