# Spire Service Recovery

The following covers redeploying the Spire service and restoring the data.

## Prerequisites

- The system is fully installed and has transitioned off of the LiveCD.
- All activities required for site maintenance are complete.
- The latest CSM documentation has been installed on the master nodes. See [Check for Latest Documentation](../../update_product_stream/README.md#check-for-latest-documentation).
- The Cray CLI has been configured on the node where the procedure is being performed. See [Configure the Cray CLI](../configure_cray_cli.md).

## Service recovery for Spire

1. (`ncn-mw#`) Uninstall the `spire` and `cray-spire` charts and wait for the resources to terminate.

   1. Note the version of the `spire` chart that is currently deployed.

      ```bash
      helm history -n spire spire
      ```

      Example output:

      ```text
      REVISION	UPDATED                 	STATUS  	CHART       	APP VERSION	DESCRIPTION
      1       	Wed Nov 15 12:41:47 2023	deployed	spire-2.14.2	0.12.2     	Install complete
      ```

   1. Uninstall the `spire` chart.

      ```bash
      helm uninstall -n spire spire
      ```

      Example output:

      ```text
      release "spire" uninstalled
      ```

   1. Note the version of the `cray-spire` chart that is currently deployed.

      ```bash
      helm history -n spire cray-spire
      ```

      Example output:

      ```text
      REVISION	UPDATED                 	STATUS  	CHART           	APP VERSION	DESCRIPTION
      1       	Wed Nov 15 12:41:50 2023	deployed	cray-spire-1.5.4	1.5.5      	Install complete
      ```

   1. Uninstall the `cray-spire` chart.

      ```bash
      helm uninstall -n spire cray-spire
      ```

      Example output:

      ```text
      release "cray-spire" uninstalled
      ```

   1. Wait for the resources to terminate, delete the PVCs, and clean up `spire-agent` before reinstalling the charts.

      1. Verify that only `tpm-provisioner` pods (or no pods) are running in `spire` namespace.

         ```bash
         watch "kubectl get pods -n spire"
         ```

         Example output:

         ```text
         NAME                                          READY   STATUS    RESTARTS      AGE
         tpm-provisioner-0                             2/2     Running   0             17d
         ```

      1. Delete the Spire server PVCs.

         ```bash
         kubectl get pvc -n spire | grep spire-server | awk '{print $1}' | xargs kubectl delete -n spire pvc
         ```

         Example output:

         ```text
         persistentvolumeclaim "data-cray-spire-server-0" deleted
         persistentvolumeclaim "data-cray-spire-server-1" deleted
         persistentvolumeclaim "data-cray-spire-server-2" deleted
         persistentvolumeclaim "spire-data-spire-server-0" deleted
         persistentvolumeclaim "spire-data-spire-server-1" deleted
         persistentvolumeclaim "spire-data-spire-server-2" deleted
         ```

      1. Clean up `spire-agent`.

         ```bash
         for ncn in $(kubectl get nodes -o name | cut -d'/' -f2); do
             echo "Cleaning up NCN ${ncn}"
             ssh "${ncn}" systemctl stop spire-agent
             ssh "${ncn}" rm -v /var/lib/spire/data/keys.json /var/lib/spire/agent_svid.der /var/lib/spire/bundle.der
         done
         ```

1. (`ncn-mw#`) Redeploy the `spire` and `cray-spire` charts and wait for the resources to start.

   1. Follow the [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) procedure to redeploy the `spire` chart:

      - Name of chart to be redeployed: `spire`
      - Base name of manifest: `sysmgmt`
      - When reaching the step to update customizations, no edits need to be made to the customizations file.

   1. Repeat the above procedure for the `cray-spire` chart:

      - Name of chart to be redeployed: `cray-spire`
      - Base name of manifest: `sysmgmt`

   1. Wait for the resources to start.

      ```bash
      watch "kubectl get pods -n spire"
      ```

      Example output:

      ```text
      NAME                                          READY   STATUS    RESTARTS       AGE
      cray-spire-agent-7w6tc                        1/1     Running   0              10m
      cray-spire-agent-b6754                        1/1     Running   0              10m
      cray-spire-agent-pxqmq                        1/1     Running   0              10m
      cray-spire-agent-rxsbf                        1/1     Running   0              10m
      cray-spire-jwks-76f48d6484-b72jf              3/3     Running   0              10m
      cray-spire-jwks-76f48d6484-v5b5n              3/3     Running   0              10m
      cray-spire-jwks-76f48d6484-xgnxw              3/3     Running   0              10m
      cray-spire-postgres-0                         3/3     Running   0              10m
      cray-spire-postgres-1                         3/3     Running   0              10m
      cray-spire-postgres-2                         3/3     Running   0              10m
      cray-spire-postgres-pooler-86797d8b9b-p2nkf   2/2     Running   0              10m
      cray-spire-postgres-pooler-86797d8b9b-rfvr8   2/2     Running   0              10m
      cray-spire-postgres-pooler-86797d8b9b-t9xwt   2/2     Running   0              10m
      cray-spire-server-0                           2/2     Running   0              10m
      cray-spire-server-1                           2/2     Running   0              10m
      cray-spire-server-2                           2/2     Running   0              10m
      request-ncn-join-token-4hgnt                  2/2     Running   0              15m
      request-ncn-join-token-67qlz                  2/2     Running   0              15m
      request-ncn-join-token-75q2l                  2/2     Running   0              15m
      request-ncn-join-token-d24wv                  2/2     Running   0              15m
      request-ncn-join-token-q56zm                  2/2     Running   0              15m
      request-ncn-join-token-tmz4l                  2/2     Running   0              15m
      request-ncn-join-token-z87pl                  2/2     Running   0              15m
      spire-agent-42gb2                             1/1     Running   0              15m
      spire-agent-6lxv9                             1/1     Running   0              15m
      spire-agent-hhbqm                             1/1     Running   0              15m
      spire-agent-sztjm                             1/1     Running   0              15m
      spire-jwks-6cd9d5b5b5-6bmcb                   3/3     Running   0              15m
      spire-jwks-6cd9d5b5b5-gz2tl                   3/3     Running   0              15m
      spire-jwks-6cd9d5b5b5-pds25                   3/3     Running   0              15m
      spire-postgres-0                              3/3     Running   0              15m
      spire-postgres-1                              3/3     Running   0              15m
      spire-postgres-2                              3/3     Running   0              15m
      spire-postgres-pooler-75964fbc66-6hvvq        2/2     Running   0              15m
      spire-postgres-pooler-75964fbc66-d52mg        2/2     Running   0              15m
      spire-postgres-pooler-75964fbc66-nm6v6        2/2     Running   0              15m
      spire-server-0                                2/2     Running   0              15m
      spire-server-1                                2/2     Running   0              15m
      spire-server-2                                2/2     Running   0              15m
      tpm-provisioner-0                             2/2     Running   0              17d
      ```

   1. Rejoin the storage nodes to Spire and restart the `spire-agent` on all NCNs.

      ```bash
      /opt/cray/platform-utils/spire/fix-spire-on-storage.sh
      for i in $(kubectl get nodes -o name | cut -d"/" -f2) $(ceph node ls | jq -r '.[] | keys[]' | sort -u); do ssh $i systemctl start spire-agent; done
      ```
