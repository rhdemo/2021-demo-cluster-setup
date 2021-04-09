#!/usr/bin/env bash

printf "\n\n######## backend/deploy ########\n"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

oc project battleships-backend 2> /dev/null || oc new-project battleships-backend

printf "Creating broker..."
oc apply -f $DIR/broker.yaml

printf "Creating triggers..."
oc apply -f $DIR/attackevent/trigger-attack.yaml
oc apply -f $DIR/bonusevent/trigger-bonus.yaml
oc apply -f $DIR/matchend/trigger-match-end.yaml
oc apply -f $DIR/matchstart/trigger-match-start.yaml

printf "Creating functions"
kn service create attack --image quay.io/ilawson/attack --env SCORINGSERVICE=http://scoring-service.battleships-scoring.svc.cluster.local:8080/ --env WATCHMAN=http://watchman.battleships-backend.svc.cluster.local:8080/watch --env CARRIER_SCORE=250 --env DESTROYER_SCORE=50 --env SUBMARINE_SCORE=100 --env BATTLESHIP_SCORE=200 --env HIT_SCORE=5 --env PRODMODE=production
kn service create bonus --image quay.io/ilawson/bonus --env SCORINGSERVICE=http://scoring-service.battleships-scoring.svc.cluster.local:8080/ --env WATCHMAN=http://watchman.battleships-backend.svc.cluster.local:8080/watch --env BONUS_SCORE=1 --env PRODMODE=production
kn service create matchend --image quay.io/ilawson/matchend --env SCORINGSERVICE=http://scoring-service.battleships-scoring.svc.cluster.local:8080/ --env WATCHMAN=http://watchman.battleships-backend.svc.cluster.local:8080/watch --env PRODMODE=production
kn service create matchstart --image quay.io/ilawson/matchstart  --env SCORINGSERVICE=http://scoring-service.battleships-scoring.svc.cluster.local:8080/ --env WATCHMAN=http://watchman.battleships-backend.svc.cluster.local:8080/watch --env PRODMODE=production


