## Clear HSM Tables to Resolve DHCP Issues

In some instances, the Hardware State Manager \(HSM\) ethernetInterfaces and redfishEndpoints tables need to be cleared to correct various issues with the DHCP service. After clearing the table, the Data Virtualization Service \(DVS\) and Slurm will need to be reconfigured to account for the IP address changes.

**CAUTION:** This process might have other implications and should only be used when service suggests it be done.

### Prerequisites

-   Dynamic Host Configuration Protocol \(DHCP\) is experiencing issues.
-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.
-   The admin is authenticated with the Cray CLI.

### Procedure

1.  Scale the resources for the `cray-dhcp-kea`, `cray-meds`, `cray-reds`, and `cray-dns-unbound` deployments to 0.

    ```bash
    ncn-w001# kubectl -n services scale --replicas=0 deployments/cray-dhcp-kea
    deployment.apps/cray-dhcp-kea scaled
    ncn-w001# kubectl -n services scale --replicas=0 deployments/cray-meds
    deployment.apps/cray-meds scaled
    ncn-w001# kubectl -n services scale --replicas=0 deployments/cray-reds
    deployment.apps/cray-reds scaled
    ncn-w001# kubectl -n services scale --replicas=0 deployments/cray-dns-unbound
    deployment.apps/cray-dns-unbound scaled
    ```

2.  Clear the redfishEndpoints table.

    ```bash
    ncn-w001# cray hsm inventory redfishEndpoints clear
    This will delete all redfish endpoints in HSM, continue? [y/N]: y
    message = "deleted 15 entries"
    code = 0
    ```

3.  Clear the ethernetInterfaces table.

    ```bash
    ncn-w001# cray hsm inventory ethernetInterfaces clear
    This will delete all component ethernet interfaces, continue? [y/N]: y
    message = "deleted 69 entries"
    code = 0
    ```

4.  Clear the current Domain Name Service \(DNS\) configuration.

    ```bash
    ncn-w001# kubectl -n services patch configmaps cray-dns-unbound \
    --type merge -p '{"data":{"records.json":"[]"}}'
    ncn-w001# systemctl restart nscd.service
    ```

    Wait about five minutes before proceeding to the next step to allow any current DHCP leases to expire.

5.  Scale the resources for the `cray-dhcp-kea`, `cray-meds`, and `cray-reds` deployments back up to 1, and the `cray-dns-unbound` deployment back up to 2.

    ```bash
    ncn-w001# kubectl -n services scale --replicas=1 deployments/cray-dhcp-kea
    deployment.apps/cray-dhcp-kea scaled
    ncn-w001# kubectl -n services scale --replicas=1 deployments/cray-meds
    deployment.apps/cray-meds scaled
    ncn-w001# kubectl -n services scale --replicas=1 deployments/cray-reds
    deployment.apps/cray-reds scaled
    ncn-w001# kubectl -n services scale --replicas=2 deployments/cray-dns-unbound
    deployment.apps/cray-dns-unbound scaled
    ```

    After a few minutes, the DHCP leases should settle and the DNS names should start resolving. Proceed to the next step to check the state of the DNS resolution for the BMCS.

6.  Check the state of the DNS resolution for the BMCs.

    Use the following script to check the state of the DNS resolution. If using a PDF, copy the script from the PDF and paste it into a neutral text editor. After pasting to a neutral text editor, copy the command from the neutral form and paste it into the console to ensure the spacing and indentation are correct.

    ```bash
    for b in $(cray hsm state components list --type NodeBMC --format=json | jq --raw-output \
    '.Components[] | .ID' | sort)
    do
        nslookup $b > /dev/null
        if [ $? -eq 0 ]
        then
          echo "$b resolved."
        else
          echo "$b did NOT resolve!"
        fi
    done
    ```

    An IP address should be associated with each BMC. If any records say did NOT resolve!, DNS hasn't been updated for that BMC yet.

    The output will look similar to the following while DNS is still coming up:

    ```bash
    x3000c0s11b0 did NOT resolve!
    x3000c0s13b0 did NOT resolve!
    x3000c0s15b0 did NOT resolve!
    x3000c0s17b0 did NOT resolve!
    x3000c0s19b1 did NOT resolve!
    x3000c0s19b2 did NOT resolve!
    x3000c0s19b3 did NOT resolve!
    x3000c0s19b4 did NOT resolve!
    x3000c0s1b0 did NOT resolve!
    x3000c0s26b0 did NOT resolve!
    x3000c0s30b1 did NOT resolve!
    x3000c0s30b2 did NOT resolve!
    x3000c0s30b3 did NOT resolve!
    x3000c0s30b4 did NOT resolve!
    x3000c0s32b1 did NOT resolve!
    x3000c0s32b2 did NOT resolve!
    x3000c0s3b0 did NOT resolve!
    x3000c0s5b0 did NOT resolve!
    x3000c0s7b0 resolved.
    x3000c0s9b0 did NOT resolve!
    ```

    After a few minutes, the output should look similar to the example below:

    ```bash
    x3000c0s11b0 resolved.
    x3000c0s13b0 resolved.
    x3000c0s15b0 resolved.
    x3000c0s17b0 resolved.
    x3000c0s19b1 resolved.
    x3000c0s19b2 resolved.
    x3000c0s19b3 resolved.
    x3000c0s19b4 resolved.
    x3000c0s1b0 resolved.
    x3000c0s26b0 resolved.
    x3000c0s30b1 resolved.
    x3000c0s30b2 resolved.
    x3000c0s30b3 resolved.
    x3000c0s30b4 resolved.
    x3000c0s32b1 resolved.
    x3000c0s32b2 resolved.
    x3000c0s3b0 resolved.
    x3000c0s5b0 resolved.
    x3000c0s7b0 resolved.
    x3000c0s9b0 resolved.
    ```

7.  Reconnect ConMan to the consoles.

    ```bash
    ncn-w001# kubectl -n services rollout restart deployment cray-conman
    ```

8.  Clear DVS on the NCNs.

    1.  Restart the cps-cm-pm pods.

        Wait a few minutes after deleting the pods so they have time to unload and reload DVS.

        ```bash
        ncn-w001# kubectl delete pods -n services -l app.kubernetes.io/name=cm-pm 
        ```

    2.  Verify the DVS module is loaded on the NCNs running the cps-cm-pm pods.

        ```bash
        ncn-w001# kubectl get pods -Ao wide | grep cps-cm-pm
        services    cray-cps-cm-pm-9np9f       5/5     Running       0     11m     10.36.0.79    ncn-w001   <none>     <none>
        services    cray-cps-cm-pm-mf6q7       5/5     Running       0     11m     10.42.0.50    ncn-w003   <none>     <none>
        services    cray-cps-cm-pm-s54gd       5/5     Running       0     11m     10.39.0.102   ncn-w002   <none>     <none>
        
        ncn-w001# pdsh -w ncn-w00[1-3] 'lsmod | grep "^dvs "'
        ncn-w002: dvs                   405504  0
        ncn-w003: dvs                   405504  0
        ncn-w001: dvs                   405504  0
        ```

9.  Reconfigure Slurm after the IP address changes.

    1.  Restart the slurmctld deployment.

        ```bash
        ncn-w001# kubectl rollout restart -n user deployment slurmctld
        ```

    2.  Verify the pods are running after restarting slurmctld.

        ```bash
        ncn-w001# kubectl get pods -A | grep slurmctld
        user      slurmctld-99c455dfd-zmkgq      3/3     Running        0      16m
        ```


When attempting to boot after following this procedure, the boot will need to be performed twice. The boot hangs and will fail the first time a boot is attempted after this procedure is performed. The failure will look similar to the following:

```bash
dracut-initqueue[457]: DVS: node map generated.
dracut-initqueue[457]: DVS: loaded dvsproc module.
dracut-initqueue[457]: DVS: loaded dvs module.
dracut-initqueue[457]: mount is: /opt/cray/cps-utils/bin/cpsmount.sh -a api-gw-service-nmn.local -t dvs -T 300 -i eth0 -e 2f1cf59408e77f76a0efefa608c93689-171 s3://boot-images/df16be69-60c8-42c2-bbff-2a6769e8bd85/rootfs /tmp/cps
```

Issuing a second boot attempt immediately after the first failed boot attempt will resolve the issue.



