# Cray System Management (CSM) - Release Notes

## What’s New
    * Base Platform Component Upgrades
        - Istio version 1.7.8, running in distroless mode
        - Containerd version 1.4.3
        - Kubernetes version 1.19.9
        - Weave version 2.8.0
        - Etcd API version 3.4 (etcdctl version 3.4.14)
        - Coredns version 1.7.0
        - Ceph version 15.2.12-83-g528da226523 (octopus)

    * Security Improvements
        - Ansible Plays have been created to update management node Operating System Passwords and SSH Keys.
        - A significant number of security enhancements have been implemented to eliminate vulnerabilities and provide security hardening
          Including:
              - The removal of clear-text passwords in CSM install scripts
              - Incorporation of trusted-base operating systems in containers
              - And addresses many critical security CVEs.

    * Customer Requested Enhancements
        - Error Logging for the BOS session template must be improved.
        - IMS must provide a way to clean up sessions without the use of jq and xargs.
        - Cray-cfs-batcher needs a maximum limit for session creation suspension.
        - BOS session should help to identify the resulting cfs job.
        - DHCP lease time should be increased. (It was increased to 3600 seconds.)
        - Helm charts should have a way to be automatically patched during Shasta installation.
        - HSM should add a timestamp to State Change Notifications (SCN) data before publishing to Kafka topic: cray-hmsstatechange-notifications.
        - End-of-Life Alpine and nginx container images must be removed for security purposes.

## Bug Fixes
The following list enumerates the more important issues that were found and fixed in CSM v1.0.0. In total, there were more than 34 customer-reported issues and more than 350 development critical issues fixed in this release.

  Critical Issues Resolved:
    * Prometheus can't scrape kubelet/kube-proxy.
    * CFS can run layers out of order.
    * The cray-bss - bos session boot parameter update seems slow.
    * Compute nodes fail to PXE boot and drop into the EFI shell.
    * The ncn-personalization of ncn-m002 and m003 seems to be in endless loop.
    * FAS is claiming to have worked on CMM, but it didn't during a V1.4 install.
    * The cray-hbtd is reporting "Telemetry bus not accepting messages, heartbeat event not sent."
    * When talking to SMD, Commands are failing with an Err 503.
    * The command "cray hsm inventory ethernetInterfaces update --component-id" is rejected as invalid.
    * There is a high rate of failed DNS queries being forwarded off-system by unbound.
    * NCN worker node's HSN connection is not being renamed to hsn0 or hsn1.
    * During large-scale node boots, a small number of nodes are stuck with fetching auth token failed.
    * Zypper install is broken because it tries to talk to suse.com.
    * Node exporters failed to parse mountinfo and are not running on ncn-s0xx nodes.
    * The cfs-hwsync-agent is repeatedly dying with RC=137 due to an OOM issue.
    * The gitea pvc is unavailable following a full system cold reboot.
    * sysmgmt-health references `docker.io/jimmidyson/configmap-reload:v0.3.0`, which can't be loaded.
    * Upstream NTP is not appearing in the chronyd config.
    * Incorrect packaged firmware metadata is being reported by FAS for the NCN's iLO/BIOS.
    * At scale, there is a DNS slowdown when attempting to reboot all of the nodes, causing DNS lookup failures.
    * cray-sysmgmt-health-kube-state-metrics uses an image of kube-state-metrics:v1.9.6, which contains a bug that causes alerts.
    * CFS teardown reports swapped image results.
    * The unbound DNS manager job is not functioning, so compute nodes can't be reached.
    * The Keycloak service crashed because it was out of java heap space.
    * Unbound should not forward to site DNS for Shasta zones.
    * k8s Pod Priority Support needs to be in k8s Image.
    * CFS is running multiple sessions for the same nodes at the same time.
    * The CFS CLI does not allow tags on session create.
    * CFS should check if the configuration is valid/exists when a session is created.
    * CFS doesn't set session start time until after job starts.
    * CFS won't list pending sessions.
    * MEDS, should not overwrite a components credentials when a xname becomes present again.
    * The Cray HSM locks command locked more nodes than specified.
    * HSM crashes when discovering Bard Peak.
    * Resources limits are hit on three NCN systems.
    * Conman is unable to connect to compute consoles.
    * For better reliability, the orphan stratum in Chrony config needed to be adjusted.
    * The UEFI Boot Order Reverts/Restores on every reboot on an HPE DL325.
    and many more...
        
## Known Issues
* Incorrect_output_for_bos_command_rerun: When a Boot Orchestration Service (BOS) session fails, it may output a message in the Boot Orchestration Agent (BOA) log associated with that session. This output contains a command that instructs the user how to re-run the failed session. It will only contain the nodes that failed during that session. The command is faulty, and this issue addresses correcting it.
* Cfs_session_stuck_in_pending: Under some circumstances, Configuration Framework Service (CFS) sessions can get stuck in a `pending` state, never completing and potentially blocking other sessions. This addresses cleaning up those sessions.
* The `branch` parameter in CFS configurations may not work, and setting it will instead return an error. Continue setting the git commit hash instead.
* After a boot or reboot a few CFS Pods may continue running even after they've finished and never go away. For more information see [Orphaned CFS Pods After Booting or Rebooting](troubleshooting/known_issues/orphaned_cfs_pods.md).
