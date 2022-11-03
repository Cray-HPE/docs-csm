# Configure a Broker UAI Class

Configuring a Broker UAI class consists of the following actions:

* Create volumes to hold any site-specific authentication, SSH, or other configuration required
* Choose the End-User UAI class for which the Broker UAI will serve instances
* [Create a UAI Class](Create_a_UAI_Class.md) with (at a minimum):
  * `namespace` set to `uas`
  * `default` set to `false`
  * `volume_mounts` set to the list of customization volume-ids created above
  * `public_ip` set to `true`
  * `uai_compute_network` set to `false`
  * `uai_creation_class` set to the class-id of the End-User UAI class

The basic contents of a Broker UAI Class is discussed in [UAI Classes](UAI_Classes.md). Familiarity with that information is assumed in the example below.

## Example of Volumes to Connect Broker UAIs to LDAP

Broker UAIs authenticate each user using SSH, and pass the SSH connection on to the selected or created End-User UAI for that user. An authentication source is required to authenticate users.
For sites that use LDAP as a directory server for authentication, connecting Broker UAIs to LDAP is simply a matter of replicating the LDAP configuration used by other nodes or systems
at the site (UANs can be a good source of this configuration) inside the Broker UAI.
This section shows how to do that using [volumes](Volumes.md), which permits the standard Broker UAI image to be used out of the box and reconfigured at the site without direct modification.

While it would be possible to make the configuration available as files volume mounted from the host node of the Broker UAI,
this is difficult to set up and maintain because it means that the configuration files must be present and synchronized across all UAI host nodes.
A more practical approach to this is to install the configuration files in Kubernetes as secrets, and then mount them from Kubernetes directly. This ensures that no matter where a Broker UAI runs, it has access to the configuration.

This example uses Kubernetes secrets and assumes that the Broker UAIs run in the `uas` Kubernetes namespace. If a different namespace is used, the creation of the ConfigMaps is different but the contents are the same.
Using a namespace other than `uas` for Broker UAIs has implications beyond secrets and ConfigMaps; it is not recommended and is beyond the scope of this document.

1. Configure LDAP and determine which files need to be changed in the Broker UAI and what their contents should be.

    In this example, the file is `/etc/sssd/sssd.conf` and its contents are representative but sanitized. Substitute your own site specific contents:

    ```text
    [sssd]
      config_file_version = 2
      services = nss, pam
      domains = My_DC

    [nss]
      filter_users = root
      filter_groups = root

    [pam]

    [domain/My_DC]
      ldap_search_base=dc=datacenter,dc=mydomain,dc=com
      ldap_uri=ldap://10.1.1.5,ldap://10.1.2.5
      id_provider = ldap
      ldap_tls_reqcert = allow
      ldap_schema = rfc2307
      cache_credentials = True
      entry_cache_timeout = 60
      enumerate = False
    ```

2. Add the content from the previous step to a secret.

    1. Create a file with the appropriate content.

        ```bash
        ncn-m001-pit# cat <<EOF > sssd.conf
        [sssd]
        config_file_version = 2
        services = nss, pam
        domains = My_DC

        [nss]
        filter_users = root
        filter_groups = root

        [pam]

        [domain/My_DC]
        ldap_search_base=dc=datacenter,dc=mydomain,dc=com
        ldap_uri=ldap://10.1.1.5,ldap://10.1.2.5
        id_provider = ldap
        ldap_tls_reqcert = allow
        ldap_schema = rfc2307
        cache_credentials = True
        entry_cache_timeout = 60
        enumerate = False
        EOF
        ```

    2. Make a secret from the file.

        ```bash
        ncn-m001-pit# kubectl create secret generic -n uas broker-sssd-conf --from-file=sssd.conf
        ```

3. Make a volume for the secret in the UAS configuration.

     ```bash
     ncn-m001-pit# cray uas admin config volumes create \
                   --mount-path /etc/sssd \
                   --volume-description \
                   '{"secret": {"secret_name": "broker-sssd-conf", "default_mode": 384}}' \
                    --volumename broker-sssd-config
     ```

     Example output:

     ```text
     mount_path = "/etc/sssd"
     volume_id = "1ec36af0-d5b6-4ad9-b3e8-755729765d76"
     volumename = "broker-sssd-config"

     [volume_description.secret]
     default_mode = 384
     secret_name = "broker-sssd-conf"
     ```

     Two important things to notice here are:

     * The secret is mounted on the directory `/etc/sssd` not the file `/etc/sssd/sssd.conf` because Kubernetes does not permit the replacement of an existing regular file with a volume but does allow overriding a directory
     * The value `384` is used here for the default mode of the file instead of `0600`, which would be easier to read, because JSON does not accept octal numbers in the leading zero form

4. Make a volume to hold an empty and writable `/etc/sssd/conf.d` in the Broker UAI:

   ```bash
   ncn-m001# cray uas admin config volumes create --mount-path /etc/sssd/conf.d --volume-description '{"empty_dir": {"medium": "Memory"}}' --volumename sssd-conf-d --format yaml
   ```

   Example output:

   ```bash
   mount_path: /etc/sssd/conf.d
   volume_description:
     empty_dir:
       medium: Memory
   volume_id: 541980f9-fadc-41cd-8222-e2ffdb6421c4
   volumename: sssd-conf-d
   ```

5. Obtain the information needed to create a UAI class for the Broker UAI containing the updated configuration in the volume list.

   The image-id of the Broker UAI image, the volume-ids of the volumes to be added to the broker class, and the class-id of the End-User UAI class managed by the broker are required:

   ```bash
   ncn-m001-pit# cray uas admin config images list
   ```

   Example output:

   ```bash
   [[results]]
   default = true
   image_id = "1996c7f7-ca45-4588-bc41-0422fe2a1c3d"
   imagename = "registry.local/cray/cray-uai-sles15sp2:1.2.4"

   [[results]]
   default = false
   image_id = "5d2dd6a3-e9d3-43f1-aa3e-b9bf1589217d"
   imagename = "registry.local/cray/cray-uai-sanity-test:1.2.4"

   [[results]]
   default = false
   image_id = "8f180ddc-37e5-4ead-b261-2b401914a79f"
   imagename = "registry.local/cray/cray-uai-broker:1.2.4"

   ncn-m001-pit# cray uas admin config volumes list
   [[results]]
   mount_path = "/etc/localtime"
   volume_id = "11a4a22a-9644-4529-9434-d296eef2dc48"
   volumename = "timezone"

   [results.volume_description.host_path]
   path = "/etc/localtime"
   type = "FileOrCreate"
   [[results]]
   mount_path = "/etc/sssd"
   volume_id = "1ec36af0-d5b6-4ad9-b3e8-755729765d76"
   volumename = "broker-sssd-config"

   [results.volume_description.secret]
   default_mode = 384
   secret_name = "broker-sssd-conf"
   [[results]]
   mount_path = "/lus"
   volume_id = "a3b149fd-c477-41f0-8f8d-bfcee87fdd0a"
   volumename = "lustre"

   [results.volume_description.host_path]
   path = "/lus"
   type = "DirectoryOrCreate"
   [[results]]
   mount_path = "/etc/sssd/conf.d"
   volume_id = "541980f9-fadc-41cd-8222-e2ffdb6421c4"
   volumename = "sssd-conf-d"

   [results.volume_description.empty_dir]
   medium = "Memory"
   ```

6. Create the Broker UAI class with the content retrieved in the previous step.

    ```bash
    ncn-m001-pit#cray uas admin config classes create \
                --image-id 8f180ddc-37e5-4ead-b261-2b401914a79f \
                --volume-list 11a4a22a-9644-4529-9434-d296eef2dc48,1ec36af0-d5b6-4ad9-b3e8-755729765d76,a3b149fd-c477-41f0-8f8d-bfcee87fdd0a,541980f9-fadc-41cd-8222-e2ffdb6421c4 \
                --replicas 3 \
                --namespace uas \
                --uai-compute-network no \
                --public-ip yes \
                --comment "UAI broker class" \
                --uai-creation-class bdb4988b-c061-48fa-a005-34f8571b88b4
    ```

    Example output:

    ```text
    class_id = "d764c880-41b8-41e8-bacc-f94f7c5b053d"
    comment = "UAI broker class"
    default = false
    image_id = "8f180ddc-37e5-4ead-b261-2b401914a79f"
    namespace = "uas"
    opt_ports = []
    priority_class_name = "uai-priority"
    public_ip = true
    replicas = 3
    uai_compute_network = false
    uai_creation_class = "bdb4988b-c061-48fa-a005-34f8571b88b4"
    volume_list = [ "11a4a22a-9644-4529-9434-d296eef2dc48", "1ec36af0-d5b6-4ad9-b3e8-755729765d76", "a3b149fd-c477-41f0-8f8d-bfcee87fdd0a","541980f9-fadc-41cd-8222-e2ffdb6421c4"]
    [[volume_mounts]]
    mount_path = "/etc/localtime"
    volume_id = "11a4a22a-9644-4529-9434-d296eef2dc48"
    volumename = "timezone"

    [volume_mounts.volume_description.host_path]
    path = "/etc/localtime"
    type = "FileOrCreate"
    [[volume_mounts]]
    mount_path = "/etc/sssd"
    volume_id = "1ec36af0-d5b6-4ad9-b3e8-755729765d76"
    volumename = "broker-sssd-config"

    [volume_mounts.volume_description.secret]
    default_mode = 384
    secret_name = "broker-sssd-conf"
    [[volume_mounts]]
    mount_path = "/lus"
    volume_id = "a3b149fd-c477-41f0-8f8d-bfcee87fdd0a"
    volumename = "lustre"

    [volume_mounts.volume_description.host_path]
    path = "/lus"
    type = "DirectoryOrCreate"

    [[results.volume_mounts]]
    mount_path = "/etc/sssd/conf.d"
    volume_id = "541980f9-fadc-41cd-8222-e2ffdb6421c4"
    volumename = "sssd-conf-d"

    [results.volume_mounts.volume_description.empty_dir]
    medium = "Memory"

    [uai_image]
    default = false
    image_id = "8f180ddc-37e5-4ead-b261-2b401914a79f"
    imagename = "registry.local/cray/cray-uai-broker:1.2.4"
    ```

    **NOTE:** In some versions of UAS, SSSD will not start correctly when customized as described above because `/etc/sssd/sssd.conf` is mounted with the wrong mode in spite of being configured with the right mode.
    If SSSD is not working in a Broker UAI, refer to this [troubleshooting section](Troubleshoot_Broker_SSSD_Cant_Use_sssd_conf.md).

[Top: User Access Service (UAS)](index.md)

[Next Topic: Start a Broker UAI](Start_a_Broker_UAI.md)
