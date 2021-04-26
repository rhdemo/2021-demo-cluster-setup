#!/bin/bash
. ./common.sh

aws
echo "AWS"
oc -n datagrid logs datagrid-0 | grep -n org.infinispan.XSITE
oc -n datagrid logs datagrid-0 | grep -n "is offline"

gcp
echo "GCP"
oc -n datagrid logs datagrid-0 | grep -n org.infinispan.XSITE
oc -n datagrid logs datagrid-0 | grep -n "is offline"

azure
echo "AZURE"
oc -n datagrid logs datagrid-0 | grep -n org.infinispan.XSITE
oc -n datagrid logs datagrid-0 | grep -n "is offline"
