oc project battleships-scoring 2> /dev/null || oc new-project battleships-scoring

oc apply -f backend/scoring-dc.yaml
oc apply -f backend/scoring-route.yaml
