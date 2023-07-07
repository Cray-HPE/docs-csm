# Re-Installation

This page details steps to take prior to starting new installation, these pages assume that all
the NCNs have been deployed (e.g. there is no more PIT node).

## Topics

1. [Quiesce compute and application nodes](#quiesce-application-and-compute-nodes)
1. [Disable DHCP service](#disable-dhcp-service)
1. [Set IPMI credentials](#set-ipmi-credentials)
1. [Power off booted nodes](#power-off-booted-nodes)
1. [Set node BMCs to DHCP](#set-node-bmcs-to-dhcp)
1. [Power off the PIT node](#power-off-pit-node)
1. [Configure DNS](#configure-dns)
1. [Check disk space](#check-disk-space)

## Quiesce application and compute nodes

> **`NOTE`** Skip this section if compute nodes and application nodes are not booted.

The application and compute nodes must be shutdown prior to a reinstallation. If they are left on, then they will
potentially end up in an undesirable state.

See [Shut Down and Power Off Compute and User Access Nodes](../operations/power_management/Shut_Down_and_Power_Off_Compute_and_User_Access_Nodes.md).

## Disable DHCP service

> **`NOTE`** Skip this section if the CSM install was incomplete or not started.

The DHCP service running in Kubernetes needs to be disabled or it will conflict with the PIT's DHCP services.

(`ncn-mw#`) Disable `cray-dhcp-kea`

```bash
kubectl scale -n services --replicas=0 deployment cray-dhcp-kea
```

## Set IPMI credentials

The upcoming procedures use `ipmitool`. Set IPMI credentials for the BMCs of the NCNs.

> `read -s` is used in order to prevent the credentials from being displayed on the screen or recorded in the shell history.

1. (`ncn#` or `pit#`) Set the username and IPMI password:

   ```bash
   username=root
   read -r -s -p "NCN BMC ${username} password: " IPMI_PASSWORD
   ```

1. (`ncn#` or `pit#`) Export `IPMI_PASSWORD` for the `-E` option to work on `ipmitool`:

   ```bash
   export IPMI_PASSWORD
   ```

## Power off booted nodes

> **`NOTE`** Skip this section if none of the management nodes are booted.

Power each NCN off using `ipmitool` from `ncn-m001` (or the PIT node, if reinstalling an incomplete install).

1. Get the inventory of BMCs.

   - (`pit#`) From the PIT:

      ```bash
      readarray -t BMCS < <(conman -q | grep -v m001 | sort -u)
      ```

   - (`ncn#`) From an NCN (e.g. `ncn-m001`):

      ```bash
      readarray BMCS < <(grep mgmt /etc/hosts | awk '{print $NF}' | grep -v m001 | sort -u)
      ```

1. (`ncn#` or `pit#`) Power off NCNs.

    ```bash
    printf "%s\n" ${BMCS[@]} | xargs -t -i ipmitool -I lanplus -U "${username}" -E -H {} power off
    ```

1. (`ncn#` or `pit#`) Check the power status to confirm that the nodes have powered off.

    ```bash
    printf "%s\n" ${BMCS[@]} | xargs -t -i ipmitool -I lanplus -U "${username}" -E -H {} power status
    ```

## Set node BMCs to DHCP

During the install of the management nodes, their BMCs get set to static IP addresses. The installation expects these
BMCs to be set back to DHCP before proceeding.

> **`NOTE`** These steps require that the **[Set IPMI credentials](#set-ipmi-credentials)** steps have been performed.

1. Get the inventory of BMCs.

   - (`pit#`) From the PIT:

      ```bash
      readarray -t BMCS < <(conman -q | grep -v m001 | sort -u)
      ```

   - (`ncn#`) From an NCN (e.g. `ncn-m001`):

      ```bash
      readarray BMCS < <(grep mgmt /etc/hosts | awk '{print $NF}' | grep -v m001 | sort -u)
      ```

1. Set the BMCs to DHCP.

   ```bash
   function bmcs_set_dhcp {
      local lan=1
      for bmc in ${BMCS[@]}; do
         # by default the LAN for the BMC is lan channel 1, except on Intel systems.
         if ipmitool -I lanplus -U "${username}" -E -H "${bmc}" lan print 3 2>/dev/null; then
            lan=3
         fi
         printf "Setting %s to DHCP ... " "${bmc}"
         if ipmitool -I lanplus -U "${username}" -E -H "${bmc}" lan set "${lan}" ipsrc dhcp; then
            echo "Done"
         else
            echo "Failed!"
         fi
      done
   }
   bmcs_set_dhcp
   ```

1. Perform a cold reset of any BMCs which are still reachable.

    ```bash
   function bmcs_cold_reset {
      for bmc in ${BMCS[@]}; do
         printf "Setting %s to DHCP ... " "${bmc}"
         if ipmitool -I lanplus -U "${username}" -E -H "${bmc}" mc reset cold; then
            echo "Done"
         else
            echo "Failed!"
         fi
      done
   }
   bmcs_cold_reset
   ```

   > **`NOTE`** As long as every BMC is either not reachable or receives a cold reset, this step is successful.

## Power off PIT node

> **`NOTE`** Skip this step if planning to use this node as a staging area to create the USB LiveCD.

1. (`ncn-m001#` or `pit#`) Shut down the LiveCD or `ncn-m001` node.

   ```bash
   poweroff
   ```

The process is now done; the NCNs are ready for a new deployment.

## Configure DNS

If `ncn-m001` is being used to prepare the USB LiveCD, then remove the Kubernetes IP addresses from `/etc/resolv.conf` and add a
valid external DNS server.

## Check disk space

If `ncn-m001` is being used to prepare the USB LiveCD, then ensure that there is enough free disk space for the CSM tar archive to be
downloaded and unpacked.

## Next topic

See [Boot installation environment](csm-install/README.md#2-boot-installation-environment).
