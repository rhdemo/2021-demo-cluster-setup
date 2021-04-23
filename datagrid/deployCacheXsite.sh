#!/bin/bash
set -e
. ./common.sh

aws
make caches/xsite/deploy DG_REMOTE_SITE_1=GCP DG_REMOTE_SITE_2=AZURE DG_NAMESPACE=datagrid

gcp
make caches/xsite/deploy DG_REMOTE_SITE_1=AWS DG_REMOTE_SITE_2=AZURE DG_NAMESPACE=datagrid

azure
make caches/xsite/deploy DG_REMOTE_SITE_1=AWS DG_REMOTE_SITE_2=GCP DG_NAMESPACE=datagrid
