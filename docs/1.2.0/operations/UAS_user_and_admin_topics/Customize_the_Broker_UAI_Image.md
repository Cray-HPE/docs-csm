# Customize the Broker UAI Image

The Broker UAI image that comes with UAS is the image used to construct Broker UAIs.

The key pieces of the Broker UAI image are:

* An `entrypoint` shell script that initializes the container and starts the SSH daemon running.
* An SSH configuration that forces logged in users into the `switchboard` command which creates / selects End-User UAIs and redirects connections.

The primary way to customize the Broker UAI image is by [defining volumes and connecting them to the Broker UAI class](Configure_a_Broker_UAI_Class.md) for a given broker.
Some customizations may require action that cannot be covered simply by using volumes to override configuration. Those cases generally require changing the Broker UAI behavior in some way.
Those cases can be covered either by volume mounting a customized `entrypoint` script, or volume mounting a customized SSH configuration. Both of these cases are shown in the following examples.

## Customize the Broker UAI `entrypoint` Script

The Broker UAI `entrypoint` script runs once every time the Broker UAI starts. It resides at `/app/broker/entrypoint.sh` in the Broker UAI image.
The `entrypoint` script is the only file in that directory, so it can be overridden by creating a Kubernetes ConfigMap in the `uas` namespace containing the modified script and creating a volume using that ConfigMap with a mount point of `/app/broker`.
There is critical content in the `entrypoint` script that should not be modified.

The following shows the contents of an unmodified script:

```bash
#!/bin/bash

# MIT License
#
# (C) Copyright [2020] Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

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

Starting at the top:

* `pam_config ...` can be customized to set up PAM as needed. The configuration here assumes the broker is using SSSD to reach a directory server for authentication and that,
  if a home directory is not present for a user at login, one should be made on the broker.
* The `ssh-keygen...` part is needed to set up the SSH host key for the broker and should be left alone.
* The `UAI_CREATION_CLASS` code should be left alone, as it sets up information used by `switchboard` to create End-User UAIs.
* The `/usr/sbin/sshd...` part starts the SSH server on the broker and should be left alone. Configuration of SSH is covered in the next section and is done by replacing `/etc/switchboard/sshd_config` not by modifying this line.
* The `sssd` part assumes the broker is using SSSD to reach a directory server, it can be changed as needed.
* The `sleep infinity` prevents the script from exiting which keeps the Broker UAI running. It should not be removed or altered.

As long as the basic flow and contents described here are honored, other changes to this script should work without compromising the Broker UAI's function.

The following is an example of replacing the `entrypoint` script with a new `entrypoint` script that changes the SSSD invocation to explicitly specify the `sssd.conf` file path (the standard path is used here,
but a different path might make customizing SSSD for a given site simpler under some set of circumstances):

1. Create a new `entrypoint` script.

    **NOTE:** A special "here document" form is used to prevent variable substitution in the file.

    ```bash
    ncn-m001-pit# cat <<-"EOF" > entrypoint.sh
    #!/bin/bash

    # MIT License
    #
    # (C) Copyright [2020] Hewlett Packard Enterprise Development LP
    #
    # Permission is hereby granted, free of charge, to any person obtaining a
    # copy of this software and associated documentation files (the "Software"),
    # to deal in the Software without restriction, including without limitation
    # the rights to use, copy, modify, merge, publish, distribute, sublicense,
    # and/or sell copies of the Software, and to permit persons to whom the
    # Software is furnished to do so, subject to the following conditions:
    #
    # The above copyright notice and this permission notice shall be included
    # in all copies or substantial portions of the Software.
    #
    # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    # THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
    # OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
    # ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    # OTHER DEALINGS IN THE SOFTWARE.

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
    ```

2. Create a new ConfigMap with the content from the script.

    ```bash
    ncn-m001-pit# kubectl create configmap -n uas broker-entrypoint --from-file=entrypoint.sh
    ```

3. Create a new volume.

    **NOTE**: The `default_mode` setting, which will set the mode on the file `/app/broker/entrypoint.sh` is decimal 493 here instead of octal 0755. The octal notation is not permitted in a JSON specification. Decimal numbers have to be used.

    ```bash
    ncn-m001-pit# cray uas admin config volumes create --mount-path /app/broker --volume-description '{"config_map": {"name": "broker-entrypoint", "default_mode": 493}}' --volumename broker-entrypoint
    ```

    Example output:

    ```bash
    mount_path = "/app/broker"
    volume_id = "2246bbb1-4006-4b11-ba57-6588a7b7c02f"
    volumename = "broker-entrypoint"

    [volume_description.config_map]
    default_mode = 493
    name = "broker-entrypoint"
    ```

4. List the UAI classes.

    ```bash
    ncn-m001-pit# cray uas admin config classes list | grep -e class_id -e comment
    ```

    Example output:

    ```bash
    class_id = "5eb523ba-a3b7-4a39-ba19-4cfe7d19d296"
    comment = "UAI Class to Create Non-Brokered End-User UAIs"
    class_id = "bdb4988b-c061-48fa-a005-34f8571b88b4"
    comment = "UAI Class to Create Brokered End-User UAIs"
    comment = "Resource Specification to use with Brokered End-User UAIs"
    class_id = "d764c880-41b8-41e8-bacc-f94f7c5b053d"
    comment = "UAI broker class"
    ```

5. Describe the desired UAI class.

    ```bash
    ncn-m001-pit# cray uas admin config classes describe d764c880-41b8-41e8-bacc-f94f7c5b053d --format yaml
    ```

    Example output:

    ```bash
    class_id: d764c880-41b8-41e8-bacc-f94f7c5b053d
    comment: UAI broker class
    default: false
    image_id: 8f180ddc-37e5-4ead-b261-2b401914a79f
    namespace: uas
    opt_ports: []
    priority_class_name: uai-priority
    public_ip: true
    replicas: 1
    resource_config:
    resource_id:
    service_account:
    timeout:
    tolerations:
    uai_compute_network: false
    uai_creation_class: bdb4988b-c061-48fa-a005-34f8571b88b4
    uai_image:
      default: false
      image_id: 8f180ddc-37e5-4ead-b261-2b401914a79f
      imagename: registry.local/cray/cray-uai-broker:1.2.4
    volume_list:
    - 11a4a22a-9644-4529-9434-d296eef2dc48
    - 1ec36af0-d5b6-4ad9-b3e8-755729765d76
    - a3b149fd-c477-41f0-8f8d-bfcee87fdd0a
    volume_mounts:
    - mount_path: /etc/localtime
      volume_description:
        host_path:
          path: /etc/localtime
          type: FileOrCreate
      volume_id: 11a4a22a-9644-4529-9434-d296eef2dc48
      volumename: timezone
    - mount_path: /etc/sssd
      volume_description:
        secret:
          default_mode: 384
          secret_name: broker-sssd-conf
      volume_id: 1ec36af0-d5b6-4ad9-b3e8-755729765d76
      volumename: broker-sssd-config
    - mount_path: /lus
      volume_description:
        host_path:
          path: /lus
          type: DirectoryOrCreate
      volume_id: a3b149fd-c477-41f0-8f8d-bfcee87fdd0a
      volumename: lustre
    ```

6. Update the UAI class.

    ```bash
    ncn-m001-pit# cray uas admin config classes update \
    --volume-list '11a4a22a-9644-4529-9434-d296eef2dc48,1ec36af0-d5b6-4ad9-b3e8-755729765d76,2246bbb1-4006-4b11-ba57-6588a7b7c02f,a3b149fd-c477-41f0-8f8d-bfcee87fdd0a' \
    d764c880-41b8-41e8-bacc-f94f7c5b053d --format yaml
    ```

    Example output:

    ```text
    class_id: d764c880-41b8-41e8-bacc-f94f7c5b053d
    comment: UAI broker class
    default: false
    image_id: 8f180ddc-37e5-4ead-b261-2b401914a79f
    namespace: uas
    opt_ports: []
    priority_class_name: uai-priority
    public_ip: true
    replicas: 1
    resource_config:
    resource_id:
    service_account:
    timeout:
    tolerations:
    uai_compute_network: false
    uai_creation_class: bdb4988b-c061-48fa-a005-34f8571b88b4
    uai_image:
      default: false
      image_id: 8f180ddc-37e5-4ead-b261-2b401914a79f
      imagename: registry.local/cray/cray-uai-broker:1.2.4
    volume_list:
    - 11a4a22a-9644-4529-9434-d296eef2dc48
    - 1ec36af0-d5b6-4ad9-b3e8-755729765d76
    - 2246bbb1-4006-4b11-ba57-6588a7b7c02f
    - a3b149fd-c477-41f0-8f8d-bfcee87fdd0a
    volume_mounts:
    - mount_path: /etc/localtime
      volume_description:
        host_path:
          path: /etc/localtime
          type: FileOrCreate
      volume_id: 11a4a22a-9644-4529-9434-d296eef2dc48
      volumename: timezone
    - mount_path: /etc/sssd
      volume_description:
        secret:
          default_mode: 384
          secret_name: broker-sssd-conf
      volume_id: 1ec36af0-d5b6-4ad9-b3e8-755729765d76
      volumename: broker-sssd-config
    - mount_path: /app/broker
      volume_description:
        config_map:
          default_mode: 493
          name: broker-entrypoint
      volume_id: 2246bbb1-4006-4b11-ba57-6588a7b7c02f
      volumename: broker-entrypoint
    - mount_path: /lus
      volume_description:
        host_path:
          path: /lus
          type: DirectoryOrCreate
      volume_id: a3b149fd-c477-41f0-8f8d-bfcee87fdd0a
      volumename: lustre
    ```

7. After the Broker UAI class is updated, all that remains is to clear out any existing End-User UAIs (existing UAIs will not work with the new broker because the new broker will have a new key-pair shared with its UAIs)
   and the existing Broker UAI (if any) and create a new Broker UAI.

    **NOTE:** Clearing out existing UAIs will terminate any user activity on those UAIs, make sure that users are warned of the disruption.

    1. Clear out the UAIs.

        ```bash
        ncn-m001-pit# cray uas admin uais delete --class-id bdb4988b-c061-48fa-a005-34f8571b88b4
        ncn-m001-pit# cray uas admin uais delete --class-id d764c880-41b8-41e8-bacc-f94f7c5b053d
        ```

        Output similar to `results = [ "Successfully deleted uai-vers-e937b810",]` will be returned for each command.

    2. Restart the broker.

        ```bash
        ncn-m001-pit# cray uas admin uais create --class-id d764c880-41b8-41e8-bacc-f94f7c5b053d --owner broker
        ```

        Example output:

        ```bash
        uai_age = "0m"
        uai_connect_string = "ssh broker@34.136.140.107"
        uai_host = "ncn-w003"
        uai_img = "registry.local/cray/cray-uai-broker:1.2.4"
        uai_ip = "34.136.140.107"
        uai_msg = ""
        uai_name = "uai-broker-f5bfb28c"
        uai_status = "Running: Ready"
        username = "broker"

        [uai_portmap]
        ```

## Customize the Broker UAI SSH Configuration

The SSH configuration used on Broker UAIs resides in `/etc/switchboard/sshd_config` and contains the following:

```bash
Port 30123
AuthorizedKeysFile  .ssh/authorized_keys
UsePAM yes
X11Forwarding yes
Subsystem sftp  /usr/lib/ssh/sftp-server
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

* `Port 30123` tells SSHD to listen on a port that can be reached through port forwarding by the publicly visible Kubernetes service.
* The `UseDNS no` avoids any DNS issues resulting from the Broker UAI running in the Kubernetes network space.
* The `permitTTY yes` setting permits interactive UAI logins.
* The `ForceCommand ...` statement ensures that users are always sent on to End-User UAIs or drop out of the Broker UAI on failure, preventing users from directly accessing the Broker UAI.
* The `AcceptEnv UAI_ONE_SHOT` setting is not required, but it allows a user to set the `UAI_ONE_SHOT` variable which instructs the broker to delete any created End-User UAI after the user logs out.

These should be left unchanged. The rest of the configuration can be customized as needed.

The following is an example that follows on from the previous section and configures SSH to provide a pre-login banner. Both a new `banner` file and a new `sshd_config` are placed in a Kubernetes ConfigMap and mounted over `/etc/switchboard`:

1. Create a new pre-login `banner` file.

    **NOTE:** A special "here document" form is used to prevent variable substitution in the file.

    ```bash
    ncn-m001-pit# cat <<-"EOF" > banner
    Here is a banner that will be displayed before login on
    the Broker UAI

    EOF
    ```

2. Create a new `sshd_config`.

    **NOTE:** A special "here document" form is used to prevent variable substitution in the file.

    ```bash
    ncn-m001-pit# cat <<-"EOF" > sshd_config
    Port 30123
    AuthorizedKeysFile  .ssh/authorized_keys
    UsePAM yes
    X11Forwarding yes
    Subsystem sftp  /usr/lib/ssh/sftp-server
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
    ```

3. Add the new `banner` file and `sshd_config` to a Kubernetes ConfigMap.

    ```bash
    ncn-m001-pit# kubectl create configmap -n uas broker-sshd-conf --from-file sshd_config --from-file banner
    ```

4. Mount the changes over `/etc/switchboard`.

    ```bash
    ncn-m001-pit# cray uas admin config volumes create \
                --mount-path /etc/switchboard \
                --volume-description '{"config_map": {"name": "broker-sshd-conf", "default_mode": 384}}' \
                --volumename broker-sshd-config
    ```

    Example output:

    ```bash
    mount_path = "/etc/switchboard"
    volume_id = "4577eddf-d81e-40c9-9c91-082f3193edd6"
    volumename = "broker-sshd-config"

    [volume_description.config_map]
    default_mode = 384
    name = "broker-sshd-conf"
    ```

5. Update the UAI class.

    ```bash
    ncn-m001-pit# cray uas admin config classes update \
    --volume-list '4577eddf-d81e-40c9-9c91-082f3193edd6,11a4a22a-9644-4529-9434-d296eef2dc48,1ec36af0-d5b6-4ad9-b3e8-755729765d76,2246bbb1-4006-4b11-ba57-6588a7b7c02f,a3b149fd-c477-41f0-8f8d-bfcee87fdd0a' \
    d764c880-41b8-41e8-bacc-f94f7c5b053d --format yaml
    ```

    Example output:

    ```bash
    class_id: d764c880-41b8-41e8-bacc-f94f7c5b053d
    comment: UAI broker class
    default: false
    image_id: 8f180ddc-37e5-4ead-b261-2b401914a79f
    namespace: uas
    opt_ports: []
    priority_class_name: uai-priority
    public_ip: true
    replicas: 1
    resource_config:
    resource_id:
    service_account:
    timeout:
    tolerations:
    uai_compute_network: false
    uai_creation_class: bdb4988b-c061-48fa-a005-34f8571b88b4
    uai_image:
      default: false
      image_id: 8f180ddc-37e5-4ead-b261-2b401914a79f
      imagename: registry.local/cray/cray-uai-broker:1.2.4
    volume_list:
    - 4577eddf-d81e-40c9-9c91-082f3193edd6
    - 11a4a22a-9644-4529-9434-d296eef2dc48
    - 1ec36af0-d5b6-4ad9-b3e8-755729765d76
    - 2246bbb1-4006-4b11-ba57-6588a7b7c02f
    - a3b149fd-c477-41f0-8f8d-bfcee87fdd0a
    volume_mounts:
    - mount_path: /etc/switchboard
      volume_description:
        config_map:
          default_mode: 384
          name: broker-sshd-conf
      volume_id: 4577eddf-d81e-40c9-9c91-082f3193edd6
      volumename: broker-sshd-config
    - mount_path: /etc/localtime
      volume_description:
        host_path:
          path: /etc/localtime
          type: FileOrCreate
      volume_id: 11a4a22a-9644-4529-9434-d296eef2dc48
      volumename: timezone
    - mount_path: /etc/sssd
      volume_description:
        secret:
          default_mode: 384
          secret_name: broker-sssd-conf
      volume_id: 1ec36af0-d5b6-4ad9-b3e8-755729765d76
      volumename: broker-sssd-config
    - mount_path: /app/broker
      volume_description:
        config_map:
          default_mode: 493
          name: broker-entrypoint
      volume_id: 2246bbb1-4006-4b11-ba57-6588a7b7c02f
      volumename: broker-entrypoint
    - mount_path: /lus
      volume_description:
        host_path:
          path: /lus
          type: DirectoryOrCreate
      volume_id: a3b149fd-c477-41f0-8f8d-bfcee87fdd0a
      volumename: lustre
    ```

6. Once the new configuration is installed, clean out the old UAIs and restart the broker.

    **NOTE:** Clearing out existing UAIs will terminate any user activity on those UAIs, make sure that users are warned of the disruption.

    1. Clean out the old UAIs.

        ```bash
        ncn-m001-pit# cray uas admin uais delete --class-id bdb4988b-c061-48fa-a005-34f8571b88b4

        ncn-m001-pit#  cray uas admin uais delete --class-id d764c880-41b8-41e8-bacc-f94f7c5b053d
        ```

        Output similar to `results = [ "Successfully deleted uai-vers-e937b810",]` will be returned for each command.

    2. Restart the broker.

        ```bash
        ncn-m001-pit# cray uas admin uais create --class-id d764c880-41b8-41e8-bacc-f94f7c5b053d --owner broker
        ```

        Example output:

        ```bash
        uai_age = "0m"
        uai_connect_string = "ssh broker@104.197.32.33"
        uai_host = "ncn-w003"
        uai_img = "registry.local/cray/cray-uai-broker:1.2.4"
        uai_ip = "104.197.32.33"
        uai_msg = "PodInitializing"
        uai_name = "uai-broker-ed144660"
        uai_status = "Waiting"
        username = "broker"

        [uai_portmap]
        ```

7. Connect to the broker to log in:

    ```bash
    vers> ssh vers@104.197.32.33
    Here is a banner that will be displayed before login to SSH
    on Broker UAIs
    Password:
    ```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Customize End-User UAI Images](Customize_End-User_UAI_Images.md)
