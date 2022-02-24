
## Configure a Broker UAI Class

Configuring a broker UAI class consists of the following:

* Create volumes to hold any site-specific authentication, SSH, or other configuration required
* Choose the end-user UAI class for which the broker UAI will serve instances
* [Create a UAI Class](Create_a_UAI_Class.md) with (at a minimum):
  * `namespace` set to `uas`
  * `default` set to `false`
  * `volume_mounts` set to the list of customization volume-ids created above
  * `public_ip` set to `true`
  * `uai_compute_network` set to `false`
  * `uai_creation_class` set to the class-id of the end-user UAI class


### Example of Volumes to Connect Broker UAIs to LDAP

Broker UAIs authenticate users in SSH, and pass the SSH connection on to the selected or created end-user UAI. An authentication source is required to authenticate users. For sites that use LDAP as a directory server for authentication, connecting broker UAIs to LDAP is simply a matter of replicating the LDAP configuration used by other nodes or systems at the site (UANs can be a good source of this configuration) inside the broker UAI. This section shows how to do that using volumes, which permits the standard broker UAI image to be used out of the box and reconfigured externally.

While it would be possible to make the configuration available as files volume mounted from the host node of the broker UAI, this is difficult to set up and maintain because it means that the configuration files must be present and synchronized across all UAI host nodes. A more practical approach to this is to install the configuration files in Kubernetes as secrets, and then mount them from Kubernetes directly. This ensures that no matter where a broker UAI runs, it has access to the configuration.

This example, uses Kubernetes secrets and assumes that the broker UAIs run in the `uas` Kubernetes namespace. If a different namespace is used, the creation of the ConfigMaps is different but the contents are the same. Using a namespace other than `uas` for broker UAIs is not recommended and is beyond the scope of this document.

1. Configure LDAP and determine which files need to be changed in the broker UAI and what their contents should be.

    In this example, the file is `/etc/sssd/sssd.conf` and its contents are (the contents have been sanitized, substitute appropriate contents in their place):

    ```
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

        ```
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

        ```
        ncn-m001-pit# kubectl create secret generic -n uas broker-sssd-conf --from-file=sssd.conf
        ```

  3. Make a volume for the secret in the UAS configuration.

     ```
     ncn-m001-pit# cray uas admin config volumes create --mount-path /etc/sssd --volume-description '{"secret": {"secret_name": "broker-sssd-conf", "default_mode": 384}}' --volumename broker-sssd-config
     mount_path = "/etc/sssd"
     volume_id = "4dc6691e-e7d9-4af3-acde-fc6d308dd7b4"
     volumename = "broker-sssd-config"

     [volume_description.secret]
     default_mode = 384
     secret_name = "broker-sssd-conf"
     ```

     Two important things to notice here are:

     * The secret is mounted on the directory `/etc/sssd` not the file `/etc/sssd/sssd.conf` because Kubernetes does not permit the replacement of an existing regular file with a volume but does allow overriding a directory
     * The value `384` is used here for the default mode of the file instead of `0600`, which would be easier to read, because JSON does not accept octal numbers in the leading zero form

4. Obtain the information needed to create a UAI class for the broker UAI containing the updated configuration in the volume list.

   The image-id of the broker UAI image, the volume-ids of the volumes to be added to the broker class, and the class-id of the end-user UAI class managed by the broker are required:

   ```
   ncn-m001-pit# cray uas admin config images list
   [[results]]
   default = false
   image_id = "c5dcb261-5271-49b3-9347-afe7f3e31941"
   imagename = "dtr.dev.cray.com/cray/cray-uai-broker:latest"

   [[results]]
   default = false
   image_id = "c5f6377a-dfc0-41da-89c9-6c88c8a2cda8"
   imagename = "dtr.dev.cray.com/cray/cray-uas-sles15:latest"

   [[results]]
   default = true
   image_id = "ff86596e-9699-46e8-9d49-9cb20203df8c"
   imagename = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"

   ncn-m001-pit# cray uas admin config volumes list | grep -e volume_id -e volumename
   volume_id = "4dc6691e-e7d9-4af3-acde-fc6d308dd7b4"
   volumename = "broker-sssd-config"
   volume_id = "55a02475-5770-4a77-b621-f92c5082475c"
   volumename = "timezone"
   volume_id = "7aeaf158-ad8d-4f0d-bae6-47f8fffbd1ad"
   volumename = "munge-key"
   volume_id = "9fff2d24-77d9-467f-869a-235ddcd37ad7"
   volumename = "lustre"
   volume_id = "ea97325c-2b1d-418a-b3b5-3f6488f4a9e2"
   volumename = "slurm-config"

   ncn-m001-pit# cray uas admin config classes list | grep -e class_id -e comment
   class_id = "a623a04a-8ff0-425e-94cc-4409bdd49d9c"
   comment = "UAI User Class"
   class_id = "bb28a35a-6cbc-4c30-84b0-6050314af76b"
   comment = "Non-Brokered UAI User Class"
   ```

5. Create the broker UAI class with the content retrieved in the previous step.

   ```
   ncn-m001-pit# cray uas admin config classes create --image-id c5dcb261-5271-49b3-9347-afe7f3e31941 --volume-list '4dc6691e-e7d9-4af3-acde-fc6d308dd7b4,55a02475-5770-4a77-b621-f92c5082475c,9fff2d24-77d9-467f-869a-235ddcd37ad7' --uai-compute-network no --public-ip yes --comment "UAI broker class" --uai-creation-class a623a04a-8ff0-425e-94cc-4409bdd49d9c --namespace uas
   class_id = "74970cdc-9f94-4d51-8f20-96326212b468"
   comment = "UAI broker class"
   default = false
   namespace = "uas"
   opt_ports = []
   priority_class_name = "uai-priority"
   public_ip = true
   uai_compute_network = false
   uai_creation_class = "a623a04a-8ff0-425e-94cc-4409bdd49d9c"
   [[volume_mounts]]
   mount_path = "/etc/sssd"
   volume_id = "4dc6691e-e7d9-4af3-acde-fc6d308dd7b4"
   volumename = "broker-sssd-config"

   [volume_mounts.volume_description.secret]
   default_mode = 384
   secret_name = "broker-sssd-conf"
   [[volume_mounts]]
   mount_path = "/etc/localtime"
   volume_id = "55a02475-5770-4a77-b621-f92c5082475c"
   volumename = "timezone"

   [volume_mounts.volume_description.host_path]
   path = "/etc/localtime"
   type = "FileOrCreate"
   [[volume_mounts]]
   mount_path = "/lus"
   volume_id = "9fff2d24-77d9-467f-869a-235ddcd37ad7"
   volumename = "lustre"

   [volume_mounts.volume_description.host_path]
   path = "/lus"
   type = "DirectoryOrCreate"

   [uai_image]
   default = false
   image_id = "c5dcb261-5271-49b3-9347-afe7f3e31941"
   imagename = "dtr.dev.cray.com/cray/cray-uai-broker:latest"
   ```

