# Cray System Management (CSM) - Release Notes

## CSM 1.0.10
The following lists enumerate the improvements and enhancements since CSM 1.0.1

### New Functionality
* Adds hardware discovery and power control for Bard Peak Olympus blades. (Power-capping not supported yet.)

### Bug Fixes
* Fixes an intermittent issue where kernel dumps wouldn't deliver because the CA cert for Spire needed to be reset.
* Fixes an intermittent issue where PXE booting of NCNs was timing out.
* Fixes an intermittent UX issue where Console was replaying output.
* Fixes an issue with FAS loader not handling the new Slingshot 1.6 firmware version scheme.
* Fixes an issue where Ceph services were not auto-starting after a reboot of a storage node.
* Fixes an issue where later ssh connections to Ceph were producing host key verification errors.
* Fixes an issue where DNS requests would briefly fail during hardware discovery or an upgrade.
* Fixes an issue preventing SCSD changing root credentials for DL325/385.
* Fixes an intermittent issue where Gigabyte firmware updates via FAS would return an error.
* Fixes a rare issue where Nexus would not be available when scaling down to two nodes.
* Fixes an issue where the boot order for Gigabyte NCNs wasn't persisting after a reboot or reinstall.
* Fixes an intermittent issue where storage nodes would have clock skew during fresh install.

## CSM 1.0.1
The following lists enumerate major improvements since CSM v0.9.x.

### What’s New
* Functionality
  - Scale up to 6000 Nodes is supported.
    - Conman has been updated to using a deployment model that handles a larger scale.
    - Additional scaling improvements have been incorporated into several services including, Unbound, Kea, hardware state manager (HSM), and Spire.
  - Upgrades between major versions are now allowed.
  - The CSM installation process has been improved.
    - Over 20 workarounds from the prior CSM release have been removed.
    - A significant number of installation-related enhancements have been integrated, both functionally and thru documentation.
    - Installation validation testing has been improved by updating existing validation tests and also adding additional tests.

* Enhanced Documentation
  - CSM operational documentation has been changed to markdown format for standardized deployment.
  - CSM Administration Guides and Operational Procedures are now also available online.
  - Searchable HTML - https://cray-hpe.github.io/docs-csm/en-10/
  - Source - https://github.com/Cray-HPE/docs-csm/tree/release/1.0
  - Improvements have been made to the documentation regarding installation, operations, and troubleshooting.
    - Contains backup and restore procedures for Keycloak, Spire and SLS services.
    - Provides guidance on setting the timezone for customer systems.
    - Explains how to build application node xnames.

* New Hardware Support
  - AMD Rome-Based HPE Apollo 6500 XL675d Gen10+ with NVIDIA 40GB A100 GPU for use as a Compute Node.
  - AMD Rome-Based HPE Apollo 6500 XL645d Gen10+ with NVIDIA 40GB A100 GPU for use as a Compute Node.
  - AMD Rome-Based HPE DL385 Gen10+ with NVIDIA 40GB A100 GPU for use as a User Access Node.
  - AMD Rome-Based HPE DL 385 Gen10+ with AMD Mi100 GPU for use as a User Access Node.
  - AMD Milan-Based HPE DL 385 with NVIDIA 40 GB A100 GPU for use as a User Access Node.
  - AMD Milan-Based HPE Apollo 6500/XL645d Gen10+ with NVIDIA 80GB A100 GPU for use as a Compute Node.
  - AMD Milan-Based Windom Blade with NVIDIA 40 GB A100 GPU for use as a Compute Node.
  - AMD Milan-Based Grizzly Peak Blade with NVIDIA 40 GB A100 GPU for use as a Compute Node.
  - AMD Milan-Based Grizzly Peak Blade with NVIDIA 80 GB A100 GPU for use as a Compute Node.
  - Aruba CX8325, 8360, and 6300M network switches

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
  - CAPMC simulates reinit on hardware that does not support restart; see [CAPMC reinit and configuration](troubleshooting/capmc/CAPMC_reinit_and_config.md) for more information

### Bug Fixes
The following list enumerates the more important issues that were found and fixed in CSM v1.0.1. In total, there were more than 34 customer-reported issues and more than 350 development critical issues fixed in this release.

Critical Issues Resolved:
* Prometheus cannot scrape kubelet/kube-proxy.
* CFS can run layers out of order.
* The cray-bss - bos session boot parameter update seems slow.
* Compute nodes fail to PXE boot and drop into the EFI shell.
* The ncn-personalization of ncn-m002 and m003 seems to be in endless loop.
* FAS is claiming to have worked on CMM, but it did not during a V1.4 install.
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
* sysmgmt-health references `docker.io/jimmidyson/configmap-reload:v0.3.0`, which cannot be loaded.
* Upstream NTP is not appearing in the chronyd config.
* Incorrect packaged firmware metadata is being reported by FAS for the NCN's iLO/BIOS.
* At scale, there is a DNS slowdown when attempting to reboot all of the nodes, causing DNS lookup failures.
* cray-sysmgmt-health-kube-state-metrics uses an image of kube-state-metrics:v1.9.6, which contains a bug that causes alerts.
* CFS teardown reports swapped image results.
* The unbound DNS manager job is not functioning, so compute nodes cannot be reached.
* The Keycloak service crashed because it was out of java heap space.
* Unbound should not forward to site DNS for Shasta zones.
* k8s Pod Priority Support needs to be in k8s Image.
* CFS is running multiple sessions for the same nodes at the same time.
* The CFS CLI does not allow tags on session create.
* CFS should check if the configuration is valid/exists when a session is created.
* CFS does not set session start time until after job starts.
* CFS will not list pending sessions.
* MEDS, should not overwrite a components credentials when a xname becomes present again.
* The Cray HSM locks command locked more nodes than specified.
* HSM crashes when discovering Bard Peak.
* Resources limits are hit on three NCN systems.
* Conman is unable to connect to compute consoles.
* For better reliability, the orphan stratum in Chrony config needed to be adjusted.
* The UEFI Boot Order Reverts/Restores on every reboot on an HPE DL325.
and many more...
        
### Known Issues
* Incorrect_output_for_bos_command_rerun: When a Boot Orchestration Service (BOS) session fails, it may output a message in the Boot Orchestration Agent (BOA) log associated with that session. This output contains a command that instructs the user how to re-run the failed session. It will only contain the nodes that failed during that session. The command is faulty, and this issue addresses correcting it.
* Cfs_session_stuck_in_pending: Under some circumstances, Configuration Framework Service (CFS) sessions can get stuck in a `pending` state, never completing and potentially blocking other sessions. This addresses cleaning up those sessions.
* The `branch` parameter in CFS configurations may not work, and setting it will instead return an error. Continue setting the git commit hash instead.
* After a boot or reboot a few CFS Pods may continue running even after they have finished and never go away. For more information see [Orphaned CFS Pods After Booting or Rebooting](troubleshooting/known_issues/orphaned_cfs_pods.md).
* Intermittently, kernel dumps do not deliver because the CA cert for Spire needed to be reset.
* Intermittently, PXE booting of NCNs time out.
* Intermittently, Console replays output.
* FAS loader is not handling the new Slingshot 1.6 firmware update because of its new version scheme.
* Ceph services do not auto-start after a reboot of a storage node.
* Intermittently, ssh connections to Ceph show host key verification errors.
* Intermittently, DNS requests briefly fail during hardware discovery or an upgrade.
* SCSD is not able to change root credentials for DL325/385 due to a bug in the 11.2021 iLO firmware.
* Intermittently, Gigabyte firmware updates via FAS show an error.
* Rarely, Nexus is not available when scaling down NCN workers to two nodes.
* The boot order for Gigabyte NCNs does not persist after a reboot or reinstall.
* Intermittently, storage nodes have clock skew during fresh install.
* Kube-multus pods may fail to restart due to ImagePullBackOff. For more information see [Kube-multus pod is in ImagePullBackOff](troubleshooting/known_issues/kube_multus_pod_in_ImagePullBackOff.md).
* Power capping Olympus hardware via CAPMC is not supported.
