# CSM Health Checks

This page lists available CSM Health Checks that can be executed to validate system health.

## Platform Health Checks

Scripts do not verify results. Script output includes analysis needed to determine pass/fail for each check. All health checks are expected to pass.
Health Check scripts can be run:
* after install.sh has been run – not before
* before and after one of the NCN's reboot
* after the system or a single node goes down unexpectedly
* after the system is gracefully shut down and brought up
* any time there is unexpected behavior on the system to get a baseline of data for CSM services and components
* in order to provide relevant information to support tickets that are being opened after sysmgmt manifest has been installed

Health Check scripts can be found and run on any worker or master node from any directory.

#### ncnHealthChecks
     /opt/cray/platform-utils/ncnHealthChecks.sh
The ncnHealthChecks script reports the following health information:
* Kubernetes status for master and worker NCNs
* Ceph health status
* Health of etcd clusters
* Number of pods on each worker node for each etcd cluster
* List of automated etcd backups for the Boot Orchestration Service (BOS), Boot Script Service (BSS), Compute Rolling Upgrade Service (CRUS), and Domain Name Service (DNS)
* NCN node uptimes
* Pods yet to reach the running state

#### ncnPostgresHealthChecks
     /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
For each postgres cluster the ncnPostgresHealthChecks script determines
the leader pod and then reports the status of all postgres pods in the cluster.

