# Troubleshoot Compute Node Boot Issues Related to Slow Boot Times

> **`NOTE`** This section is for Boot Orchestration Service (BOS) v1 only. BOS v2 does not use
> [Cray Advanced Platform Monitoring and Control (CAPMC)](../../glossary.md#cray-advanced-platform-monitoring-and-control-capmc),
> nor does it have the Boot Orchestration Agent (BOA). However, the steps
> outlined below allow for similar debugging of slow steps within
> [Configuration Framework Service \(CFS\)](../../glossary.md#configuration-framework-service-cfs)-initiated sessions.

Inspect BOS, BOA, and CFS job logs in order to
obtain information that is critical for boot troubleshooting. Use this procedure to determine why compute nodes are
booting slower than expected.

## Prerequisites

- A boot session has been created with BOS.
- The Cray CLI is configured. See [Configure the Cray CLI](../configure_cray_cli.md).

## Procedure

1. (`ncn-mw#`) View the BOA logs.

    1. Find the BOA job from the boot session.

        The output of the command below is organized by the creation time of the BOA job with the most recent one listed last.

        ```bash
        kubectl -nservices --sort-by=.metadata.creationTimestamp get pods | grep boa
        ```

        Example output:

        ```text
        boa-e3c845be-3092-4807-a0c9-272bf0e15896-7pnl4              0/2     Completed   0        3d
        boa-c740f74d-f5af-41f3-a71b-1a3fc00cbe7a-k5hdw              0/2     Completed   0        2d12h
        boa-a365b6a2-3614-4b53-9b6b-df0f4485e25d-nbcdb              0/2     Completed   0        2m43s
        ```

    1. Watch the log from BOA job.

        ```bash
        kubectl logs -n services -f -c boa BOA_JOB_ID
        ```

        Example output:

        ```text
        2019-11-12 02:14:27,771 - DEBUG   - cray.boa - BOA starting

        2019-11-12 02:14:28,786 - DEBUG   - cray.boa - Boot Agent Image: acad2b43-dff5-483d-a392-8b1b1f91a60c Nodes: x5000c1s1b1n0, x3000c0s35b2n0, x5000c1s3b1n1, x3000c0s35b3n0, x5000c1s0b1n0, x5000c1s3b0n1, x5000c1s2b0n0, x5000c1s3b1n0, x5000c1s1b1n1, x5000c1s2b0n1, x3000c0s35b1n0, x5000c1s3b0n0, x5000c1s0b1n1, x5000c1s1b0n0, x5000c1s2b1n0, x5000c1s1b0n1, x5000c1s2b1n1 created.
        2019-11-12 02:14:29,118 - INFO    - cray.boa - Boot Session: 88df3fc3-6697-41cc-9f63-7076d78a9110

        2019-11-12 02:14:29,505 - DEBUG   - cray.boa.logutil - cray.boa.agent.reboot called with  args: (Boot Agent Image: acad2b43-dff5-483d-a392-8b1b1f91a60c Nodes: x5000c1s1b1n0, x3000c0s35b2n0, x5000c1s3b1n1, x3000c0s35b3n0, x5000c1s0b1n0, x5000c1s3b0n1, x5000c1s2b0n0, x5000c1s3b1n0, x5000c1s1b1n1, x5000c1s2b0n1, x3000c0s35b1n0, x5000c1s3b0n0, x5000c1s0b1n1, x5000c1s1b0n0, x5000c1s2b1n0, x5000c1s1b0n1, x5000c1s2b1n1,)
        2019-11-12 02:14:29,505 - INFO    - cray.boa.agent - Rebooting the Session: 88df3fc3-6697-41cc-9f63-7076d78a9110 Set: computes

        2019-11-12 02:15:15,898 - DEBUG   - cray.boa.logutil - cray.boa.dbclient.db_write_session called with  args: (<etcd3.client.Etcd3Client object at 0x7f822db68dd8>, '88df3fc3-6697-41cc-9f63-7076d78a9110', 'computes', 'status', 'boot_capmc_finished')
        2019-11-12 02:15:15,898 - DEBUG   - cray.boa.dbclient - Key: /session/88df3fc3-6697-41cc-9f63-7076d78a9110/computes/status/ Value: boot_capmc_finished
        2019-11-12 02:15:15,938 - INFO    - cray.boa.smd.wait_for_nodes -
        Standby: 17 entries
        2019-11-12 02:15:15,938 - INFO    - cray.boa.smd.wait_for_nodes - Waiting 5 seconds for 17 nodes to be in state: Ready

        [...]
        ```

1. (`ncn-mw#`) View the CFS logs related to the boot job.

    1. Find the most recent CFS jobs.

        There may be more than one job if multiple components are being configured. If there are multiple different CFS
        jobs running, check CFS first to find the timestamp value when CFS was updated. Expect a delay of a couple
        minutes after the CFS session starts depending on the `cfs-batcher` settings.

        ```bash
        kubectl -n services get cfs
        ```

        Example output:

        ```text
        NAME                                           JOB                                        STATUS    SUCCEEDED   REPOSITORY CLONE URL                                               BRANCH   COMMIT                                     PLAYBOOK                            AGE
        066bc062-7fc3-11ea-970e-a4bf0138f2ba           cfs-1628cf85-e847-49af-891c-1b7655d8056d   complete   true        https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git   master                                              site.yml                            4d10h
        3c3758a8-7fd9-11ea-a365-a4bf0138f2ba           cfs-05420ebf-fbbc-4d3a-a0af-a840e379fe12   complete   true        https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git   master                                              site.yml                            4d8h
        batcher-65f94609-0599-4d86-a8ad-9555d2a9ab9d   cfs-b10975a0-fdde-4d00-98f8-0a2895b32d57   complete   true        https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git            0a38dc0d61f94eb43bf32c8bad801c4d41bf52d9   site.yml                            3d17h
        batcher-6d823363-c7cd-4616-afb8-416156a83522   cfs-78726a81-eb72-4e2f-80e8-a8d08a7c031c   complete   true        https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git            0a38dc0d61f94eb43bf32c8bad801c4d41bf52d9   site.yml                            29h
        batcher-ef877321-922c-4517-bc05-e4f2a5141b2b   cfs-a6c6f707-c7ca-48d7-aff7-71b26398c216   complete   true        https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git            a371a11a5cf139ba67cee5823c8ce0e5b61d7a3f   site.yml                            4d5h
        ed684272-7fe8-11ea-a0fd-a4bf0138f2ba           cfs-6ed992a3-7f63-4187-a2bf-fc4451ead997   complete   true        https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git   master                                              site.yml                            4d6h
        ncn-customization-ncn-w001-uai-hosts-load      cfs-acb9f57f-e390-49c6-8028-842550f3d73e   complete   false       https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git   master                                              cray-ncn-customization-load.yml     4d6h
        ncn-customization-ncn-w002-uai-hosts-load      cfs-37aebeb8-1c3f-45a4-a9b1-d25ad4e10a91   complete   false       https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git   master                                              cray-ncn-customization-load.yml     4d6h
        ncn-customization-ncn-w002-uai-hosts-unload    cfs-095cce88-1925-4625-a611-ae19d9976a60   complete   false       https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git   master                                              cray-ncn-customization-unload.yml   4d6h
        ncn-customization-ncn-w003-uai-hosts-load      cfs-6b3fdebd-ab2b-4751-b29f-436ff2893569   complete   false       https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git   master                                              cray-ncn-customization-load.yml     4d6h
        ncn-customization-ncn-w003-uai-hosts-unload    cfs-d94ebbe6-6b61-4f78-9dc4-fd24576d32dd   complete   false       https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git   master                                              cray-ncn-customization-unload.yml   4d6h
        ```

        If multiple CFS jobs exist, describe the CFS sessions and look at the configuration, as well as which components
        are included. It is unlikely, but a single session may contain components from multiple separate BOS sessions if they
        both request the same configuration for different components at around the same time.

        ```bash
        cray cfs sessions describe SESSION_NAME
        ```

    1. Find the pods for the CFS job.

        ```bash
        kubectl -n services get pods | grep JOB_NAME
        ```

        Example output:

        ```text
        cfs-1628cf85-e847-49af-891c-1b7655d8056d-29ntt      0/4     Completed   0     4d11h
        ```

    1. View the log from the CFS pod.

        ```bash
        kubectl -n services logs POD_NAME ansible
        ```

        Example output:

        ```text
        Inventory available
          % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                         Dload  Upload   Total   Spent    Left  Speed
          0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
        HTTP/1.1 200 OK
        content-type: text/html; charset=UTF-8
        cache-control: no-cache, max-age=0
        x-content-type-options: nosniff
        date: Thu, 16 Apr 2020 09:20:15 GMT
        server: envoy
        transfer-encoding: chunked

        [...]

        PLAY [Compute] *****************************************************************

        TASK [rsyslog : Add rsyslog.d config] ******************************************
        changed: [cle_default_rootfs_cfs_066bc062-7fc3-11ea-970e-a4bf0138f2ba]

        TASK [localtime : Create /etc/localtime symlink] *******************************
        changed: [cle_default_rootfs_cfs_066bc062-7fc3-11ea-970e-a4bf0138f2ba]

        TASK [ntp : Install stock /etc/chrony.conf] ************************************
        changed: [cle_default_rootfs_cfs_066bc062-7fc3-11ea-970e-a4bf0138f2ba]

        TASK [cle-hosts-cf : create temporary workarea] ********************************
        changed: [cle_default_rootfs_cfs_066bc062-7fc3-11ea-970e-a4bf0138f2ba]

        TASK [cle-hosts-cf : copy /etc/hosts from NCN host OS into compute image] ******
        changed: [cle_default_rootfs_cfs_066bc062-7fc3-11ea-970e-a4bf0138f2ba]

        TASK [cle-hosts-cf : copy /etc/hosts into place] *******************************
        changed: [cle_default_rootfs_cfs_066bc062-7fc3-11ea-970e-a4bf0138f2ba]

        TASK [cle-hosts-cf : remove temporary workarea] ********************************
        changed: [cle_default_rootfs_cfs_066bc062-7fc3-11ea-970e-a4bf0138f2ba]

        [...]
        ```

Use the data returned in the BOA and CFS logs to determine the underlying issue for slow boot times.
