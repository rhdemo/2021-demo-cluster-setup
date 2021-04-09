oc project battleships-leaderboard 2> /dev/null || oc new-project battleships-leaderboard

oc new-app quay.io/redhatdemo/2021-leaderboard-service --name="leaderboard-service" --as-deployment-config=true --env="QUARKUS_INFINISPAN_CLIENT_SERVER_LIST=datagrid.datagrid.svc.cluster.local:11222"
oc apply -f leaderboard-route.yaml