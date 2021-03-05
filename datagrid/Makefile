DG_NAMESPACE=datagrid
DG_REPLICAS=2


.PHONY: operator/namespace
operator/namespace:
	@kubectl create namespace $(DG_NAMESPACE) || true
	@which oc 2>/dev/null ; if [ $$? -eq 0 ]; then \
		oc project $(DG_NAMESPACE) || true; \
	fi

.PHONY: operator/install
operator/install: operator/namespace
	@kubectl label namespace $(DG_NAMESPACE) monitoring-key=middleware || true
	@oc label namespace $(DG_NAMESPACE) "openshift.io/cluster-monitoring=true" || true
	@kubectl apply -f operator/install/crds/ || true
	# TODO replace with OLM subscription operator/install/subscription.yaml when issues resolved upstream
	@sed -e '/# Replace/{n;s/.*/  namespace: $(DG_NAMESPACE)/}' operator/install/operator-install.yaml | kubectl apply -n $(DG_NAMESPACE) -f -

	@for i in {1..30}; do kubectl wait --for condition=established --timeout=60s crd/infinispans.infinispan.org -n $(DG_NAMESPACE) && break || sleep 1; done

.PHONY: cluster/libs
cluster/libs:
	@kubectl -n $(DG_NAMESPACE) apply -f operator/libs-pvc.yaml
	@kubectl -n $(DG_NAMESPACE) apply -f operator/libs-pod.yaml
	@kubectl -n $(DG_NAMESPACE) wait --for=condition=ready pod/datagrid-lib-pod
	@kubectl -n $(DG_NAMESPACE) cp libs datagrid-lib-pod:/tmp/
	@kubectl -n $(DG_NAMESPACE) delete pod datagrid-lib-pod

.PHONY: cluster/deploy
cluster/deploy: cluster/libs
	@kubectl apply -f operator/infinispan.yaml -n $(DG_NAMESPACE)
	@for i in {1..30}; do kubectl rollout status statefulset datagrid -n $(DG_NAMESPACE) && break || sleep 1; done

.PHONY: caches/deploy
caches/deploy:
	@kubectl -n $(DG_NAMESPACE) cp config datagrid-0:/tmp/config
	@kubectl -n $(DG_NAMESPACE) exec datagrid-0 -- /opt/infinispan/bin/cli.sh -c http://datagrid-0:11222 --file=/tmp/config/batch

.PHONY: deploy
deploy: operator/install cluster/deploy caches/deploy

.PHONY: clean
clean:
	@kubectl delete crd caches.infinispan.org || true
	@kubectl delete crd infinispans.infinispan.org || true
	@kubectl delete namespace $(DG_NAMESPACE) || true
