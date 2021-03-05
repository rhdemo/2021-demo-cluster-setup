#!/bin/bash
. common.sh

# Initiate config
batch_file="batch-failover"
if grep -q "##BACKUP_SITE_IP##" config/distributed-off-heap-*-failover.xml; then
    echo "##BACKUP_SITE_IP## placeholder in config/distributed-off-heap-*-failover.xml files must be replaced with BACKUP_SITE ExternalIP 'oc get service/datagrid-service-external'"
    exit 1
fi

createProjectAndDeploy

waitForDeployment

executeBatchFile "batch-failover"
