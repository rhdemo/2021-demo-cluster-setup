#!/usr/bin/env bash

printf "\n\n######## backend/undeploy ########\n"

oc delete project battleships-backend
oc delete project battleships-scoring
oc delete project battleships-leaderboard