oc new-app infinispan/server:12.0.1.Final --name=infinispan --env="USER=admin" --env="PASS=pass" --as-deployment-config=true
oc new-app quay.io/redhatdemo/2021-scoring-service --name="scoring-service" --as-deployment-config=true --env="QUARKUS_INFINISPAN_CLIENT_SERVER_LIST=infinispan:11222"

(Create the routes for the Infinispan console and the scoring service (8080))
add --env="LEADERBOARD_CONFIGURE_INFINISPAN=true" to pre-populate the caches
