DG_DEMO_IMAGE=quay.io/redhatdemo/datagrid:2021
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
	@sed -e "s/NAMESPACE/$(DG_NAMESPACE)/g" operator/install/subscription.yaml | oc apply -n $(DG_NAMESPACE) -f -

.PHONY: cluster/image
cluster/image:
	@docker build . -t $(DG_DEMO_IMAGE)
	@docker push $(DG_DEMO_IMAGE)

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
