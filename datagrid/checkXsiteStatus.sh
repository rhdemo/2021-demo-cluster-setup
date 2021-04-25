#!/bin/bash
set -e
. ./common.sh

aws
echo "AWS"
oc -n datagrid logs datagrid-0 | grep org.infinispan.XSITE

gcp
echo "GCP"
oc -n datagrid logs datagrid-0 | grep org.infinispan.XSITE

azure
echo "AZURE"
oc -n datagrid logs datagrid-0 | grep org.infinispan.XSITE
