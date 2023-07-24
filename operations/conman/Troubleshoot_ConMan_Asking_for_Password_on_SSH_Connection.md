# Troubleshoot ConMan Asking for Password on SSH Connection

If ConMan starts to ask for a password when there is an SSH connection to the
node on liquid-cooled hardware, that usually indicates there is a problem with
the SSH key that was established on the node BMC. The key may have been
replaced or overwritten on the hardware.

Use this procedure to renew or reinstall the SSH key on the BMCs.

## Prerequisites

This procedure requires administrative privileges. If checking the existing SSH key on BMC's
the BMC username and password are also required.

> **`NOTE`** The procedure to find a BMC username and password is listed in
[Determine the system's default BMC `root` user password](../security_and_authentication/Recovering_from_Mismatched_BMC_Credentials.md)

## Check if a key is incorrect on a node

1. (`ncn-mw#`) Get the SSH public key being used by ConMan.

    ```bash
    kubectl -n services exec -it cray-console-node-0 -c cray-console-node -- /bin/bash -c "cat /var/log/console/conman.key.pub"
    ```

    Expected output will look something like:

    ```text
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWwcRCONVFO+uCXc5o3qdHC0wrSIiaXWTEbBQHTsn8UsQP0orR/uYnKziJJSh4iD+OUVMFpn0Jt/XbokKsIVxuRS5rcKN0V0VBQ8BoRTXi9Tb6V3uF4WnZJKruf36bX1v18Cmn3WSkey9hlYaDZykokv4DW9VYEixHe0vN+4bZSbFmZzASbaQmU/twpw6wqGv4XgCVgq/YUQUEYRmGD5g41tXGfEZyRZShK8tzRuPa5Or2k64n1X2zhtoulHtF8bzdwvfPqnuj3oLDZX6g8I2iJ1X0AKYU6JGB0Nj4h0CJ0tgK5JCFZtTiYDnb/75SBRqM115KCLlpGbUD/fLWpr4H
    ```

1. (`ncn-mw#`) Check the public key on the BMC.

    ```bash
    curl -sk -u BMC_USER:BMC_PASS https://x9000c1s6b0/redfish/v1/Managers/BMC/NetworkProtocol | jq .Oem.SSHConsole
    ```

    Expected output for a matching key will look something like:

    ```json
    {
    "AuthorizedKeys": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWwcRCONVFO+uCXc5o3qdHC0wrSIiaXWTEbBQHTsn8UsQP0orR/uYnKziJJSh4iD+OUVMFpn0Jt/XbokKsIVxuRS5rcKN0V0VBQ8BoRTXi9Tb6V3uF4WnZJKruf36bX1v18Cmn3WSkey9hlYaDZykokv4DW9VYEixHe0vN+4bZSbFmZzASbaQmU/twpw6wqGv4XgCVgq/YUQUEYRmGD5g41tXGfEZyRZShK8tzRuPa5Or2k64n1X2zhtoulHtF8bzdwvfPqnuj3oLDZX6g8I2iJ1X0AKYU6JGB0Nj4h0CJ0tgK5JCFZtTiYDnb/75SBRqM115KCLlpGbUD/fLWpr4H\n"
    }
    ```

    Expected output for a non-matching key will look something like:

    ```json
    {
    "AuthorizedKeys": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDfFmoGLNw3zzghpT81Zir+YuUC2vgany9PdkOzViFi2f3xK8ijhFuCWDJcLQyvL0vgtCrRB+mI88GMaQh7tcXnSU9Lt6ELOchKFYMK2/mtaOG/+xuD29LcNl1Xk6KHTr/MkUBethrGwIJfIzUZZQCLYGPQt3LSwJXDpWAcihjUiwMnikyGJXSiWIRJ7e1B3vjHthLutXQEphM0K4JnrSUc5AgwxbHnx9h+WBb+JpdFvRRn9NhAgVfMkb01+p7VmoCJmHq+7qfBUCZRhqFErzHeNMcl2T7kPzQoWoJb93LPT3ym5cqQN0zdfT1c20rvO671iI2Ox3+J1uiUWCyXtNQ5wPhXDJ58gHnuR8rYB04r1T9lEw+m6ZqABXT2eQz4qKvvebKAQn3lM/STxnFPTYHAaUpP0sViZemhM83etghPjAyf9MTSBlkPRgUeXWFSbsyq/RZvxzeqpLGpzilNM6qV7V5F0/3XbjtfPPNaovCuEGtT1oFsiKzC6UR8kXtj4Pc= root@my-ncn-m001-pit"
    }
    ```

If the key on the BMC does not match the key used by ConMan, then the ConMan sessions will not have permission to access
the consoles. Proceed to resetting the SSH keys to resolve the issue.

## Procedure to Reset SSH keys

> **`NOTE`** this procedure has changed since the CSM 0.9 release.

1. (`ncn-mw#`) Scale the `cray-console-operator` pods to 0 replicas.

    ```bash
    kubectl -n services scale --replicas=0 deployment/cray-console-operator
    ```

    Example output:

    ```text
    deployment.apps/cray-console-operator scaled
    ```

1. (`ncn-mw#`) Verify that the `cray-console-operator` service is no longer running.

    The following command will give no output when the pod is no longer running.

    ```bash
    kubectl -n services get pods | grep console-operator
    ```

1. (`ncn-mw#`) Delete the SSH keys in a `cray-console-node` pod.

    ```bash
    kubectl -n services exec -it cray-console-node-0 -- rm -v /var/log/console/conman.key /var/log/console/conman.key.pub
    ```

1. (`ncn-mw#`) Restart the `cray-console-operator` pod.

    ```bash
    kubectl -n services scale --replicas=1 deployment/cray-console-operator
    ```

    Example output:

    ```text
    deployment.apps/cray-console-operator scaled
    ```

    It may take some time to regenerate the keys and get them deployed to the BMCs,
    but after a while the console connections using SSH should be reestablished. Note
    that it may be worthwhile to determine how the SSH key was modified and
    establish site procedures to coordinate SSH key use; otherwise they may be
    overwritten again at a later time.
