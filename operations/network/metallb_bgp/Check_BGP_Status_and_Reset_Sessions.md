# Check BGP Status and Reset Sessions

Check the Border Gateway Protocol \(BGP\) status on the Aruba and Mellanox switches and verify that all sessions are in an Established state.
If the state of any session in the table is Idle, the BGP sessions must be reset.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

### MELLANOX

1. Verify that all BGP sessions are in an `ESTABLISHED` state for the Mellanox spine switches.

    SSH to each spine switch to check the status of all BGP sessions.

    1. SSH to a spine switch.

        For example:

        ```bash
        ncn-m001# ssh admin@sw-spine-001.mtl
        ```

    1. View the status of the BGP sessions.

        ```text
        sw-spine-001 [standalone: master] > enable
        sw-spine-001 [standalone: master] # show ip bgp summary
        ```

        Example output:

        ```text
        VRF name                  : default
        BGP router identifier     : 10.252.0.2
        local AS number           : 65533
        BGP table version         : 50
        Main routing table version: 50
        IPV4 Prefixes             : 68
        IPV6 Prefixes             : 0
        L2VPN EVPN Prefixes       : 0
        
        ------------------------------------------------------------------------------------------------------------------
        Neighbor          V    AS           MsgRcvd   MsgSent   TblVer    InQ    OutQ   Up/Down       State/PfxRcd
        ------------------------------------------------------------------------------------------------------------------
        10.252.1.10       4    65533        3144      3564      50        0      0      1:01:50:41    ESTABLISHED/13
        10.252.1.11       4    65533        3144      3569      50        0      0      1:01:50:40    ESTABLISHED/14
        10.252.1.12       4    65533        3145      3576      50        0      0      1:01:50:41    ESTABLISHED/14
        10.252.1.13       4    65533        3144      3568      50        0      0      1:01:50:41    ESTABLISHED/13
        10.252.1.14       4    65533        3145      3572      50        0      0      1:01:50:41    ESTABLISHED/14
        ```

        If any of the sessions are in an `IDLE` state, proceed to the next step.

1. Reset BGP to re-establish the sessions.

    <a name="mellanox-ssh"></a>

    1. SSH to each spine switch.

        For example:

        ```bash
        ncn-m001# ssh admin@sw-spine-001.mtl
        ```

    1. Verify that BGP is enabled.

        ```text
        sw-spine-001 [standalone: master] > show protocols | include bgp
         bgp:                    enabled
        ```

    1. Clear the BGP sessions.

        ```text
        sw-spine-001 [standalone: master] > enable
        sw-spine-001 [standalone: master] # clear ip bgp all
        ```

    1. Check the status of the BGP sessions to see if they are now `ESTABLISHED`.

        It may take a few minutes for sessions to become `ESTABLISHED`.

        ```text
        sw-spine-001 [standalone: master] > enable
        sw-spine-001 [standalone: master] # show ip bgp summary
        ```

        Example output:

        ```text
        VRF name                  : default
        BGP router identifier     : 10.252.0.2
        local AS number           : 65533
        BGP table version         : 50
        Main routing table version: 50
        IPV4 Prefixes             : 68
        IPV6 Prefixes             : 0
        L2VPN EVPN Prefixes       : 0
        
        ------------------------------------------------------------------------------------------------------------------
        Neighbor          V    AS           MsgRcvd   MsgSent   TblVer    InQ    OutQ   Up/Down       State/PfxRcd
        ------------------------------------------------------------------------------------------------------------------
        10.252.1.10       4    65533        3144      3564      50        0      0      1:01:50:41    ESTABLISHED/13
        10.252.1.11       4    65533        3144      3569      50        0      0      1:01:50:40    ESTABLISHED/14
        10.252.1.12       4    65533        3145      3576      50        0      0      1:01:50:41    ESTABLISHED/14
        10.252.1.13       4    65533        3144      3568      50        0      0      1:01:50:41    ESTABLISHED/13
        10.252.1.14       4    65533        3145      3572      50        0      0      1:01:50:41    ESTABLISHED/14
        ```

    Once all sessions are in an `ESTABLISHED` state, BGP reset is complete for the Mellanox switches.

    **Troubleshooting:** If some sessions remain `IDLE`, then re-run the Mellanox reset steps to clear and re-check status.
    If some sessions still remain `IDLE`, then proceed to [reapply the `cray-metallb` helm chart](#reapply), along with the BGP reset,
    in order to force the speaker pods to re-establish sessions with the switch.

### Aruba

1. Verify that all BGP sessions are in an `Established` state for the Aruba spine switches.

    SSH to each spine switch to check the status of all BGP sessions.

    1. SSH to a spine switch.

        ```bash
        ncn-m001# ssh admin@sw-spine-001.mtl
        ```

    1. View the status of the BGP sessions.

        ```text
        sw-spine-001# show bgp ipv4 unicast summary
        ```

        Example output:

        ```text
        VRF : default
        BGP Summary
        -----------
         Local AS               : 65533        BGP Router Identifier  : 10.252.0.2
         Peers                  : 4            Log Neighbor Changes   : No
         Cfg. Hold Time         : 180          Cfg. Keep Alive        : 60
         Confederation Id       : 0

         Neighbor        Remote-AS MsgRcvd MsgSent   Up/Down Time State        AdminStatus
         10.252.0.3      65533       19704   19708   00m:01w:00d  Established   Up
         10.252.1.10     65533       34455   39416   00m:01w:04d  Established   Up
         10.252.1.11     65533       34458   39400   00m:01w:04d  Established   Up
         10.252.1.12     65533       34448   39415   00m:01w:04d  Established   Up
        ```

        If any of the sessions are in an `Idle` state, proceed to the next step.

1. Reset BGP to re-establish the sessions.

    <a name="aruba-ssh"></a>

    1. SSH to each spine switch.

        For example:

        ```bash
        ncn-m001# ssh admin@sw-spine-001.mtl
        ```

    1. Clear the BGP sessions.

        ```text
        sw-spine-001# clear bgp *
        ```

    1. Check the status of the BGP sessions.

        It may take a few minutes for sessions to become `Established`.

        ```text
        sw-spine-001# show bgp ipv4 unicast summary
        ```

        Example output:

        ```text
        VRF : default
        BGP Summary
        -----------
         Local AS               : 65533        BGP Router Identifier  : 10.252.0.2
         Peers                  : 4            Log Neighbor Changes   : No
         Cfg. Hold Time         : 180          Cfg. Keep Alive        : 60
         Confederation Id       : 0

         Neighbor        Remote-AS MsgRcvd MsgSent   Up/Down Time State        AdminStatus
         10.252.0.3      65533       19704   19708   00m:01w:00d  Established   Up
         10.252.1.10     65533       34455   39416   00m:01w:04d  Established   Up
         10.252.1.11     65533       34458   39400   00m:01w:04d  Established   Up
         10.252.1.12     65533       34448   39415   00m:01w:04d  Established   Up
        ```

    Once all sessions are in an `Established` state, BGP reset is complete for the Aruba switches.

    **Troubleshooting:** If some sessions remain `Idle`, then re-run the Aruba reset steps to clear and re-check status.
    If some sessions still remain `Idle`, then proceed to the next step to reapply the `cray-metallb` helm chart, along with the
    BGP reset, in order to force the speaker pods to re-establish sessions with the switch.

<a name="reapply"></a>

1. Determine the `cray-metallb` chart version that is currently deployed.

    ```bash
    ncn-m001# helm ls -A -a | grep cray-metallb
    ```

    Example output:

    ```text
    cray-metallb   metallb-system   1   2021-02-10 14:58:43.902752441 -0600 CST  deployed  cray-metallb-0.12.2   0.8.1
    ```

1. Create a manifest file that will be used to reapply the same chart version.

    ```console
    ncn-m001# cat << EOF > ./metallb-manifest.yaml
    apiVersion: manifests/v1beta1
    metadata:
      name: reapply-metallb
    spec:
      charts:
      - name: cray-metallb
        namespace: metallb-system
        values:
          imagesHost: dtr.dev.cray.com
        version: 0.12.2
    EOF
    ```

1. Open SSH sessions to all spine switches.

1. Determine the `CSM_RELEASE` version that is currently running and set an environment variable.

    For example:

    ```bash
    ncn-m001# CSM_RELEASE=0.8.0
    ```

1. Mount the `PITDATA` so that helm charts are available for the re-install \(it might already be mounted\) and verify that the chart with the expected version exists.

    ```bash
    ncn-m001# mkdir -pv /mnt/pitdata && mount -L PITDATA /mnt/pitdata && \
              ls /mnt/pitdata/csm-${CSM_RELEASE}/helm/cray-metallb*
    ```

    Example output:

    ```text
    /mnt/pitdata/csm-0.8.0/helm/cray-metallb-0.12.2.tgz
    ```

1. Uninstall the current `cray-metallb` chart.

    Until the chart is reapplied, this will also affect unbound name resolution, and all BGP sessions will be Idle for all of the worker nodes.

    ```bash
    ncn-m001# helm del cray-metallb -n metallb-system
    ```

1. Use the open SSH sessions to the switches to clear the BGP sessions based on the above Mellanox or Aruba procedures.

    * Refer to substeps [1-3](#mellanox-ssh) for Mellanox.
    * Refer to substeps [1-2](#aruba-ssh) for Aruba.

1. Reapply the `cray-metallb` chart based on the `CSM_RELEASE`.

    ```bash
    ncn-m001# loftsman ship --manifest-path ./metallb-manifest.yaml \
                --charts-path /mnt/pitdata/csm-${CSM_RELEASE}/helm
    ```

1. Check that the speaker pods are all running.

    This may take a few minutes.

    ```bash
    ncn-m001# kubectl get pods -n metallb-system
    ```

    Example output:

    ```text
    NAME                                       READY   STATUS    RESTARTS   AGE
    cray-metallb-controller-6d545b5ccc-mm4qz   1/1     Running   0          79m
    cray-metallb-speaker-4nrzq                 1/1     Running   0          76m
    cray-metallb-speaker-b5m2n                 1/1     Running   0          79m
    cray-metallb-speaker-h7s7b                 1/1     Running   0          79m
    ```

1. Use the open SSH sessions to the switches to check the status of the BGP sessions.

    * Refer to substeps [1-3](#mellanox-ssh) for Mellanox.
    * Refer to substeps [1-2](#aruba-ssh) for Aruba.
