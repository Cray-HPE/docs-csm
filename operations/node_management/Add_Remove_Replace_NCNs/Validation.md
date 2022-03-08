# Validate NCN

## Description

Validate that the system is health

## Procedure

1. Collect data about the system management platform health \(can be run from a master or worker NCN\).

   ```bash
   ncn-mw# /opt/cray/platform-utils/ncnHealthChecks.sh
   ncn-mw# /opt/cray/platform-utils/ncnPostgresHealthChecks.sh
   ```

1. Run the following goss tests which will cover a variety of sub-systems \(can be run from a master or worker NCN\)..

   ```bash
   ncn-mw# /opt/cray/tests/install/ncn/automated/ncn-healthcheck-master
   ncn-mw# /opt/cray/tests/install/ncn/automated/ncn-healthcheck-worker
   ncn-mw# /opt/cray/tests/install/ncn/automated/ncn-healthcheck-storage
   ncn-mw# /opt/cray/tests/install/ncn/automated/ncn-kubernetes-checks 
   ```
