#!/bin/bash
set -e
SITE=$(echo $DG_LOCAL_SITE | tr '[A-Z]' '[a-z]')
kubectl create sa $SITE -n $DG_NAMESPACE || true
kubectl create rolebinding dg-view-binding --clusterrole=view --serviceaccount=$DG_NAMESPACE:$SITE --user=infinispan-operator -n $DG_NAMESPACE || true

TOKEN_SECRET=$(kubectl get serviceaccount/$SITE -n $DG_NAMESPACE -o json | jq -r ".secrets[] | select(.name|test(\"$SITE-token.\")) | .name")
TOKEN=$(kubectl get secret $TOKEN_SECRET -o jsonpath='{.data.token}' -n $DG_NAMESPACE | base64 --decode)
mkdir -p tokens/$SITE
echo $TOKEN > tokens/$SITE/token

