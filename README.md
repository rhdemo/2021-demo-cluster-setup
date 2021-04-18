# Deployment for 2021

## Requirements

* OpenShift Cluster 4.6+
* OpenShift CLI (`oc`)
* Knative CLI (`kn`)
* Make

## Usage

### 1. Create an Environment File

Copy the `.env.example` into a file named `.env`. This will be used by the
various scripts to inject variables into their deployments.

The `OC_` variables require a token and cluster API URL. This is the target
OpenShift cluster that services will be deployed onto.

```
OC_URL=https://the-cluster.openshiftapps.com:6443
OC_TOKEN=sha256~thisis-atoken-itsrandom # to be used instead of OC_USER and OC_PASSWORD
```

The cluster name is important for a multi-cluster demo. It will be used to
tag outgoing payloads, i.e data sent to an off-cluster Kafka instance will
be tagged as being from the "Americas" cluster.

```
CLUSTER_NAME="Americas"
```

Variables used to connect to the (possibly external) Kafka service.

```
KAFKA_SVC_USERNAME=srvc-acct-xxx-yyy-zzz-123
KAFKA_BOOTSTRAP_URL=some-name-abc.kafka.devshift.org:443
KAFKA_SVC_PASSWORD=1pass2goes-here-abcd-1b743
```

This controls Node.js application behaviours. Specifically, the game WebSocket
Server will send game records to S3 (if AWS variables are defined), enable trace
logging, and enable player vs. player matches if this is set to "dev"

```
NODE_ENV="prod"
AWS_ACCESS_KEY_ID=abc123
AWS_SECRET_ACCESS_KEY=123+abc
```

The admin application is used to control game state, e.g for dramatic pause
during a demo. This is protected via basic authentication with a username and
password.

```
ADMIN_USERNAME=admin
ADMIN_PASSWORD=secretsauce
```

### 2. Deploy the Services

Make is used to deploy everything. It's important that Data Grid is deployed
prior to the backend and frontend components.

```
make datagrid && \
make serverless && \
make backend && \
make ai && \
make kafka-forwarder \
make frontend
```

### 3. Deploy Kafka Streams

This service only needs to be deployed in a single cluster since it aggregates
data from all of the clusters.

If using a Kafka instance with self-signed certificates you'll need to copy a
trustore containing the certificate to the *kafka-streams/* folder.

_NOTE: All *jks* files in the repo are ignored by gitignore._

```bash
cp $PATH_TO_A_TRUSTSTORE kafka-streams/truststore.jks
```

Update the *.env* with `TRUSTSTORE_PASSWORD` set to the password for the
*truststore.jks* you copied, then run:


```
make kafka-streams
```

### 4. Deploy the Dashboard

This is similar to the Kafka Streams applications. Only needs to be deployed into a single cluster.

Find the HTTP URLs for the Kafka Streams applications deployed in the previous section, set them in the .env like so:

```
DASHBOARD_REPLAY_SERVER=https://kafka-streams.app.some-cluster.com
DASHBOARD_GAME_SERVER=https://other-kafka-streams.app.some-cluster.com
```

Now run the deployment:

```
make dashboard
```
