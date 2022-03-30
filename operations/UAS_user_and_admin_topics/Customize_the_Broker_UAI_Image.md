# Customize the Broker UAI Image

The broker UAI image that comes with UAS is the image used to construct broker UAIs.

The key pieces of the broker UAI image are:

* An entrypoint shell script that initializes the container and starts the SSH daemon running.
* An SSH configuration that forces logged in users into the `switchboard` command which creates / selects end-user UAIs and redirects connections.

The primary way to customize the broker UAI image is by defining volumes and connecting them to the broker UAI class for a given broker. An example of this is configuring the broker for LDAP is shown in [Configure a Broker UAI Class](Configure_a_Broker_UAI_Class.md). Some customizations may require action that cannot be covered simply by using a volume. Those cases can be covered either by volume mounting a customized entrypoint script, or volume mounting a customized SSH configuration. Both of these cases are shown in the following examples.

### Customize the Broker UAI Entrypoint Script

The broker UAI entrypoint script runs once every time the broker UAI starts. It resides at `/app/broker/entrypoint.sh` in the broker UAI image. The entrypoint script is the only file in that directory, so it can be overridden by creating a Kubernetes ConfigMap in the `uas` namespace containing the modified script and creating a volume using that ConfigMap with a mount point of `/app/broker`. There is critical content in the entrypoint script that should not be modified.

The following shows the contents of an unmodified script:

```
#!/bin/bash

# Copyright 2020 Hewlett Packard Enterprise Development LP

echo "Configure PAM to use sssd..."
pam-config -a --sss --mkhomedir

echo "Generating broker host keys..."
ssh-keygen -A

echo "Checking for UAI_CREATION_CLASS..."
if ! [ -z $UAI_CREATION_CLASS ]; then
    echo UAI_CREATION_CLASS=$UAI_CREATION_CLASS >> /etc/environment
fi

echo "Starting sshd..."
/usr/sbin/sshd -f /etc/switchboard/sshd_config

echo "Starting sssd..."
sssd

sleep infinity
```

Starting at the top, `pam_config ...` can be customized to set up PAM as needed. The configuration here assumes the broker is using SSSD to reach a directory server for authentication and that, if a home directory is not present for a user at login, one should be made on the broker. The `ssh-keygen...` part is needed to set up the SSH host key for the broker and should be left alone. The `UAI_CREATION_CLASS` code should be left alone, as it sets up information used by `switchboard` to create end-user UAIs. The `/usr/sbin/sshd...` part starts the SSH server on the broker and should be left alone. Configuration of SSH is covered in the next section and is done by replacing `/etc/switchboard/sshd_config` not by modifying this line. The `sssd` part assumes the broker is using SSSD to reach a directory server, it can be changed as needed. The `sleep infinity` prevents the script from exiting which keeps the broker UAI running. It should not be removed or altered. As long as the basic flow and contents described here are honored, other changes to this script should work without compromising the broker UAI's function.

The following is an example of replacing the entrypoint script with a new entrypoint script that changes the SSSD invocation to explicitly specify the `sssd.conf` file path (the standard path is used here, but a different path might make customizing SSSD for a given site simpler under some set of circumstances):

```
# Notice special here document form to prevent variable substitution in the file

ncn-m001-pit# cat <<-"EOF" > entrypoint.sh
#!/bin/bash

# Copyright 2020 Hewlett Packard Enterprise Development LP

echo "Configure PAM to use sssd..."
pam-config -a --sss --mkhomedir

echo "Generating broker host keys..."
ssh-keygen -A

echo "Checking for UAI_CREATION_CLASS..."
if ! [ -z $UAI_CREATION_CLASS ]; then
    echo UAI_CREATION_CLASS=$UAI_CREATION_CLASS >> /etc/environment
fi

echo "Starting sshd..."
/usr/sbin/sshd -f /etc/switchboard/sshd_config

echo "Starting sssd..."
# LOCAL MODIFICATION
# change the normal SSSD invocation
# sssd
# to specify the config file path
sssd --config /etc/sssd/sssd.conf
# END OF LOCAL MODIFICATION

sleep infinity
EOF

ncn-m001-pit# kubectl create configmap -n uas broker-entrypoint --from-file=entrypoint.sh

# Notice that the `default_mode` setting, which will set the mode on the file
# /app/broker/entrypoint.sh is decimal 493 here instead of octal 0755.
# The octal notation is not permitted in a JSON specification. Decimal
# numbers have to be used.

ncn-m001-pit# cray uas admin config volumes create --mount-path /app/broker --volume-description '{"config_map": {"name": "broker-entrypoint", "default_mode": 493}}' --volumename broker-entrypoint
mount_path = "/app/broker"
volume_id = "1f3bde56-b2e7-4596-ab3a-6aa4327d29c7"
volumename = "broker-entrypoint"

[volume_description.config_map]
default_mode = 493
name = "broker-entrypoint"

ncn-m001-pit# cray uas admin config classes list | grep -e class_id -e comment
class_id = "74970cdc-9f94-4d51-8f20-96326212b468"
comment = "UAI broker class"
class_id = "a623a04a-8ff0-425e-94cc-4409bdd49d9c"
comment = "UAI User Class"
class_id = "bb28a35a-6cbc-4c30-84b0-6050314af76b"
comment = "Non-Brokered UAI User Class"

ncn-m001-pit# cray uas admin config classes describe 74970cdc-9f94-4d51-8f20-96326212b468 --format yaml
class_id: 74970cdc-9f94-4d51-8f20-96326212b468
comment: UAI broker class
default: false
namespace: uas
opt_ports: []
priority_class_name: uai-priority
public_ip: true
resource_config:
uai_compute_network: false
uai_creation_class: a623a04a-8ff0-425e-94cc-4409bdd49d9c
uai_image:
  default: false
  image_id: c5dcb261-5271-49b3-9347-afe7f3e31941
  imagename: dtr.dev.cray.com/cray/cray-uai-broker:latest
volume_mounts:
- mount_path: /etc/sssd
  volume_description:
    secret:
      default_mode: 384
      secret_name: broker-sssd-conf
  volume_id: 4dc6691e-e7d9-4af3-acde-fc6d308dd7b4
  volumename: broker-sssd-config
- mount_path: /etc/localtime
  volume_description:
    host_path:
      path: /etc/localtime
      type: FileOrCreate
  volume_id: 55a02475-5770-4a77-b621-f92c5082475c
  volumename: timezone
- mount_path: /lus
  volume_description:
    host_path:
      path: /lus
      type: DirectoryOrCreate
  volume_id: 9fff2d24-77d9-467f-869a-235ddcd37ad7
  volumename: lustre

ncn-m001-pit# cray uas admin config classes update --volume-list '4dc6691e-e7d9-4af3-acde-fc6d308dd7b4,55a02475-5770-4a77-b621-f92c5082475c,9fff2d24-77d9-467f-869a-235ddcd37ad7,1f3bde56-b2e7-4596-ab3a-6aa4327d29c7' --format yaml 74970cdc-9f94-4d51-8f20-96326212b468
class_id: 74970cdc-9f94-4d51-8f20-96326212b468
comment: UAI broker class
default: false
namespace: uas
opt_ports: []
priority_class_name: uai-priority
public_ip: true
resource_config:
uai_compute_network: false
uai_creation_class: a623a04a-8ff0-425e-94cc-4409bdd49d9c
uai_image:
  default: false
  image_id: c5dcb261-5271-49b3-9347-afe7f3e31941
  imagename: dtr.dev.cray.com/cray/cray-uai-broker:latest
volume_mounts:
- mount_path: /etc/sssd
  volume_description:
    secret:
      default_mode: 384
      secret_name: broker-sssd-conf
  volume_id: 4dc6691e-e7d9-4af3-acde-fc6d308dd7b4
  volumename: broker-sssd-config
- mount_path: /etc/localtime
  volume_description:
    host_path:
      path: /etc/localtime
      type: FileOrCreate
  volume_id: 55a02475-5770-4a77-b621-f92c5082475c
  volumename: timezone
- mount_path: /lus
  volume_description:
    host_path:
      path: /lus
      type: DirectoryOrCreate
  volume_id: 9fff2d24-77d9-467f-869a-235ddcd37ad7
  volumename: lustre
- mount_path: /app/broker
  volume_description:
    config_map:
      default_mode: 493
      name: broker-entrypoint
  volume_id: 1f3bde56-b2e7-4596-ab3a-6aa4327d29c7
  volumename: broker-entrypoint
```

With the broker UAI class updated, all that remains is to clear out any existing end-user UAIs (existing UAIs will not work with the new broker because the new broker will have a new key-pair shared with its UAIs) and the existing broker UAI (if any) and create a new broker UAI.

**NOTE:** Clearing out existing UAIs will terminate any user activity on those UAIs, make sure that users are warned of the disruption.

```
ncn-m001-pit# cray uas admin uais delete --class-id a623a04a-8ff0-425e-94cc-4409bdd49d9c
results = [ "Successfully deleted uai-vers-ee6f427e",]

ncn-m001-pit# cray uas admin uais delete --class-id 74970cdc-9f94-4d51-8f20-96326212b468
results = [ "Successfully deleted uai-broker-11f36815",]

ncn-m001-pit# cray uas admin uais create --class-id 74970cdc-9f94-4d51-8f20-96326212b468 --owner broker
uai_connect_string = "ssh broker@10.103.13.162"
uai_img = "dtr.dev.cray.com/cray/cray-uai-broker:latest"
uai_ip = "10.103.13.162"
uai_msg = ""
uai_name = "uai-broker-a50407d5"
uai_status = "Pending"
username = "broker"

[uai_portmap]
```

### Customize the Broker UAI SSH Configuration

The SSH configuration used on broker UAIs resides in `/etc/switchboard/sshd_config` and contains the following:

```
Port 30123
AuthorizedKeysFile	.ssh/authorized_keys
UsePAM yes
X11Forwarding yes
Subsystem	sftp	/usr/lib/ssh/sftp-server
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL
AcceptEnv UAI_ONE_SHOT
UseDNS no

Match User !root,*
	PermitTTY yes
	ForceCommand /usr/bin/switchboard broker --class-id $UAI_CREATION_CLASS
```
The important content here is as follows:

* `Port 30123` tells sshd to listen on a port that can be reached through port forwarding by the publicly visible Kubernetes service.
* The `UseDNS no` avoids any DNS issues resulting from the broker UAI running in the Kubernetes network space.
* The `permitTTY yes` setting permits interactive UAI logins.
* The `ForceCommand ...` statement ensures that users are always sent on to end-user UAIs or drop out of the broker UAI on failure, preventing users from directly accessing the broker UAI.
* The `AcceptEnv UAI_ONE_SHOT` setting is not required, but it allows a user to set the UAI_ONE_SHOT variable which instructs the broker to delete any created end-user UAI after the user logs out.

These should be left unchanged. The rest of the configuration can be customized as needed.

The following is an example that follows on from the previous section and configures SSH to provide a pre-login banner. Both a new `banner` file and a new `sshd_config` are placed in a Kubernetes ConfigMap and mounted over `/etc/switchboard`:

```
# Notice special here document form to prevent variable substitution in the file

ncn-m001-pit# cat <<-"EOF" > banner
Here is a banner that will be displayed before login on
the broker UAI

EOF

# Notice special here document form to prevent variable substitution in the file

ncn-m001-pit# cat <<-"EOF" > sshd_conf
Port 30123
AuthorizedKeysFile	.ssh/authorized_keys
UsePAM yes
X11Forwarding yes
Subsystem	sftp	/usr/lib/ssh/sftp-server
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL
AcceptEnv UAI_ONE_SHOT
UseDNS no
Banner /etc/switchboard/banner

Match User !root,*
	PermitTTY yes
	ForceCommand /usr/bin/switchboard broker --class-id $UAI_CREATION_CLASS
EOF

ncn-m001-pit# kubectl create configmap -n uas broker-sshd-conf --from-file sshd_config --from-file banner

ncn-m001-pit# cray uas admin config volumes create --mount-path /etc/switchboard --volume-description '{"config_map": {"name": "broker-sshd-conf", "default_mode": 384}}' --volumename broker-sshd-config
mount_path = "/etc/switchboard"
volume_id = "d5058121-c1b6-4360-824d-3c712371f042"
volumename = "broker-sshd-config"

[volume_description.config_map]
default_mode = 384
name = "broker-sshd-conf"

ncn-m001-pit# cray uas admin config classes update --volume-list '4dc6691e-e7d9-4af3-acde-fc6d308dd7b4,55a02475-5770-4a77-b621-f92c5082475c,9fff2d24-77d9-467f-869a-235ddcd37ad7,1f3bde56-b2e7-4596-ab3a-6aa4327d29c7,d5058121-c1b6-4360-824d-3c712371f042' --format yaml 74970cdc-9f94-4d51-8f20-96326212b468
class_id: 74970cdc-9f94-4d51-8f20-96326212b468
comment: UAI broker class
default: false
namespace: uas
opt_ports: []
priority_class_name: uai-priority
public_ip: true
resource_config:
uai_compute_network: false
uai_creation_class: a623a04a-8ff0-425e-94cc-4409bdd49d9c
uai_image:
  default: false
  image_id: c5dcb261-5271-49b3-9347-afe7f3e31941
  imagename: dtr.dev.cray.com/cray/cray-uai-broker:latest
volume_mounts:
- mount_path: /etc/sssd
  volume_description:
    secret:
      default_mode: 384
      secret_name: broker-sssd-conf
  volume_id: 4dc6691e-e7d9-4af3-acde-fc6d308dd7b4
  volumename: broker-sssd-config
- mount_path: /etc/localtime
  volume_description:
    host_path:
      path: /etc/localtime
      type: FileOrCreate
  volume_id: 55a02475-5770-4a77-b621-f92c5082475c
  volumename: timezone
- mount_path: /lus
  volume_description:
    host_path:
      path: /lus
      type: DirectoryOrCreate
  volume_id: 9fff2d24-77d9-467f-869a-235ddcd37ad7
  volumename: lustre
- mount_path: /app/broker
  volume_description:
    config_map:
      default_mode: 493
      name: broker-entrypoint
  volume_id: 1f3bde56-b2e7-4596-ab3a-6aa4327d29c7
  volumename: broker-entrypoint
- mount_path: /etc/switchboard
  volume_description:
    config_map:
      default_mode: 384
      name: broker-sshd-conf
  volume_id: d5058121-c1b6-4360-824d-3c712371f042
  volumename: broker-sshd-config
```

With the new configuration installed, clean out the old UAIs and restart the broker:

**NOTE:** Clearing out existing UAIs will terminate any user activity on those UAIs, make sure that users are warned of the disruption.

```
ncn-m001-pit# cray uas admin uais delete --class-id a623a04a-8ff0-425e-94cc-4409bdd49d9c
results = [ "Successfully deleted uai-vers-e937b810",]

ncn-m001-pit# cray uas admin uais delete --class-id 74970cdc-9f94-4d51-8f20-96326212b468
results = [ "Successfully deleted uai-broker-a50407d5",]

ncn-m001-pit# cray uas admin uais create --class-id 74970cdc-9f94-4d51-8f20-96326212b468 --owner broker
uai_age = "0m"
uai_connect_string = "ssh broker@10.103.13.162"
uai_host = "ncn-w001"
uai_img = "dtr.dev.cray.com/cray/cray-uai-broker:latest"
uai_ip = "10.103.13.162"
uai_msg = "PodInitializing"
uai_name = "uai-broker-df7e6939"
uai_status = "Waiting"
username = "broker"

[uai_portmap]
```

To connect to the broker to log in:

```
vers> ssh vers@10.103.13.162
Here is a banner that will be displayed before login to SSH
on Broker UAIs
Password:
```

