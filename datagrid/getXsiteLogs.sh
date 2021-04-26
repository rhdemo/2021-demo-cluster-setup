#!/bin/bash
set -e
. ./common.sh

aws
echo "AWS"
mkdir -p logs/aws
oc -n datagrid logs datagrid-0 > logs/aws/datagrid-0
oc -n datagrid logs datagrid-1 > logs/aws/datagrid-1

gcp
echo "GCP"
mkdir -p logs/gcp
oc -n datagrid logs datagrid-0 > logs/gcp/datagrid-0
oc -n datagrid logs datagrid-1 > logs/gcp/datagrid-1

azure
echo "AZURE"
mkdir -p logs/azure
oc -n datagrid logs datagrid-0 > logs/azure/datagrid-0
oc -n datagrid logs datagrid-1 > logs/azure/datagrid-1
