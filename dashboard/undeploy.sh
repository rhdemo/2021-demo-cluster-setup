#!/usr/bin/env bash

printf "\n\n######## dashboard/undeploy ########\n"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT=${PROJECT:-battleships-dashboard}

oc delete project ${PROJECT}