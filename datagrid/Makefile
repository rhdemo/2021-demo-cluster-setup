DG_NAMESPACE=datagrid
DG_REPLICAS=2


.PHONY: operator/namespace
operator/namespace:
	@oc new-project $(DG_NAMESPACE) || true
	@which oc 2>/dev/null ; if [ $$? -eq 0 ]; then \
		oc project $(DG_NAMESPACE) || true; \
	fi

.PHONY: operator/install
operator/install: operator/namespace
	@oc apply -f operator/install/subscription.yaml || true

.PHONY:
cluster/libs:
	@oc -n $(DG_NAMESPACE) apply -f operator/libs-pvc.yaml
	@oc -n $(DG_NAMESPACE) apply -f operator/libs-pod.yaml
	@oc -n $(DG_NAMESPACE) wait --for=condition=ready --timeout=2m pod/datagrid-lib-pod
	@oc -n $(DG_NAMESPACE) cp --no-preserve=true libs datagrid-lib-pod:/tmp/
	@oc -n $(DG_NAMESPACE) delete pod datagrid-lib-pod

.PHONY: cluster/deploy
cluster/deploy:
	@oc -n $(DG_NAMESPACE) apply -f operator/infinispan.yaml
	@for i in {1..30}; do oc rollout status statefulset datagrid -n $(DG_NAMESPACE) && break || sleep 1; done

.PHONY: caches/deploy
caches/deploy:
	@oc -n $(DG_NAMESPACE) create configmap datagrid-batch --from-file=config/
	@oc -n $(DG_NAMESPACE) apply -f operator/batch.yaml

.PHONY: deploy
deploy: operator/install cluster/deploy caches/deploy

.PHONY: clean
clean:
	@oc delete project $(DG_NAMESPACE) || true
