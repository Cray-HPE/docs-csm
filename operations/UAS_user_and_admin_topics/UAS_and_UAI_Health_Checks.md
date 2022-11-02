# UAS and UAI Legacy Mode Health Checks

Check the health of UAS and UAI to validate installation / upgrade of an HPE Cray EX system. This is a legacy mode procedure that can be run at installation / upgrade time to make sure that the following are true:

* UAS is installed and running correctly
* UAI images are installed and registered correctly
* UAIs can be created in legacy mode

## Initialize and Authorize the CLI

The procedures below use the CLI as an authorized user and run on two separate node types. The first part runs on the LiveCD node while the second part runs on a non-LiveCD Kubernetes master or worker node.
When using the CLI on either node, the CLI configuration must be initialized and the user running the procedure must be authorized.
This section describes how to initialize the CLI for use by a user and authorize the CLI as a user to run the procedures on any given node. The procedures will need to be repeated in both stages of the validation procedure.

## Discontinue Use of the `CRAY_CREDENTIALS` Service Account Token

Installation procedures leading up to production mode on Shasta use the CLI with a Kubernetes managed service account normally used for internal operations.
There is a procedure for extracting the OAUTH token for this service account and assigning it to the `CRAY_CREDENTIALS` environment variable to permit simple CLI operations.
The UAS / UAI validation procedure runs as a post-installation procedure and requires an actual user with Linux credentials, not this service account. Prior to running any of the steps below you must unset the `CRAY_CREDENTIALS` environment variable.

```bash
unset CRAY_CREDENTIALS
```

## Initialize the CLI Configuration

The CLI needs to know what host to use to obtain authorization and what user is requesting authorization so it can obtain an OAUTH token to talk to the API Gateway. This is accomplished by initializing the CLI configuration.
This example uses the `vers` username. In practice, `vers` and the response to the `password:` prompt should be replaced with the username and password of the administrator running the validation procedure.

To check whether the CLI needs initialization, run the following command.

```bash
cray config describe
```

If the output appears as follows, the CLI requires initialization.

```bash
Usage: cray config describe [OPTIONS]

Error: No configuration exists. Run `cray init`
```

If the output appears more like the following, then the CLI is initialized and logged in as `vers`. If that is the incorrect username, authorize the correct username and password in the next section.
If `vers` is the correct user, proceed to the validation procedure on that node.

If the CLI must be initialized again, use the following command and include the correct username, password, and the password response.

```bash
cray init
Cray Hostname: api-gw-service-nmn.local
Username: vers
Password:
Success!

Initialization complete.
```

## Authorize the Correct CLI User

If the CLI is initialized but authorized for a user different, run the following command and substitute the correct username and password.

```bash
cray auth login
Username: vers
Password:
Success!
```

**Authorization Is Local to a Host:** whenever you are using the CLI (`cray` command) on a host (e.g. a workstation or NCN) where it has not been used before, it is necessary to authenticate on that host using `cray auth login`.
There is no mechanism to distribute CLI authorization amongst hosts.

## Troubleshoot CLI Initialization or Authorization Issues

If initialization or authorization fails in any of the preceding steps, there are several common causes.

* DNS failure looking up `api-gw-service-nmn.local` may be preventing the CLI from reaching the API Gateway and Keycloak for authorization
* Network connectivity issues with the NMN may be preventing the CLI from reaching the API Gateway and Keycloak for authorization
* Certificate mismatch or trust issues may be preventing a secure connection to the API Gateway
* Istio failures may be preventing traffic from reaching Keycloak
* Keycloak may not yet be set up to authorize the current user

While resolving these issues is beyond the scope of this section, adding `-vvvvv` to the `cray auth` or `cray init` commands may offer clues as to why the initialization or authorization is failing.

## Validate the Basic UAS Installation

This procedure and the following procedures run on separate nodes on the system and validate the basic UAS installation.
Ensure this runs on the LiveCD node and that the CLI is authorized for the user.

```bash
cray uas mgr-info list
```

Example output:

```bash
service_name = "cray-uas-mgr"
version = "1.11.5"
```

```bash
ncn-m001-cray uas list
```

Example output:

```bash
results = []
```

This shows that UAS is installed and running version 1.11.5 and that no UAIs are running. If another user has been using the UAS, it is possible to see UAIs in the list.
That is acceptable from a validation standpoint.

To verify that the pre-made UAI images are registered with UAS, run the following command.

```bash
cray uas images list
```

Example output:

```bash
default_image = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
image_list = [ "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest",]
```

The output shows that the pre-made End-User UAI image, `cray/cray-uai-sles15sp1:latest`, is registered with UAS. This does not necessarily mean this image is installed in the container image registry, but it is configured for use.
If other UAI images have been created and registered, they may also appear in the output.

## Validate UAI Creation

The following are needed for this procedure:

* Must run on a master or worker node
* Must run on the HPE Cray EX system \(or from an external host, but the procedure for that is not covered here\)
* Requires that the CLI be initialized and authorized as for the current user

1. Verify that the user account can create a UAI.

    ```bash
    cray uas create --publickey ~/.ssh/id_rsa.pub
    ```

    Example output:

    ```bash
    uai_connect_string = "ssh vers@10.16.234.10"
    uai_host = "ncn-w001"
    uai_img = "registry.local/cray/cray-uai-sles15sp1:latest"
    uai_ip = "10.16.234.10"
    uai_msg = ""
    uai_name = "uai-vers-a00fb46b"
    uai_status = "Pending"
    username = "vers"

    [uai_portmap]
    ```

    The UAI is now created and in the process of initializing and running.

1. View the state of the UAI.

    The following can be repeated as many times as desired. If the results appear like the following, the UAI is ready for use.

    ```bash
    cray uas list
    ```

    Example output:

    ```bash
    [[results]]
    uai_age = "0m"
    uai_connect_string = "ssh vers@10.16.234.10"
    uai_host = "ncn-w001"
    uai_img = "registry.local/cray/cray-uai-sles15sp1:latest"
    uai_ip = "10.16.234.10"
    uai_msg = ""
    uai_name = "uai-vers-a00fb46b"
    uai_status = "Running: Ready"
    username = "vers"
    ```

1. Log into the UAI \(without a password\) as follows:

    1. SSH to the UAI.

        ```bash
        ssh vers@10.16.234.10
        ```

        Example output:

        ```bash
        The authenticity of host '10.16.234.10 (10.16.234.10)' can't be established.
        ECDSA key fingerprint is SHA256:BifA2Axg5O0Q9wqESkLqK4z/b9e1usiDUZ/puGIFiyk.
        Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
        Warning: Permanently added '10.16.234.10' (ECDSA) to the list of known hosts.
        ```

    1. List the processes.

        ```bash
        vers@uai-vers-a00fb46b-6889b666db-4dfvn:~> ps -afe
        ```

        Example output:

        ```bash
        UID          PID    PPID  C STIME TTY          TIME CMD
        root           1       0  0 18:51 ?        00:00:00 /bin/bash /usr/bin/uai-ssh.sh
        munge         36       1  0 18:51 ?        00:00:00 /usr/sbin/munged
        root          54       1  0 18:51 ?        00:00:00 su vers -c /usr/sbin/sshd -e -f /etc/uas/ssh/sshd_config -D
        vers          55      54  0 18:51 ?        00:00:00 /usr/sbin/sshd -e -f /etc/uas/ssh/sshd_config -D
        vers          62      55  0 18:51 ?        00:00:00 sshd: vers [priv]
        vers          67      62  0 18:51 ?        00:00:00 sshd: vers@pts/0
        vers          68      67  0 18:51 pts/0    00:00:00 -bash
        vers         120      68  0 18:52 pts/0    00:00:00 ps -afe
        ```

    1. Exit the connection.

        ```bash
        vers@uai-vers-a00fb46b-6889b666db-4dfvn:~> exit
        ```

1. Clean up the UAI and note that the UAI name used is the same as the name in the output from `cray uas create` above.

    ```bash
    cray uas delete --uai-list uai-vers-a00fb46b
    ```

    In this example, `results = [ "Successfully deleted uai-vers-a00fb46b",]` will be returned if successful.

## Troubleshoot UAS and UAI Operations Issues

**Authorization Issues:**

If the user is not logged in as a valid Keycloak user or is inadvertently using the `CRAY_CREDENTIALS` environment variable \(i.e. the variable is set if the user is logged in with their username or another username\),
the output of running `cray uas list` will produce output like the following.

```bash
cray uas list
Usage: cray uas list [OPTIONS]
Try 'cray uas list --help' for help.

Error: Bad Request: Token not valid for UAS. Attributes missing: ['gidNumber', 'loginShell', 'homeDirectory', 'uidNumber', 'name']
```

Fix this by logging in as a "real user" \(a user with Linux credentials\) and ensure that CRAY\_CREDENTIALS is unset.

## UAS Cannot Access Keycloak

If the output of `cray uas list` appears similar to the following, the wrong hostname to reach the API gateway may be in use. In that case, run the CLI initialization steps again.

```bash
cray uas list
Usage: cray uas list [OPTIONS]
Try 'cray uas list --help' for help.

Error: Internal Server Error: An error was encountered while accessing Keycloak
```

There also may be a problem with the Istio service mesh inside of the Shasta system.
Troubleshooting this is beyond the scope of this section, but viewing the UAS pod logs in Kubernetes may provide useful information.

There are typically two UAS pods. View logs from both pods to identify the specific failure. The logs have a very large number of GET events listed as part of the aliveness checking.
The following shows an example of viewing UAS logs \(the example shows only one UAS manage, normally there would be two\).

```bash
kubectl get po -n services | grep uas-mgr | grep -v etcd
```

Example output:

```bash
cray-uas-mgr-6bbd584ccb-zg8vx            2/2     Running            0          12d
kubectl logs -n services cray-uas-mgr-6bbd584ccb-zg8vx cray-uas-mgr | grep -v 'GET ' | tail -25
2021-02-08 15:32:41,211 - uas_mgr - INFO - getting deployment uai-vers-87a0ff6e in namespace user
2021-02-08 15:32:41,225 - uas_mgr - INFO - creating deployment uai-vers-87a0ff6e in namespace user
2021-02-08 15:32:41,241 - uas_mgr - INFO - creating the UAI service uai-vers-87a0ff6e-ssh
2021-02-08 15:32:41,241 - uas_mgr - INFO - getting service uai-vers-87a0ff6e-ssh in namespace user
2021-02-08 15:32:41,252 - uas_mgr - INFO - creating service uai-vers-87a0ff6e-ssh in namespace user
2021-02-08 15:32:41,267 - uas_mgr - INFO - getting pod info uai-vers-87a0ff6e
2021-02-08 15:32:41,360 - uas_mgr - INFO - No start time provided from pod
2021-02-08 15:32:41,361 - uas_mgr - INFO - getting service info for uai-vers-87a0ff6e-ssh in namespace user
127.0.0.1 - - [08/Feb/2021 15:32:41] "POST /v1/uas?imagename=registry.local%2Fcray%2Fno-image-registered%3Alatest HTTP/1.1" 200 -
2021-02-08 15:32:54,455 - uas_auth - INFO - UasAuth lookup complete for user vers
2021-02-08 15:32:54,455 - uas_mgr - INFO - UAS request for: vers
2021-02-08 15:32:54,455 - uas_mgr - INFO - listing deployments matching: host None, labels uas=managed,user=vers
2021-02-08 15:32:54,484 - uas_mgr - INFO - getting pod info uai-vers-87a0ff6e
2021-02-08 15:32:54,596 - uas_mgr - INFO - getting service info for uai-vers-87a0ff6e-ssh in namespace user
2021-02-08 15:40:25,053 - uas_auth - INFO - UasAuth lookup complete for user vers
2021-02-08 15:40:25,054 - uas_mgr - INFO - UAS request for: vers
2021-02-08 15:40:25,054 - uas_mgr - INFO - listing deployments matching: host None, labels uas=managed,user=vers
2021-02-08 15:40:25,085 - uas_mgr - INFO - getting pod info uai-vers-87a0ff6e
2021-02-08 15:40:25,212 - uas_mgr - INFO - getting service info for uai-vers-87a0ff6e-ssh in namespace user
2021-02-08 15:40:51,210 - uas_auth - INFO - UasAuth lookup complete for user vers
2021-02-08 15:40:51,210 - uas_mgr - INFO - UAS request for: vers
2021-02-08 15:40:51,210 - uas_mgr - INFO - listing deployments matching: host None, labels uas=managed,user=vers
2021-02-08 15:40:51,261 - uas_mgr - INFO - deleting service uai-vers-87a0ff6e-ssh in namespace user
2021-02-08 15:40:51,291 - uas_mgr - INFO - delete deployment uai-vers-87a0ff6e in namespace user
127.0.0.1 - - [08/Feb/2021 15:40:51] "DELETE /v1/uas?uai_list=uai-vers-87a0ff6e HTTP/1.1" 200 -
```

## UAI Images not in Registry

If output is similar to the following, the pre-made End-User UAI image is not in the user's local registry \(or whatever registry it is being pulled from, see the `uai_img` value for details\).
Locate and the image and push / import it to the registry.

```bash
cray uas list
```

Example output:

```bash
[[results]]
uai_age = "0m"
uai_connect_string = "ssh vers@10.103.13.172"
uai_host = "ncn-w001"
uai_img = "registry.local/cray/cray-uai-sles15sp1:latest"
uai_ip = "10.103.13.172"
uai_msg = "ErrImagePull"
uai_name = "uai-vers-87a0ff6e"
uai_status = "Waiting"
username = "vers"
```

## Missing Volumes and Other Container Startup Issues

Various packages install volumes in the UAS configuration. All of those volumes must also have the underlying resources available, sometimes on the host node where the UAI is running and sometimes from within Kubernetes.
If the UAI gets stuck with a `ContainerCreating` `uai_msg` field for an extended time, this is a likely cause.
UAIs run in the user Kubernetes namespace and are pods that can be examined using `kubectl describe`.

Run the following command to locate the pod.

```bash
kubectl get po -n user | grep <uai-name>
```

Run the following command to investigate the problem.

```bash
kubectl describe -n user <pod-name>
```

If volumes are missing, they will be in the `Events:section` of the output. Other problems may show up there as well.
The names of the missing volumes or other issues should indicate what needs to be fixed to enable the UAI.

[Top: User Access Service (UAS)](README.md)

[Next Topic: Troubleshoot UAS Issues](Troubleshoot_UAS_Issues.md)
