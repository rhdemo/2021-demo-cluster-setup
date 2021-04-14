#!/bin/bash
set -e

. ./common.sh

rm -rf tokens

aws
make clean DG_NAMESPACE=datagrid

gcp
make clean DG_NAMESPACE=datagrid
