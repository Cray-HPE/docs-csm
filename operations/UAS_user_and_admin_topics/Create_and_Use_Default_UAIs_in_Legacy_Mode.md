# Create and Use Default UAIs in Legacy Mode

Create a UAI using the default UAI image or the default UAI class in legacy mode.

## Procedure

1. Create a UAI with a command of the following form:

    ```bash
    user> cray uas create --public-key '<path>'
    ```

    `<path>` is the path to a file containing an SSH public-key matched to the SSH private key belonging to the user.

2. Watch the UAI and see when it is ready for logins.

    ```bash
    user> cray uas list
    ```

3. Log into the UAI using the `ssh` command.

4. Delete the UAI when finished working with it.

    ```bash
    user> cray uas delete --uai-list '<uai-list>'
    ```

## Example UAI Lifecycle

In the following example, the user logs into the CLI using `cray auth login` with a user name and password matching that user's credentials in Keycloak.

```bash
vers> cray auth login
Username: vers
Password:
Success!

vers> cray uas list
results = []
```

From there the user creates a UAI. The UAI starts out in a `Pending` or `Waiting` state as Kubernetes constructs its pod and starts its container running.

```bash
vers> cray uas create --publickey ~/.ssh/id_rsa.pub
uai_age = "0m"
uai_connect_string = "ssh vers@34.136.140.107"
uai_host = "ncn-w002"
uai_img = "registry.local/cray/cray-uai-sles15sp2:1.2.4"
uai_ip = "34.136.140.107"
uai_msg = ""
uai_name = "uai-vers-01b26dd1"
uai_status = "Running: Ready"
username = "vers"

[uai_portmap]

vers> cray uas list
 cray uas list
[[results]]
uai_age = "1m"
uai_connect_string = "ssh vers@34.136.140.107"
uai_host = "ncn-w002"
uai_img = "registry.local/cray/cray-uai-sles15sp2:1.2.4"
uai_ip = "34.136.140.107"
uai_msg = ""
uai_name = "uai-vers-01b26dd1"
uai_status = "Running: Ready"
username = "vers"
```

Using `cray uas list`, the user watches the UAI until it reaches a `Running: Ready` state. The UAI is now ready to accept SSH logins from the user, and the user then logs into the UAI to run a simple Slurm job, and logs out.

```bash
vers> ssh vers@34.136.140.107
The authenticity of host '34.136.140.107 (34.136.140.107)' can't be established.
ECDSA key fingerprint is SHA256:5gU4SPiw8UvcX7s+xJfVMKULaUi3e0E3i+XA6AklEJA.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '34.136.140.107' (ECDSA) to the list of known hosts.
vers@uai-vers-01b26dd1-45tpc:~> ps -afe
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 14:50 ?        00:00:00 /bin/bash /usr/bin/uai-ssh.sh
root        45     1  0 14:50 ?        00:00:00 su vers -c /usr/sbin/sshd -e -f /etc/uas/ssh/sshd_config -D
vers        46    45  0 14:50 ?        00:00:00 /usr/sbin/sshd -e -f /etc/uas/ssh/sshd_config -D
vers       107    46  0 14:53 ?        00:00:00 sshd: vers [priv]
vers       110   107  0 14:53 ?        00:00:00 sshd: vers@pts/0
vers       111   110  0 14:53 pts/0    00:00:00 -bash
vers       148   111  0 14:53 pts/0    00:00:00 ps -afe
vers@uai-vers-01b26dd1-45tpc:~> exit
logout
Connection to 34.136.140.107 closed.
```

Now finished with the UAI, the user deletes it with `cray uas delete`. If the user has more than one UAI to delete, the argument to the `--uai-list` option can be a comma-separated list of UAI names.

```bash
vers> cray uas delete --uai-list uai-vers-01b26dd1
results = [ "Successfully deleted uai-vers-01b26dd1",]
```

[Top: User Access Service (UAS)](index.md)

[Next Topic: List Available UAI Images in Legacy Mode](List_Available_UAI_Images_in_Legacy_Mode.md)
