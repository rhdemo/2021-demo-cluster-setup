# Datagrid Service
Scripts to install Infinispan 12.0.x in the `datagrid` project.

## Default Configuration
- Uses Infinispan 12.0.x Operator
- Distributed mode
    - Each key/value is distributed across two nodes

## Endpoints
- HOTROD & REST
    - service = datagrid

All services can be reached directly via:
`datagrid.datagrid.svc.cluster.local`

## Cache Configurations
Additional cache/counter configurations can be added to the `config/batch*` files.

## Additional libraries
Additional jars can be added to the Infinispan `server/lib` directory by adding them to the local `libs` folder and creating a custom server image via `make cluster/image`.

## Deployment
`make deploy DG_NAMESPACE=<namespace>`

>Default DG_NAMESPACE=datagrid

## Teardown
`make clean DG_NAMESPACE=<namespace>`

## Xsite Deployment
1. Create tokens for all of the clusters
    - OC Login to AWS cluster
    - `make cluster/xsite/tokens DG_LOCAL_SITE=AWS DG_NAMESPACE=datagrid`
    - OC Login to GCP cluster
    - `make cluster/xsite/tokens DG_LOCAL_SITE=AWS DG_NAMESPACE=datagrid`

2. Create token secrets on each cluster
    - OC login to each cluster
    - `make cluster/xsite/secrets DG_NAMESPACE=datagrid`

3. Deploy cluster and caches on each cluster
    - OC Login to AWS cluster
    - `make operator/install cluster/xsite/deploy DG_LOCAL_SITE=AWS DG_NAMESPACE=datagrid`
    - OC Login to GCP cluster
    - `make operator/install cluster/xsite/deploy DG_LOCAL_SITE=GCP DG_NAMESPACE=datagrid`

4. Wait for the xsite view to form (can be either cluster)
    - `oc logs datagrid-0 -f`
    - The logs should contain `[org.infinispan.XSITE] ISPN000439: Received new x-site view: [AWS, GCP]`

5. Deploy the caches on each of the clusters
    - OC Login to AWS cluster
    - `make caches/xsite/deploy DG_REMOTE_SITE=GCP DG_NAMESPACE=datagrid`
    - OC Login to GCP cluster
    - `make caches/xsite/deploy DG_REMOTE_SITE=AWS DG_NAMESPACE=datagrid`