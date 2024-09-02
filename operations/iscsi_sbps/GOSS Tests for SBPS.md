# Assumptions before running this test: 

Ansible scripts are run successfully which configures iSCSI on selected worker nodes and label them as 'iscsi=sbps'. Goss tests use this label as identification of nodes on which this test has to run. 

## SBPS GOSS Frame work:

Bash script 'iscsi_sbps_sanity.sh' is written for the below mentioned sanity checks:

- Verify SPBS Agent is running (systemd service)
- Verify LIO target is active
- Verify TCP service probes complete against all active portals (iSCSI)
- Verify DNS SRV and A records exist for the worker respective of the iSCSI portals
- Mapping between DNS A records and host iscsi portals

This bash script 'iscsi_sbps_sanity.sh' needs to be placed under /opt/cray/tests/install/ncn/scripts/ directory. 
The goss script which determines on which nodes to run the' iscsi_sbps_sanity.sh' and invokes this script is 'goss-validate-iscsi-sbps-config.yaml'
This yaml file needs to be placed under /opt/cray/tests/install/ncn/tests/ directory. The file name (goss-validate-iscsi-sbps-config.yaml) entry has to be made in /opt/cray/tests/install/ncn/suites/ncn-healthcheck-worker.yaml. All these have to be done on all the nodes (master and worker).

## Steps to run:

Ensure below goss environment variable is set and 'goss-servers' systemd service is running on all the nodes (master and worker):

    export GOSS_BASE=/opt/cray/tests/install/ncn

Restart the goss-server on all the configured worker nodes .

systemctl restart goss-servers.service <------- on all the worker nodes configured.
ncn-m001:/opt/cray/tests/install/ncn/tests # systemctl status goss-servers.service
â goss-servers.service - goss-servers
     Loaded: loaded (/etc/systemd/system/goss-servers.service; disabled; vendor preset: disabled)
     Active: active (running) since Tue 2024-01-16 18:47:59 UTC; 1 day 18h ago
   Main PID: 1630316 (bash)
      Tasks: 682
     CGroup: /system.slice/goss-servers.service

Two ways to trigger goss tests. 

Method #1: Run below script from master/pit  node

    /opt/cray/tests/install/ncn/automated/ncn-healthcheck-worker

This will trigger of the test onto corresponding worker nodes which are configured with iSCSI. Here it runs on worker nodes as worker nodes will be configured with iSCSI. 

Method #2: Run on Individual node (worker)

    goss -g /opt/cray/tests/install/ncn/tests/goss-validate-iscsi-sbps-config.yaml validate

    This will trigger on the node on which this was run.


