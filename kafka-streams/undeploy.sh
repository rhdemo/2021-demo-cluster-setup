PROJECT=${PROJECT:-kafka-streams}

printf "\n\n######## $PROJECT/undeploy ########\n"

oc delete project $PROJECT