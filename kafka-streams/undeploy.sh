PROJECT=${PROJECT:-kafka-streams}

printf "\n\n######## $PROJECT/undeploy ########\n"

oc delete project $PROJECT
oc delete trigger/kafka-forwarder-match-start -n battleships-backend
oc delete trigger/kafka-forwarder-attack -n battleships-backend
oc delete trigger/kafka-forwarder-match-end -n battleships-backend