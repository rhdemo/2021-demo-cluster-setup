#!/bin/bash
set -e
. ./common.sh

aws
make caches/xsite/deploy DG_REMOTE_SITE=GCP DG_NAMESPACE=datagrid

gcp
make caches/xsite/deploy DG_REMOTE_SITE=AWS DG_NAMESPACE=datagrid
