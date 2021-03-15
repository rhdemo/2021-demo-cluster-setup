# Datagrid Service
Scripts to install Infinispan 12.0.x in the `datagrid-demo` project.

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
Additional jars can be added to the Infinispan `server/lib` directory by placing them in the local `libs` folder before calling `make deploy`

## Deployment
`make deploy DG_NAMESPACE=<namespace>`

>Default DG_NAMESPACE=datagrid

## Teardown
`make clean DG_NAMESPACE=<namespace>`
