#!/usr/bin/env bash

printf "\n\n######## downloading logs ########\n"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT=${PROJECT:-frontend}
DOWNLOAD_DIR=${DOWNLOAD_DIR:-/tmp}
DATE=$(date +"%Y-%m-%dT%H:%M")
DOWNLOAD_DEST="${DOWNLOAD_DIR}/${DATE}"
CLUSTER_DIR="$(echo ${CLUSTER_NAME} | sed 's/ /_/g')"

oc project ${PROJECT}

download_logs() {
  local PODS=$(oc get pods | grep "${1}" |  grep -v 'deploy' | awk '{print $1}')
  local DIR="${DOWNLOAD_DEST}/${CLUSTER_DIR}/${1}"

  mkdir -p "${DIR}"
  for POD in $PODS
  do
    oc logs $POD > "${DIR}/${POD}.log"
  done
}

download_logs 'game-server'
download_logs 'game-ui'
download_logs 'admin'