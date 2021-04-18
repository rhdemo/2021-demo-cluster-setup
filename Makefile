ENV_FILE := .env
include ${ENV_FILE}
export $(shell sed 's/=.*//' ${ENV_FILE})

# NOTE: the actual commands here have to be indented by TABs
.PHONY: oc_login
oc_login:
ifdef OC_TOKEN
	$(info **** Using OC_TOKEN for login ****)
	oc login ${OC_URL} --token=${OC_TOKEN}
else
	$(info **** Using OC_USER and OC_PASSWORD for login ****)
	oc login ${OC_URL} -u ${OC_USER} -p ${OC_PASSWORD} --insecure-skip-tls-verify=true
endif

datagrid: oc_login
	@$(MAKE) -C datagrid deploy

datagrid-undeploy: oc_login
	./datagrid/teardown.sh

ai: oc_login
	./ai/deploy.sh

ai-undeploy: oc_login
	./ai/undeploy.sh

frontend: oc_login
	./frontend/deploy.sh

frontend-undeploy: oc_login
	./frontend/undeploy.sh

kafka-forwarder: oc_login
	./kafka-forwarder/deploy.sh

kafka-forwarder-undeploy: oc_login
	./kafka-forwarder/undeploy.sh

kafka-streams: oc_login
	./kafka-streams/deploy.sh

kafka-streams-undeploy: oc_login
	./kafka-streams/undeploy.sh

backend: oc_login
	./backend/deploy.sh
	./backend/leaderboard-service.sh
	./backend/scoring-service.sh

backend-undeploy: oc_login
	./backend/undeploy.sh

dashboard: oc_login
	./dashboard/deploy.sh

dashboard-undeploy: oc_login
	./dashboard/undeploy.sh

serverless: oc_login
	./backend/kafkabroker.sh
