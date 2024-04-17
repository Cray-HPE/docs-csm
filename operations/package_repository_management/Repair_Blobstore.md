# Repair `Blobstore`

Nexus may encounter an issue where a RPM fails to download due to missing blob data in the `blobstore`.

Configure the `Repair: Reconcile component database from blob store` task in Nexus to cleanup any uploaded data that may be incomplete.
This is not typically needed, so it is considered to be a repair task.

The example in this procedure is for creating a repair task to reconcile the `csm blobstore` to resolve an issue downloading `https://packages.local/repository/csm-noos/x86_64/cray-site-init-1.32.3-1.x86_64.rpm`.

Nexus logs may contain the following warning.

Example output:

```text
*UNKNOWN org.sonatype.nexus.transaction.RetryController - Exceeded retry limit: 8/8 (org.sonatype.nexus.repository.storage.MissingBlobException: Blob default@35A948FA-BC6DC537-60B22DA2-11B0B4B9-EC112D49:7d049616-0122-4160-b5b1-ed5366dd790e exists in metadata, but is missing from the blobstore)
```

See the [Nexus documentation on tasks](https://help.sonatype.com/en/tasks.html) for more information.

- [Prerequisites](#prerequisites)
- [System domain name](#system-domain-name)
- [Nexus web URL](#nexus-web-url)
- [Procedure](#procedure)

## Prerequisites

CSM installation is complete.

## System domain name

The `SYSTEM_DOMAIN_NAME` value found in some of the URLs on this page is expected to be the system's fully qualified domain name (FQDN).

(`ncn-mw#`) The FQDN can be found by running the following command on any Kubernetes NCN.

```bash
kubectl get secret site-init -n loftsman -o jsonpath='{.data.customizations\.yaml}' | base64 -d | yq r - spec.network.dns.external
```

Example output:

```text
system.hpc.amslabs.hpecorp.net
```

Be sure to modify the example URLs on this page by replacing `SYSTEM_DOMAIN_NAME` with the actual value found using the above command.

## Nexus web URL

Nexus is accessible using a web browser at the following URL: `https://nexus.cmn.SYSTEM_DOMAIN_NAME`

An example of what the resulting URL will look like is: `https://nexus.cmn.eniac.dev.cray.com`.

## Procedure

1. Log in to the Nexus web UI.

    ![Access Nexus with the web UI](./Manage_Repositories_with_Nexus.md#access-nexus-with-the-web-ui)]

    ![Nexus Web UI](../../img/operations/Nexus_Web_UI.png "Nexus Web UI")

1. Click on the gear icon at the top of the page.

    Clicking on the gear will open up the repository administration page.

    ![Repository Administration Page](../../img/operations/Nexus_Repository_Admin_Page.png "Repository Administration Page")

1. Click on `Tasks` in the navigation bar on the left-hand side of the page.

    The `Tasks` button is under the `System` heading.

    ![Tasks Page](../../img/operations/Nexus_Tasks_Page.png "Tasks Page")

1. Click the `Create Task` button.

    Clicking the `Create Task` button will open up the following page. Select the type of task. For this example, the `Repair: Reconcile component database from blob store` option would be selected.

    ![Task Type Selection](../../img/operations/Nexus_Task_Type_Selection.png "Task Type Selection")

1. Enter the required information for the task, such as the task name, Blob store, and task frequency.

    Click the `Create task` at the bottom of the page after entering all required information about the task.

    The new task will now be available on the main `Tasks` page.

1. Click on the newly created task.

1. Click the `Run` button at the top of the page.

    Select `Yes` when the confirmation pop-up appears.

    There will now be information about the run that was just scheduled on the main `Tasks` page. Once the task status is `Waiting` and the last result is `Ok`, the task has completed successfully.

1. (`ncn-mw#`) View the log file on the system.

    Even though the Nexus logs contains messages pertaining to tasks, it can be difficult to track messages for a specific task, especially because repairing a `blobstore` can take time.

    1. Retrieve the Nexus pod name.

        ```bash
        kubectl -n nexus get pods | grep nexus
        ```

        Example output:

        ```text
        nexus-55d8c77547-65k6q              2/2     Running     1          22h
        ```

    1. Access the running Nexus pod.

        ```bash
        kubectl -n nexus exec -ti nexus-55d8c77547-65k6q -c nexus -- ls -ltr /nexus-data/log/tasks
        ```

        Example output:

        ```text
        total 8
        -rw-r--r-- 1 nexus nexus 16920742 Apr 15 22:30 blobstore.rebuildComponentDB-20240415221109275.log
        -rw-r--r-- 1 nexus nexus     1345 Apr 16 01:00 repository.cleanup-20240416010000016.log
        ```

    1. View the log file for the blobstore rebuild.

        The log file for a successful rebuild will look similar to the following:

        ```bash
        kubectl -n nexus exec -ti nexus-55d8c77547-65k6q -c nexus -- tail /nexus-data/log/tasks/blobstore.rebuildComponentDB-20240415221109275.log
        ```

        Example output:

        ```text
        2024-04-15 22:30:52,200+0000 INFO  [quartz-9-thread-19]  *SYSTEM org.sonatype.nexus.blobstore.restore.orient.DefaultOrientIntegrityCheckStrategy - Checking integrity of assets in repository 'csm-1.4.2-noos' with blob store 'csm'
        2024-04-15 22:30:52,220+0000 INFO  [quartz-9-thread-19]  *SYSTEM org.sonatype.nexus.blobstore.restore.orient.DefaultOrientIntegrityCheckStrategy - Elapsed time: 20.45 ms, processed: 8, failed integrity check: 0
        2024-04-15 22:30:52,221+0000 INFO  [quartz-9-thread-19]  *SYSTEM org.sonatype.nexus.blobstore.restore.orient.OrientRestoreMetadataTask - Task complete
        ```

        The returned `Task complete` without any other `ERROR` or `WARN` messages indicates that the rebuild has completed successfully.

        In this case, it took just over 20 minutes to finish.

1. (`ncn-m001#`) Rerun the script to install CSM to Nexus again. The location of this script is based on where the CSM release tarball was unpacked.
Generally this file exists under `/etc/cray/upgrade/csm/${CSM_REL_NAME}/tarball/${CSM_REL_NAME}`. The script also needs `NEXUS_USERNAME` and `NEXUS_PASSWORD` to be set.

    ```bash
    function nexus-get-credential() {

        if ! command -v kubectl 1>&2 >/dev/null; then
          echo "Requires kubectl"
          return 1
        fi
        if ! command -v base64 1>&2 >/dev/null ; then
          echo "Requires base64"
          return 1
        fi

        [[ $# -gt 0 ]] || set -- -n nexus nexus-admin-credential

        kubectl get secret "${@}" >/dev/null || return $?

        NEXUS_USERNAME="$(kubectl get secret "${@}" --template {{.data.username}} | base64 -d)"
        NEXUS_PASSWORD="$(kubectl get secret "${@}" --template {{.data.password}} | base64 -d)"
    }
    ```

    ```bash
    cd <location of unpacked CSM Release tarball>
    ./lib/setp-nexus.sh
    ```

1. (`ncn-mw#`) Check that the RPM is present in Nexus.

    ```bash
    function paginate() {
        local url="$1"
        local token
        { token="$(curl -sSk "$url" | tee /dev/fd/3 | jq -r '.continuationToken // null')"; } 3>&1
        until [[ "$token" == "null" ]]; do
            { token="$(curl -sSk "$url&continuationToken=${token}" | tee /dev/fd/3 | jq -r '.continuationToken // null')"; } 3>&1
        done
    }
    paginate "https://packages.local/service/rest/v1/components?repository=csm-noos" | jq -r '.items[] | .name' | sort -u | grep cray-site-init
    ```

1. (`ncn-mw#`) Check that the RPM can be successfully downloaded from Nexus.

    ```bash
    wget https://packages.local/repository/csm-noos/x86_64/cray-site-init-1.32.3-1.x86_64.rpm
    ```
