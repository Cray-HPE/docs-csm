# Known issues with NCN health checks

- The first pass of running these tests may fail due to `cloud-init` not being completed on the storage nodes. In the case of failure, wait for five minutes and rerun the tests.

- For any failures related to SSL certificates, see the [SSL Certificate Validation Issues](ssl_certificate_validation_issues.md) troubleshooting guide.

- `Kubernetes Query BSS Cloud-init for ca-certs`

  - This test may fail immediately after platform installation. It should pass after the `TrustedCerts` operator has updated BSS
    (Global `cloud-init` meta) with CA certificates.

- `Kubernetes Velero No Failed Backups`

  - Because of a [known issue  with Velero](https://github.com/vmware-tanzu/velero/issues/1980), a backup may be attempted immediately
    upon the deployment of a backup schedule (for example, Vault). It may be necessary to delete backups from a Kubernetes node to
    clear this situation. For more information on how to clean up backups that have failed due to a known interruption, see the output of the test.
    For example:

     1. (`ncn-mw#` or `pit#`) Find the failed backup.

        ```bash
        kubectl get backups -A -o json | jq -e '.items[] | select(.status.phase == "PartiallyFailed") | .metadata.name'
        ```

     1. (`ncn-mw#`) Delete the backup.

        > In the following command, replace `<backup>` with a backup returned in the previous step.
        >
        > This command will not work on the PIT node.

        ```bash
        velero backup delete <backup> --confirm
        ```

- `Verify spire-agent is enabled and running`

  - The `spire-agent` service may fail to start on Kubernetes NCNs (all worker and master nodes). In this case, it may log errors
    (using `journalctl`) similar to `join token does not exist or has already been used`, or the last log entries may contain multiple
    instances of `systemd[1]: spire-agent.service: Start request repeated too quickly.`. Deleting the `request-ncn-join-token` `daemonset` pod
    running on the node may clear the issue. Even though the `spire-agent` `systemctl` service on the Kubernetes node should eventually
    restart cleanly, the user may have to log in to the impacted nodes and restart the service. The following recovery procedure can
    be run from any Kubernetes node in the cluster.

     1. (`ncn-mw#` or `pit#`) Define the following function

        ```bash
        function renewncnjoin() {
            for pod in $(kubectl get pods -n spire |grep request-ncn-join-token | awk '{print $1}'); do
                if kubectl describe -n spire pods $pod | grep -q "Node:.*$1"; then
                    echo "Restarting $pod running on $1"
                    kubectl delete -n spire pod "$pod"
                fi
            done
        }
        ```

     1. (`ncn-mw#` or `pit#`) Run the function as follows (substituting the name of the impacted NCN):

        ```bash
        renewncnjoin ncn-xxxx
        ```

  - The `spire-agent` service may also fail if an NCN was powered off for too long and its tokens are expired. If this happens, delete
    `/root/spire/agent_svid.der`, `/root/spire/bundle.der`, and `/root/spire/data/svid.key` off the NCN before deleting the
    `request-ncn-join-token` daemon set pod.

- `cfs-state-reporter service ran successfully`

  - If this test is failing, it could be due to SSL certificate issues on that NCN.

     1. (`ncn#`) Run the following command on the node where the test is failing.

        ```bash
        systemctl status cfs-state-reporter | grep HTTPSConnectionPool
        ```

     1. If the previous command gives any output, this indicates possible SSL certificate problems on that NCN.

        - See the [SSL Certificate Validation Issues](ssl_certificate_validation_issues.md) troubleshooting guide.

  - If this test is failing on a storage node, it could be an issue with the node's Spire token. The following procedure may resolve the problem:

     1. (`ncn-m002#`) Run the following script:

        ```bash
        /opt/cray/platform-utils/spire/fix-spire-on-storage.sh
        ```

     1. Rerun the check to see if the problem is resolved.

- Clock skew test failures

   It can take up to 15 minutes, and sometimes longer, for NCN clocks to synchronize after an upgrade or when a system is restored. If a clock skew test
   fails, wait for 15 minutes, and try again.

   (`ncn-m001#`) To check status, run the following command, preferably on `ncn-m001`:

   ```bash
   chronyc sources -v
   ```

   ```text
   210 Number of sources = 9

     .-- Source mode  '^' = server, '=' = peer, '#' = local clock.
    / .- Source state '*' = current synced, '+' = combined , '-' = not combined,
   | /   '?' = unreachable, 'x' = time may be in error, '~' = time too variable.
   ||                                                 .- xxxx [ yyyy ] +/- zzzz
   ||      Reachability register (octal) -.           |  xxxx = adjusted offset,
   ||      Log2(Polling interval) --.      |          |  yyyy = measured offset,
   ||                                \     |          |  zzzz = estimated error.
   ||                                 |    |           \
   MS Name/IP address         Stratum Poll Reach LastRx Last sample
   ===============================================================================
   ^* ntp.hpecorp.net               2  10   377   650   -421us[ -571us] +/-   30ms
   =? ncn-m002.nmn                 10   4   377   213    +82us[  +82us] +/-  367us
   =- ncn-m003.nmn                  3   1   377     1  -2033us[-2033us] +/-   28ms
   =- ncn-s001.nmn                  6   5   377    20    +53us[  +53us] +/-  193us
   =- ncn-s002.nmn                  5   5   377    25    +29us[  +29us] +/-  275us
   =- ncn-s003.nmn                  6   6   377    27    +47us[  +47us] +/-  237us
   =- ncn-w001.nmn                  5   9   377  234m  +8305us[  +10ms] +/-   38ms
   =- ncn-w002.nmn                  3   5   377     8  -1910us[-1910us] +/-   27ms
   =- ncn-w003.nmn                  3   8   377   74m  -1122us[-1002us] +/-   31ms
   ```

- `Etcd backups missing after system power up`

   After system power up, automated Etcd backups will resume within about 24 hours of the cluster being back up.  When running the `ncnHealthChecks.sh` script within this time period, it may report a failure:

   ```text
   --- FAILED --- not all Etcd clusters had expected backups.
   ```

   This is normal, and backups should resume after 24 hours.
