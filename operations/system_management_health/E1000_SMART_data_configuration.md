# Retrieve SMART data from ClusterStor E1000 nodes via Redfish Exporter

This is a Prometheus Exporter for extracting metrics from a server using the Redfish API. The hostname of the server has to be passed as target parameter in the http call.

All these steps need to be followed post install/upgrade CSM services.

## Configure domain name for ClusterStor management node

NOTE: The below steps needs to be performed on the ClusterStor E1000 node.

In order to provide SMART data to the `prometheus` time series database, the Redfish Exporter must be configured with domain name from ClusterStor primary management node.

1. Find the `ip address` of both mgmt nodes on the external access network (EAN) of ClusterStor.

    1. If static EAN IP addresses are configured on the mgmt nodes in the, following command will show what they are:

        ```bash
        [root@kjcf01n00 ~]# cscli ean ipaddr show
        ```

       Example Output:

        ```text
        ---------------------------------------------------
        Node       Network       Interface  IP ADDRESS
        ---------------------------------------------------
        kjcf01n00  EAN           pub0       172.30.53.54
        kjcf01n01  EAN           pub0       172.30.53.55
        ---------------------------------------------------
        ```

    1. If static IP addresses have not been configured on the mgmt nodes in the cluster, and the `cscli ean ipaddr show` command returns empty, as seen below:

        ```bash
        [root@kjlmo1200 ~]# cscli ean ipaddr show
        ```

       Example Output:

        ```text
        empty
        ```

       1. Check what the primary EAN interface name is with the following command:

           ```bash
           [root@kjlmo1200 ~]# cscli ean primary show
           ```

          Example Output:

           ```text
           Interface: pub0
             Prefix:
             Gateway:
           Added EAN primary interfaces:
           pub0
           Free interfaces:
           pub0
           pub1
           pub2
           pub3
           ```

           This output indicates that the primary EAN interface is pub0, this is the default primary EAN interface on ClusterStor mgmt nodes. If no static IP address is set on this interface, it will default to DHCP.

           Check the IP address of this interface on both mgmt nodes with the following command:

            ```bash
            [root@kjlmo1200 ~]# pdsh -g mgmt ip a l pub0 | dshbak -c
            ```

           Example Output:

            ```text
            ----------------
            kjlmo1200
            ----------------
            2: pub0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
                link/ether b4:96:91:02:73:0c brd ff:ff:ff:ff:ff:ff
                altname enp8s0f0
                inet 10.214.135.37/21 brd 10.214.135.255 scope global dynamic pub0
                   valid_lft 80500sec preferred_lft 80500sec
            ----------------
            kjlmo1201
            ----------------
            2: pub0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
                link/ether b4:96:91:03:10:74 brd ff:ff:ff:ff:ff:ff
                altname enp22s0f0
                inet 10.214.135.45/21 brd 10.214.135.255 scope global dynamic pub0
                   valid_lft 77093sec preferred_lft 77093sec
            ```

1. Get the FQDN of each mgmt node from the primary EAN `ip addresses` found on each using `nslookup`.

    ```bash
    [root@kjlmo1200 ~]# nslookup 10.214.135.37
    ```

   Example Output:

    ```text
    37.135.214.10.in-addr.arpa  name = kjlmo1200.hpc.amslabs.hpecorp.net.
    ```

    ```bash
    [root@kjlmo1200 ~]# nslookup 10.214.135.45
    ```

   Example Output:

    ```text
    45.135.214.10.in-addr.arpa   name = kjlmo1201.hpc.amslabs.hpecorp.net.
    ```

1. Determine which mgmt nodes is currently the primary mgmt node.

   The RFSF API services run on the primary mgmt node in the ClusterStor SMU. To determine which node is currently the primary mgmt node, look at `cscli show_nodes` output:

   ```bash
   [root@kjlmo1200 ~]# cscli show_nodes
   ```

   Example Output:

   ```text
   ----------------------------------------------------------------------------------------
   Hostname   Role         Power State  Service State  Targets  HA Partner  HA Resources
   ----------------------------------------------------------------------------------------
   kjlmo1200  MGMT         On           N/a            0 / 0    kjlmo1201   None
   kjlmo1201  (MGMT)       On           N/a            0 / 0    kjlmo1200   None
   kjlmo1202  (MDS),(MGS)  On           Stopped        0 / 1    kjlmo1203   Local
   kjlmo1203  (MDS),(MGS)  On           Stopped        0 / 1    kjlmo1202   Local
   kjlmo1204  (OSS)        On           Stopped        0 / 3    kjlmo1205   Local
   kjlmo1205  (OSS)        On           Stopped        0 / 3    kjlmo1204   Local
   ----------------------------------------------------------------------------------------
   ```

   NOTE: The MGMT node where Role is NOT surrounded by parentheses is the current primary MGMT node `(kjlmo1200 above)`.
   This is also the node that can run `cscli`, so that is another indication of which node is primary vs. secondary. If a node is failed over, the output changes as follows:

   ```bash
   [root@kjlmo1200 ~]# cscli show_nodes
   ```

   Example Output:

   ```text
   ---------------------------------------------------------------------------------------- 
   Hostname   Role         Power State  Service State  Targets  HA Partner  HA Resources
   ----------------------------------------------------------------------------------------
   kjlmo1200  (MGMT)       On           N/a            0 / 0    kjlmo1201   None
   kjlmo1201  MGMT         On           N/a            0 / 0    kjlmo1200   None
   kjlmo1202  (MDS),(MGS)  On           Stopped        0 / 1    kjlmo1203   Local
   kjlmo1203  (MDS),(MGS)  On           Stopped        0 / 1    kjlmo1202   Local
   kjlmo1204  (OSS)        On           Stopped        0 / 3    kjlmo1205   Local
   kjlmo1205  (OSS)        On           Stopped        0 / 3    kjlmo1204   Local
   ----------------------------------------------------------------------------------------
   ```

1. Select the FQDN of the primary mgmt node to use as your RFSF API connection destination.

   The FQDN of the primary EAN `ip address` discovered above on the primary mgmt node is the FQDN that should be used to connected to the RFSF API.

    The primary EAN `ip address` discovered above on the secondary node should be used in the case of a failover on the mgmt nodes that causes the secondary node to become the primary.

## Create admin user `(LDAP instance)` on ClusterStor E1000 primary mgmt node

NOTE: The below steps needs to be performed on the ClusterStor E1000 node.

1. Add an admin user on primary management node discovered in the above section.

   ```bash
   cscli admins add --username abcxyz --role full --password Abcxyz@123
   ```

   NOTE: Password should have minimum length of 8 characters with minimum 1 lowercase alphabet, 1 uppercase alphabet, 1 alpha numeric and 1 special character.

1. View the created admins user.

   ```bash
   cscli admins list
   ```

   Output will look similar to:

   ```text
   ---------------------------------------------------------------
   Username   Role      Uid   SSH Enabled  Web Enabled  Policy
   ---------------------------------------------------------------
   abcxyz     full      1503     True         True      default
   ---------------------------------------------------------------
   ```

## Create `Configmap` with FQDN of the primary mgmt node

NOTE: The below steps needs to be performed on the CSM cluster either on master or worker node.

1. (`ncn-mw#`) Check if `configmap` `cray-sysmgmt-health-redfish` already exists.

    ```bash
    kubectl get cm -n sysmgmt-health cray-sysmgmt-health-redfish
    ```

   Example Output:

    ```text
    NAME                          DATA   AGE
    cray-sysmgmt-health-redfish   1      15d
    ```

1. (`ncn-mw#`) Delete the existing `configmap`.

    ```bash
    kubectl delete cm -n sysmgmt-health cray-sysmgmt-health-redfish --force
    ```

1. (`ncn-mw#`) Create a `configmap` file `/tmp/configmap.yml` with the below content and replace TARGET with site specific FQDN of the primary mgmt node from the above section in the second last line.
   For example, `TARGET=abc100.xyz.com`.

    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      annotations:
        meta.helm.sh/release-name: cray-sysmgmt-health
        meta.helm.sh/release-namespace: sysmgmt-health
      name: cray-sysmgmt-health-redfish
      namespace: sysmgmt-health
      labels:
        app.kubernetes.io/instance: cray-sysmgmt-health
        app.kubernetes.io/managed-by: Helm
        app.kubernetes.io/name: redfish-exporter
        app.kubernetes.io/version: 0.11.0
        release: cray-sysmgmt-health
    data:
      fetch_health.sh: |
        #!/bin/bash

        TARGET=""
        curl -o /tmp/redfish-smart-1.prom cray-sysmgmt-health-redfish-exporter.sysmgmt-health.svc:9220/health?target=${TARGET}
    ```
  
    NOTE: In case `ClusterStor` has more than one or multiple primary management node then multiple targets and curl commands can be used. The above script file `fetch_health.sh` under data section will look similar to:
  
    ```yaml
    data:
      fetch_health.sh: |
        #!/bin/bash

        TARGET1=""
        curl -o /tmp/redfish-smart-1.prom cray-sysmgmt-health-redfish-exporter.sysmgmt-health.svc:9220/health?target=${TARGET1}
        TARGET2=""
        curl -o /tmp/redfish-smart-1.prom cray-sysmgmt-health-redfish-exporter.sysmgmt-health.svc:9220/health?target=${TARGET2}
        .
        .
        .
        TARGETN=""
        curl -o /tmp/redfish-smart-1.prom cray-sysmgmt-health-redfish-exporter.sysmgmt-health.svc:9220/health?target=${TARGETN}
    ```

1. (`ncn-mw#`) Apply the above file to create a `configmap` in `sysmgmt-health` namespace.

    ```bash
    kubectl apply -f /tmp/configmap.yml -n sysmgmt-health
    ```

1. (`ncn-mw#`) Verify if the `configmap` is created or not.

    ```bash
    kubectl get configmap -n sysmgmt-health | grep redfish
    ```

   Example Output:

    ```text
    cray-sysmgmt-health-redfish                                    1      1m
    ```

## Configure Username and Password for Redfish Exporter

LDAP instance - Username and Password created on ClusterStor primary management node in the above step will be used here to configure Redfish Exporter.

This procedure can be performed on any master or worker NCN.

1. (`ncn-mw#`) Save the current redfish-exporter configuration, in case a rollback is needed.

    ```bash
    kubectl get secret -n sysmgmt-health cray-sysmgmt-health-redfish-exporter \         
         -ojsonpath='{.data.config\.yml}' | base64 --decode > /tmp/config-default.yaml
    ```

1. (`ncn-mw#`) Create a secret and an redfish-exporter configuration that will be used to add ClusterStor user LDAP instance credential.

    1. Create the secret file.

        Create a file named `/tmp/redfish-secret.yaml` with the following contents:

         ```yaml
         apiVersion: v1
         data:
           config.yml: REDFISH_CONFIG
         kind: Secret
         metadata:
           labels:
             app.kubernetes.io/instance: cray-sysmgmt-health
             app.kubernetes.io/managed-by: Helm
             app.kubernetes.io/name: redfish-exporter
             app.kubernetes.io/version: 0.11.0
             helm.sh/chart: redfish-exporter-0.1.1
             release: cray-sysmgmt-health
           name: cray-sysmgmt-health-redfish-exporter
           namespace: sysmgmt-health
         type: Opaque
         ```

    1. Create the alert configuration file.

        Create a file named `/tmp/redfish-new.yaml` with the following contents:

         ```yaml
         listen_port: 9220
         timeout: 30
         username: "abcdef"
         password: "Abcd@123"
         rf_port: 8081
         ```

        NOTE: In the following example file, the `rf_port` is for the NEO RFSF API main RESTful server (by default it is set to 8081) and `listen_port` is the redfish-exporter port. Update `username`, `password` to reflect the desired configuration.

1. (`ncn-mw#`) Replace the redfish-exporter configuration based on the files created in the previous steps.

    ```bash
    sed "s/REDFISH_CONFIG/$(cat /tmp/redfish-new.yaml \
                | base64 -w0)/g" /tmp/redfish-secret.yaml \
                | kubectl replace --force -f -
    ```

1. (`ncn-mw#`) Validate the configuration changes.

    1. Get the redfish-exporter pod in `sysmgmt-health` namespace.

        ```bash
        kubectl get pods -n sysmgmt-health | grep redfish
        ```

       Example output:

        ```text
        cray-sysmgmt-health-redfish-exporter-86f7596c5-g6lxl            1/1     Running     0                3h25m
        ```

    1. View the current configuration after few minutes.

        ```bash
        kubectl exec cray-sysmgmt-health-redfish-exporter-86f7596c5-g6lxl \
                -n sysmgmt-health -c redfish-exporter -- cat /config/config.yml
        ```

    1. If the configuration does not look accurate, check the logs for errors.

        ```bash
        kubectl logs -f -n sysmgmt-health pod/cray-sysmgmt-health-redfish-exporter-86f7596c5-g6lxl
        ```

1. (`ncn-mw#`) Delete the redfish-exporter pod so that latest configuration is picked up.

    1. Delete the redfish-exporter pod.

        ```bash
        kubectl delete pod -n sysmgmt-health cray-sysmgmt-health-redfish-exporter-86f7596c5-g6lxl --force
        ```

    1. Valdiate the pod is running again after sometime.

        ```bash
        kubectl get pod -n sysmgmt-health | grep redfish
        ```

Metrics Information:

The SMART data in `prometheus` format would look like:

```text
smartmon_temperature_celsius_raw_value{disk="/dev/sdk",host="kjlmo900.hpc.amslabs.hpecorp.net",endpoint="metrics", instance="10.252.1.6:9100", job="node-exporter", namespace="sysmgmt-health", pod="cray-sysmgmt-health-prometheus-node-exporter-74fd8",redfish_instance="10.214.132.198:9220",type="sas"} 33.0
smartmon_power_cycle_count_raw_value{disk="/dev/sdk",host="kjlmo900.hpc.amslabs.hpecorp.net"endpoint="metrics", instance="10.252.1.6:9100", job="node-exporter", namespace="sysmgmt-health", pod="cray-sysmgmt-health-prometheus-node-exporter-74fd8",redfish_instance="10.214.132.198:9220",type="sas"} 0.0
smartmon_power_on_hours_raw_value{disk="/dev/sdk",host="kjlmo900.hpc.amslabs.hpecorp.net"endpoint="metrics", instance="10.252.1.6:9100", job="node-exporter", namespace="sysmgmt-health", pod="cray-sysmgmt-health-prometheus-node-exporter-74fd8",redfish_instance="10.214.132.198:9220",type="sas"} 30531.0
smartmon_smartctl_run{disk="/dev/sdk",host="kjlmo900.hpc.amslabs.hpecorp.net"endpoint="metrics", instance="10.252.1.6:9100", job="node-exporter", namespace="sysmgmt-health", pod="cray-sysmgmt-health-prometheus-node-exporter-74fd8",redfish_instance="10.214.132.198:9220",type="sas"} 1.715076005e+09
smartmon_device_active{disk="/dev/sdm",host="kjlmo900.hpc.amslabs.hpecorp.net",endpoint="metrics", instance="10.252.1.6:9100", job="node-exporter", namespace="sysmgmt-health", pod="cray-sysmgmt-health-prometheus-node-exporter-74fd8",edfish_instance="10.214.132.198:9220",type="sas"} 1.0
```

NOTE: In the above metrics example `redfish_instance` is the `E1000` node primary management name IP address and instance is the master/worker node IP address where redfish-exporter pod is scheduled.
In case of open source `grafana` dashboards, instance in the `grafana` dashboards variable needs to be replaced with `redfish_instance` to get the `E1000` SMART data.
