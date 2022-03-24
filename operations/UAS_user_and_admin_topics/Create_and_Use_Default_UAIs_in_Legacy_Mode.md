# Create and Use Default UAIs in Legacy Mode

Create a UAI using the default UAI image or the default UAI class in legacy mode.

### Procedure

1. Create a UAI with a command of the following form:

    ```
    user> cray uas create --public-key '<path>'
    ```

    `<path>` is the path to a file containing an SSH public-key matched to the SSH private key belonging to the user.

1. Watch the UAI and see when it is ready for logins.

    ```
    user> cray uas list
    ```

1. Log into the UAI using the `ssh` command.

1. Delete the UAI when finished working with it.

    ```
    user> cray uas delete --uai-list '<uai-list>'
    ```

### Example UAI Lifecycle

In the following example, the user logs into the CLI using `cray auth login` with a user name and password matching that user's credentials in Keycloak.

```
vers> cray auth login
Username: vers
Password:
Success!

vers> cray uas list
results = []
```

From there the user creates a UAI. The UAI starts out in a `Pending` or `Waiting` state as Kubernetes constructs its pod and starts its container running.

```
vers> cray uas create --publickey ~/.ssh/id_rsa.pub
uai_age = "0m"
uai_connect_string = "ssh vers@10.103.13.157"
uai_host = "ncn-w001"
uai_img = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
uai_ip = "10.103.13.157"
uai_msg = "ContainerCreating"
uai_name = "uai-vers-8ee103bf"
uai_status = "Waiting"
username = "vers"

[uai_portmap]

vers> cray uas list
[[results]]
uai_age = "0m"
uai_connect_string = "ssh vers@10.103.13.157"
uai_host = "ncn-w001"
uai_img = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
uai_ip = "10.103.13.157"
uai_msg = ""
uai_name = "uai-vers-8ee103bf"
uai_status = "Running: Ready"
username = "vers"
```

Using `cray uas list`, the user watches the UAI until it reaches a `Running: Ready` state. The UAI is now ready to accept SSH logins from the user, and the user then logs into the UAI to run a simple Slurm job, and logs out.

```
vers> ssh vers@10.103.13.157
The authenticity of host '10.103.13.157 (10.103.13.157)' can't be established.
ECDSA key fingerprint is SHA256:XQukF3V1q0Hh/aTiFmijhLMcaOzwAL+HjbM66YR4mAg.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.103.13.157' (ECDSA) to the list of known hosts.
vers@uai-vers-8ee103bf-95b5d774-88ssd:/tmp> sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
workq*       up   infinite      4   comp nid[000001-000004]
vers@uai-vers-8ee103bf-95b5d774-88ssd> srun -n 3 -N 3 hostname
nid000001
nid000002
nid000003
vers@uai-vers-8ee103bf-95b5d774-88ssd> exit
logout
Connection to 10.103.13.157 closed.
```

Now finished with the UAI, the user deletes it with `cray uas delete`. If the user has more than one UAI to delete, the argument to the `--uai-list` option can be a comma-separated list of UAI names.

```
vers> cray uas delete --uai-list uai-vers-8ee103bf
results = [ "Successfully deleted uai-vers-8ee103bf",]
```

