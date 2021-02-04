# Datagrid Service
Scripts to install DG 8.0 in the `datagrid-demo` project.

## Default Configuration
- Uses Infinispan 10.1.3.Final upstream image
- Distributed mode
    - Each key/value is distributed across two nodes
- Entries stored off-heap

## Endpoints
- HOTROD & REST
    - service = datagrid-service

All services can be reached directly via:
`datagrid-service.datagrid-demo.svc.cluster.local`

## Cache Configurations
Additional cache/counter configurations can be added to the `config/batch*` files.

## Deployment

### Normal Clusters
A Data grid cluster can be installed by executing the `./datagrid.sh` script. An optional int argument can be passed in
order to specify the number of pods in the cluster, the default value being 2.

### Failover and Backup Cluster
In order to replicate the London to Frankfurt failover seen in the 2020 demo, it's necessary for one cluster to be nominated as
the `FAILOVER_SITE` (London) and another as the `BACKUP_SITE` (Frankfurt).

1. The `./deployBackup.sh` script needs to be executed on the cluster nominated as the backup
2. Execute `oc get svc/datagrid-service-external` and take note of the EXTERNAL-IP
3. Update the `config/distributed-off-heap-*-failover.xml` files replacing `##BACKUP_SITE_IP##` with the EXTERNAL-IP value
4. Deploy to the failover site using the `./deployFailover.sh` script.

## Teardown
Execute `./teardown.sh` to undeploy all Openshift resources on a cluster.
