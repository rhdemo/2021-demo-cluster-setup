#!/bin/bash
set -e

. ./common.sh

rm -rf tokens

aws
make cluster/xsite/tokens DG_LOCAL_SITE=AWS DG_NAMESPACE=datagrid

gcp
make cluster/xsite/tokens DG_LOCAL_SITE=GCP DG_NAMESPACE=datagrid
make cluster/xsite/secrets DG_NAMESPACE=datagrid

aws
make cluster/xsite/secrets DG_NAMESPACE=datagrid
make operator/install cluster/xsite/deploy DG_LOCAL_SITE=AWS DG_NAMESPACE=datagrid

gcp
make operator/install cluster/xsite/deploy DG_LOCAL_SITE=GCP DG_NAMESPACE=datagrid
