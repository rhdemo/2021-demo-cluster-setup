#!/bin/sh

function header_text {
  echo "$header$*$reset"
}

apply() {
  #out=$(echo "$1" | oc apply -f - 2>&1)
  out=$(echo "$1" | oc apply -f - )
  header_text $out
}

apply_project() {
  project=$1
  set +e
  oc get project $project >/dev/null 2>&1
  rc="$?"
  set -e
  if [ "$rc" -ne "0" ]; then
    header_text "* Creating namespace $project"
    oc new-project $project >/dev/null
  fi
}

# Check that resource exists before start waiting
wait_for_deployments_to_be_created() {
  while true; do
    set +e
    #oc get -n openshift-operators deployment $@ >/dev/null 2>&1
    oc get -n $1 deployment ${@:2} >/dev/null 2>&1
    rc=$?
    set -e
    if [ $rc -eq 0 ]; then
      return
    fi
    sleep 2
  done
}

wait_for_operators() {
  operators="$@"
  #run_with_timeout 60 wait_for_deployments_to_be_created $operators
  sleep 15
  wait_for_deployments_to_be_created openshift-operators $operators
  for operator in $operators; do
    out=$(oc wait deploy/$operator -n openshift-operators --for=condition=Available --timeout 60s >/dev/null)
    header_text "$out"
  done
}

wait_for_all_deployments() {
  ns=$1
  sleep 15
  out=""
  # Doing this in a loop to prevent exiting with an error when there is no deployment created yet.
  while true; do
    set +e
    echo "Waiting for deployments in namespace $ns"
    out=$(oc wait deployment --all --timeout=-1s --for=condition=Available -n "$ns" 2>&1)
    rc=$?
    set -e
    if [ $rc -eq 0 ]; then
      echo "Waiting for deployment finished successfully!"
      return
    else
        echo "Got an error, trying again.!"
    fi
    sleep 5
  done
  header_text $out
}