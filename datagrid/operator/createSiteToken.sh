#!/bin/bash
set -e
SITE=$(echo $DG_LOCAL_SITE | tr '[A-Z]' '[a-z]')
kubectl create serviceaccount $SITE -n $DG_NAMESPACE || true
kubectl create clusterrolebinding dg-view-binding --clusterrole=cluster-admin --serviceaccount=$DG_NAMESPACE:$SITE -n $DG_NAMESPACE || true

TOKEN_SECRET=$(kubectl get serviceaccount/$SITE -n $DG_NAMESPACE -o json | jq -r ".secrets[] | select(.name|test(\"$SITE-token.\")) | .name")
TOKEN=$(kubectl get secret $TOKEN_SECRET -o jsonpath='{.data.token}' -n $DG_NAMESPACE | base64 --decode)
mkdir -p tokens/$SITE
echo $TOKEN > tokens/$SITE/token
