# Gitea/VCS 401 Errors

## Summary

During fresh installs of csm-1.0.x, creation of the main admin user for gitea/VCS (Version Control Service) may fail. In this case, calls to the gitea/VCS API that require authentication will return `401` status codes with a message of `token is required`. The workaround is to manually create the admin user.

## Symptoms

During a fresh install, if this problem occurs, it will typically be noticed during the first run of the [Validate CSM Health](../../operations/validate_csm_health.md) procedure when the [SMS Health Checks](../../operations/validate_csm_health.md#sms-health-checks) are performed. The `cmsdev` command will include output similar to the following:
```text
ERROR (run tag zl7ak-vcs): POST https://api-gw-service-nmn.local/vcs/api/v1/orgs: expected status code 201, got 401
ERROR (run tag zl7ak-vcs): Failed to create vcs organization
```

If you see the above, first verify that this is due to the user creation issue documented on this page. To do so, perform the following steps on any Kubernetes master or worker node.

1. Identify the Gitea/VCS pod:

    ```bash
    ncn-mw# GITEA_VCS_POD=$(
                kubectl get pods -n services |
                grep "^gitea-vcs-" |
                grep -v "^gitea-vcs-postgres-" |
                grep -w Running |
                awk '{ print $1 }')
    ncn-mw# echo $GITEA_VCS_POD
    ```

    The output should look similar to the following:
    ```text
    gitea-vcs-7c6f5b5c45-4wjcl
    ```

1. Search the Gitea setup log using the following command:
    ```bash
    ncn-mw# kubectl exec -n services $GITEA_VCS_POD -c vcs -- \
                grep -o "^Incorrect Usage: flag provided but not defined:" /data/gitea/setup
    ```

    * `command terminated with exit code 1`

        If the command gives this output, it means that the problem being investigated is **NOT** the problem documented on this page.

    * `Incorrect Usage: flag provided but not defined:`

        If the command gives this output, then the problem being investigated **IS** the problem documented on this page. In this case,
        complete the following remediation steps to manually create the admin user.

## Remediation

1. Manually create the admin user by running the following command:

    > **NOTE**: This command uses the `$GITEA_VCS_POD` variable defined by one
    > of the commands in the previous section.

    ```bash
    ncn-mw# kubectl exec -n services $GITEA_VCS_POD -c vcs -- su -l git -c '
                set -eo pipefail
                cd /data/gitea
                echo "Manually creating admin user; Running in `pwd`" >> /data/gitea/setup
                CRAYVCS_USER=$(</mnt/crayvcs-credentials/vcs_username)
                CRAYVCS_PASSWORD=$(</mnt/crayvcs-credentials/vcs_password)
                CRAYVCS_USER_EMAIL="${CRAYVCS_USER}@mgmt-plane-nmn.local"
                /app/gitea/gitea admin create-user \
                    --config /data/gitea/conf/app.ini \
                    --name ${CRAYVCS_USER} \
                    --admin \
                    --must-change-password=false \
                    --email "${CRAYVCS_USER_EMAIL}" \
                    --password "${CRAYVCS_PASSWORD}" 2>&1 |
                        tee -a /data/gitea/setup'
    ```

    On success, the output will look similar to the following:
    ```text
    --name flag is deprecated. Use --username instead.
    2022/03/22 17:50:54 ...dules/setting/git.go:93:newGit() [I] Git Version: 2.24.4, Wire Protocol Version 2 Enabled
    New user 'crayvcs' has been successfully created!
    ```

1. Re-run the [SMS Health Checks](../../operations/validate_csm_health.md#sms-health-checks) to validate that the problem has been resolved.
