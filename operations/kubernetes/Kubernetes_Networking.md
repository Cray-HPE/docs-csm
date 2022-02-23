## Kubernetes Networking

Every Kubernetes pod has an IP address in the pod network that is reachable within the cluster. The system uses the `weave-net` plugin for inter-node communication.

### Access services from outside the cluster

All services with a REST API must be accessed from outside the cluster using the Istio Ingress Gateway. This gateway can be accessed using a URL in the following format:

```
https://api.cmn.SYSTEM-NAME_DOMAIN-NAME
https://api.can.SYSTEM-NAME_DOMAIN-NAME
https://api.chn.SYSTEM-NAME_DOMAIN-NAME
```

The API requests then get routed to the appropriate node running that service.

### Access services from within the cluster

All services running inside the cluster can access each other using their Pod IP address or the service's cluster IP address, along with the service's exposed port. The exception to this is a service that has a Cray REST API. These services are configured such that they must be accessed through the API gateway service.

### Network Policies

Kubernetes supports network policies to limit access to pods. Therefore, services running inside the cluster generally cannot access each other using their Pod IP address or the service's cluster IP address. Any other services that must be accessed through a protocol other than REST, can do so using the cluster VIP and the service's NodePort. Only services that are configured to expose a NodePort or ExternalIP can be accessed from outside the cluster.

As part of the SMS installation, the following network policies are configured on the system:

- `keycloak-database`: Allows only `keycloak` to access the `keycloak` Postgres instance
- `sma-zookeeper`: Allows only Apache Kafka to access the SMA Zookeeper instance
- `sma-postgres`: Allows only Grafana to access the SMA Postgres instance
- `hms-mariadb`: Allows only SMD to access the MariaDB instance
- `hms-badger`: Allows only badger services to access the badger Postgres instance
- `api-gateway-database`: Allows only the API gateway to access the API gateway Postgres instance
- `api-gateway-upstream`: Allows only the API gateway to access the upstream services
- `vcs-database`: Allows only Gitea to access the VCS instance

To learn more about Kubernetes, refer to [https://kubernetes.io/](https://kubernetes.io/).
