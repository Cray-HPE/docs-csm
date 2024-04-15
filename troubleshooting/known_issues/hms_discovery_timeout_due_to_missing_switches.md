# Discover Timeout Due to Missing Switches

## Overview

On systems with a large number of non-existent network switches, it has been observed that the hms-discovery job may fail to finish due to spending too much time trying to communicate with the non-existent switches. This may happen when incrementally building up a new system and running CSM prior to completion of the full hardware installation.

# Symptoms and Diagnosis

Should hms-discovery be found to not complete in such an environment, this specific problem can be diagnosed as follows:

1. (`ncn-mw#`) Dump the logs for the failed hms-discover jobs:

    ```bash
    kubectl -n services logs hms-discovery-28483755-mgvxn -f --timestamps
    ```

1. (`ncn-mw#`) Look for messages that look similar to the following (example log is abbreviated heavily for illustrative purposes):

    ```text
    ... "msg":"Failed to get port map for management switch!", ..., "error":"failed to perform bulk get: read udp 10.38.0.46:55957->10.254.0.18:161: i/o timeout" ...
    ```

In order to be considered a duplicate of the problem described here, there should be at least several of these matching logs.

# Workaround

If this problem is encountered, it can be worked around by increasing the activeDeadlineSeconds value in the hms-discovery deployment.

1. (`ncn-mw#`) Edit the hms-discovery deployment:

    ```bash
    kubectl edit cronjob -n services hms-discovery
    ```

1. (`ncn-mw#`) In the edit session for the deployment, look for the following line:

    ```text
    activeDeadlineSeconds: 300
    ```

1. (`ncn-mw#`) Update it from 300 (5 min) to something much larger like 30000 (500 min):

    ```text
    activeDeadlineSeconds: 30000
    ```

1. (`ncn-mw#`) Save your changes.  The next hms-discovery job will have its timeout extended.

1. (`ncn-mw#`) Gather a list of switches that were not discovered properly:

    ```bash
    cray hsm inventory redfishEndpoints list --type RouterBMC --format json | jq -c '.RedfishEndpoints[] | {ID,DiscoveryInfo}'
    ```

A switch was not discovered properly if it is not showing as "DiscoverOK" in this output.

1. (`ncn-mw#`) Force re-discovery of the failed switches:

    ```bash
    cray hsm inventory discover create --xnames <COMMA_SEPERATED_XNAME_LIST> --force true
    ```

# Fix

This issue is expected to be fixed in the CSM 1.6 release.
