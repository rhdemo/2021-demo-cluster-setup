#!/bin/bash
oc delete all,secrets,sa,templates,configmaps,daemonsets,clusterroles,rolebindings,routes,serviceaccounts --selector=template=datagrid-service
oc delete configmap datagrid-configuration
oc get pvc -o name | xargs -r -n1 oc delete
