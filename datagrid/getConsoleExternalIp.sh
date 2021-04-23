#!/bin/bash
set -e
. ./common.sh

aws
echo "AWS: $(oc -n datagrid get svc datagrid-external)"

gcp
echo "GCP: $(oc -n datagrid get svc datagrid-external)"

azure
echo "AZURE: $(oc -n datagrid get svc datagrid-external)"
