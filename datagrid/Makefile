DG_DEMO_IMAGE=quay.io/redhatdemo/datagrid:2021
DG_NAMESPACE=
DG_LOCAL_SITE=
DG_REMOTE_SITE=


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
	@oc -n $(DG_NAMESPACE) apply -f operator/datagrid.yaml
	@for i in {1..30}; do oc rollout status statefulset datagrid -n $(DG_NAMESPACE) && break || sleep 1; done

.PHONY: caches/deploy
caches/deploy:
	@sed -e '/CACHE_CONFIG/ {' -e 'r ./operator/game-cache-xsite.xml' -e 'd' -e '}' ./operator/cache-cr-template.yaml | sed "s/CACHE_NAME/game/g" | oc apply -n $(DG_NAMESPACE) -f - ;
	@oc -n $(DG_NAMESPACE) create configmap datagrid-batch --from-file=config/
	@oc -n $(DG_NAMESPACE) apply -f operator/batch.yaml
	@sed -e '/CACHE_CONFIG/ {' -e 'r ./operator/index-cache.xml' -e 'd' -e '}' ./operator/cache-cr-template.yaml | sed "s/CACHE_NAME/players-shots/g; s/INDEXED_ENTITY/com.redhat.Shot/g;" | oc apply -n $(DG_NAMESPACE) -f -
	@sed -e '/CACHE_CONFIG/ {' -e 'r ./operator/index-cache.xml' -e 'd' -e '}' ./operator/cache-cr-template.yaml | sed "s/CACHE_NAME/players-scores/g; s/INDEXED_ENTITY/com.redhat.PlayerScore/g;" | oc apply -n $(DG_NAMESPACE) -f -


.PHONY: cluster/xsite/tokens
cluster/xsite/tokens: operator/namespace
	@export DG_NAMESPACE DG_LOCAL_SITE
	@./operator/createSiteToken.sh


.PHONY: cluster/xsite/secrets
cluster/xsite/secrets:
	@oc create secret generic aws-token --from-literal=token=$(shell cat tokens/aws/token) -n $(DG_NAMESPACE)
	@oc create secret generic gcp-token --from-literal=token=$(shell cat tokens/gcp/token) -n $(DG_NAMESPACE)

.PHONY: cluster/xsite/deploy
cluster/xsite/deploy:
	@sed -e "s/SITE_NAME/$(shell echo $(DG_LOCAL_SITE) | tr [a-z] [A-Z])/g" operator/datagrid-xsite.yaml | oc apply -n $(DG_NAMESPACE) -f -

.PHONY: caches/xsite/deploy
caches/xsite/deploy:
	@sed -e '/CACHE_CONFIG/ {' -e 'r ./operator/game-cache-xsite.xml' -e 'd' -e '}' ./operator/cache-cr-template.yaml | sed "s/CACHE_NAME/game/g; s/BACKUP_SITE/$(DG_REMOTE_SITE)/g" | oc apply -n $(DG_NAMESPACE) -f - ;
	@oc -n $(DG_NAMESPACE) create configmap datagrid-batch --from-file=config/
	@oc -n $(DG_NAMESPACE) apply -f operator/batch.yaml
	@sed -e '/CACHE_CONFIG/ {' -e 'r ./operator/index-cache-xsite.xml' -e 'd' -e '}' ./operator/cache-cr-template.yaml | sed "s/CACHE_NAME/players-shots/g; s/INDEXED_ENTITY/com.redhat.Shot/g; s/BACKUP_SITE/$(DG_REMOTE_SITE)/g" | oc apply -n $(DG_NAMESPACE) -f - ;
	@sed -e '/CACHE_CONFIG/ {' -e 'r ./operator/index-cache-xsite.xml' -e 'd' -e '}' ./operator/cache-cr-template.yaml | sed "s/CACHE_NAME/players-scores/g; s/INDEXED_ENTITY/com.redhat.PlayerScore/g; s/BACKUP_SITE/$(DG_REMOTE_SITE)/g" | oc apply -n $(DG_NAMESPACE) -f - ;

.PHONY: deploy
deploy: operator/install cluster/deploy caches/deploy

.PHONY: clean
clean:
	@oc delete project $(DG_NAMESPACE) || true
