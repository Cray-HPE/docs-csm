# Manage a Configuration with CFS

Many product streams need to use the Configuration Framework Service (CFS) to
apply post-boot configuration to the management nodes. This post-boot
configuration is known as NCN personalization.

NCN personalization applies post-boot configuration to the HPE Cray EX
management nodes. Many HPE Cray EX management services outside of CSM
(including DVS and SMA) require NCN personalization to function.

NCN Personalization is set up via the following steps:
1. Create and upload a configuration file for the NCNs to CFS. This file lists
   the Ansible playbooks and their location in the Version Control Service (VCS)
   that configure each NCN.
1. Set the desired configuration from the previous step in CFS for each
   management node requiring post-boot configuration. This step directs CFS to
   apply the configuration automatically to each node.

Hewlett Packard Enterprise recommends that the configurations for both CNs and
NCNs use the same git commit IDs. This requirement ensures that the
configurations remain compatible. This compatibility is necessary for services
like DVS which require low-level compatibility between CNs and NCNs.

Additional software product streams may require NCN personalization of the
management nodes in addition to the configuration required by CSM. Consult the
documentation for these products for more information.

For more detailed information on configuration management with CFS, see these
topics in [Configuration Management](configuration_management/Configuration_Management.md)
   * Configuration Layers
   * Ansible Inventory
   * Configuration Management with the CFS Batcher
   * Configuration Management of System Components
   * CFS Global Options
   * Version Control Service (VCS)
   * Write Ansible Code for CFS


### Topics:

   * [CSM Configuration Layer](#csm_configuration_layer)
      * Passwordless SSH
         * CSM Keys in Vault
         * Scope of Passwordless SSH
         * Passwordless SSH Use Cases
            * Provide Custom Keys
            * Restore Keys to Initial Defaults
            * Create a CFS Configuration for the Application of Passwordless SSH to NCNs
      * [Setting the root Password on NCNs](#set_root_password)
   * [Create a CFS Configuration JSON File](#create_a_cfs_configuration_json_file)
   * [Upload and Apply the CFS Configuration File](#upload_and_apply_the_cfs_configuration_file)
   * [Rerun NCN Personalization on an NCN](#rerun_ncn_personalization_on_an_ncn)

## Details

<a name="csm_configuration_layer"></a>
### CSM Configuration Layer

This procedure describes how to create the optional CSM configuration layer to implement passwordless SSH when applied to the
management nodes with NCN Personalization.

#### Passwordless SSH

Passwordless SSH keypairs for the Cray System Management (CSM) are created automatically and periodically
maintained with a Kubernetes deployment, and then staged into Kubernetes secrets and configmaps unconditionally.
Administrators can use these provided keys, provide their own keys, or use their own solution for authentication.

Master, worker, or storage nodes (NCNs) must have these keys applied to them through the
Configuration Framework Service (CFS) in order for passwordless SSH to work. These can be applied to NCNs
one time only through a single CFS session, or maintained more persistently for each environment by registering
the configuration with CFS for each desired environment. This must be done electively in order for this to work.

Passwordless SSH setup contains two Ansible roles:
   * `trust-csm-ssh-keys` configures an environment to trust CSM keys. The public half of the key is added to the authorized_keys file on the node.
   * `passwordless-ssh` pulls both of the public and private key portions into the local environment.

These roles are shared between products through the VCS (gitea).

Downstream managed product environments, such as compute nodes and User Access Nodes (UANs), contain
configuration references to the `trust-csm-ssh-keys` role by default. During image customization of the images for those nodes,
public portions of these keys are added to the environments exactly once. If an admin changes the automatically
generated private or public key for these environments, the images must be reconfigured, or the product
`site.yml` needs to be reconfigured to allow for pushing subsequent updated public keys. Existing public keys
injected into the authorized keys file are not automatically removed during reconfiguration.

##### CSM keys in Vault

Passwordless SSH Keys are generated using vault under the CSM key. The private half of the key is published as
a Kubernetes secret:

   ```bash
   ncn# kubectl get secrets -n services csm-private-key \
   -o jsonpath="{.data.value}" | base64 -d
   -----BEGIN EC PRIVATE KEY-----
   MIGkAgEBBDCax9yqFs4TlTR0pnI5rvk7FlKl4weWnQxfAGRtTGM5axygblJxLbdY
   RnRhym8t67qgBwYFK4EEACKhZANiAAQeVXJpIMVq2471w0q6zq62BXMy4nIrs+fd
   cTEeGPjEDpudChKCrdaMSriAe7W/xvb9tlVOFp+QWJn91CndpVcq632d9qyRoy/Z
   IpPkdiTkOQltdsSum2jUkWLKybou8Z4=
   -----END EC PRIVATE KEY-----
   ```

The public half of the key is stored in a Kubernetes configmap:
   ```bash
   ncn# kubectl get configmap -n services csm-public-key \
   -o jsonpath="{.data.value}" | base64 -d
   ecdsa-sha2-
   nistp384AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBB5VcmkgxWrbjvXDSrrOrrYFczLiciuz5
   91xMR4Y+MQOm50KEoKt1oxKuIB7tb/G9v22VU4Wn5BYmf3UKd2lVyrrfZ32rJGjL9kik
   +R2JOQ5CW12xK6baNSRYsrJui7xng==
   ```

These commands can be run anywhere kubectl is configured to point at the cluster with proper authentication.

##### Scope of Passwordless SSH

The goal of passwordless SSH is to enable an easy way for interactive passwordless SSH from and between
CSM product environments to downstream managed product environments, without requiring each downstream
product environment to create and apply individual changes to NCNs.

>**Note:** Passwordless SSH from managed nodes into management nodes is not intended or supported.

Local site security requirements may preclude use of passwordless SSH access between products or
environments, so the private key is not applied anywhere by default. Users are advised to use the CSM product
configuration repository (as uploaded during install to gitea) to apply these changes to NCNs.

Applying changes to NCN environments allows basic passwordless SSH to function for the lifetime of the affected
file system.

The public key is injected as a trusted source as an authorized_key for managed environments automatically,
even if the private half is never used. If this is not desirable, the role `trust-csm-public-keys` can be
removed from the `site.yml` top-level play for the compute nodes (COS product) or UANs (UAN product).

Under no circumstances should the `passwordless-ssh` Ansible role be run against an image that is to be
registered into IMS/S3 during image customization. Doing so would allow access to private credentials
information to all nodes that trust the key by retrieving the image and extracting the saved private key.

CFS itself does not use the keys provided to initialize connections between nodes. Instead, CFS uses a
time-limited vault signed public certificate along with its own key pair.

##### Passwordless SSH Use Cases
Administrators can manage the implementation of passwordless SSH keypairs for Cray System Management
(CSM) by using the provided keys, providing their own keys, or using their own solution for authentication. This
section outlines common use cases for working with passwordless SSH and keys on an HPE Cray EX system.

The following use cases are covered in this section:
   * Provide Custom Keys
   * Restore Keys to Initial Defaults
   * Create a CFS Configuration for the Application of Passwordless SSH to NCNs

###### Provide Custom Keys
Administrators may elect to replace the provided keys with their own custom keys. This is best done before the impacted
environments are configured or installed, because it can be difficult to know where all of the key portions are
populated.

The `csm-ssh-keys` deployment will only push its configured keys when the upstream image is configured using
the Configuration Framework Service (CFS) and Image Management Service (IMS) customization. The
`trust-csm-ssh-keys` Ansible role does not remove existing entries that have been applied. This is true for both image
customization and node personalization for CFS targets.

To replace the private key half:
```bash
ncn-m001# kubectl get secret -n services csm-private-key -o json | \
    jq --arg value "$(cat ~/.ssh/id_rsa | base64)" \
    '.data["value"]=$value' | kubectl apply -f -
```

In this example, `~/.ssh/id_rsa` is a local file containing a private key in a format specified by the admin.

To replace the public key half:
```bash
ncn# kubectl delete configmap -n services \
csm-public-key && cat ~/.ssh/id_rsa.pub | \
base64 > ./value && kubectl create configmap --from-file \
value csm-public-key --namespace services && rm ./value
```

In this example, ~/.ssh/id_rsa.pub is a file containing the public key half that the admin intends to use for
Cray System Management (CSM) and downstream products.

###### Restore Keys to Initial Defaults

The csm-ssh-keys deployment periodically checks the configmap and secret containing the key information. If
these entries do not exist, it will overwrite them from the key generated with vault.
In this case, deleting the associated configmap and secrets will republish them.

###### Create a CFS Configuration for the Application of Passwordless SSH to NCNs

It may be necessary to create or update a CFS configuration entry to apply changes to the NCN environment.
Typically, this needs to be done for newly installed HPE Cray EX product releases.

The following example creates a new CFS configuration with a single product configuration layer (csm-1.5.8).
Multiple product configuration layers may be created later to apply multiple changes to a node at one time.

1. Get the import_branch for CSM from the cray-product-catalog.

   ```bash
   ncn# kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}'
   1.0.0-beta.19:
     configuration:
       clone_url: https://vcs.SYSTEM_DOMAIN_NAME/vcs/cray/csm-config-management.git
       commit: 43ecfa8236bed625b54325ebb70916f55884b3a4
       import_branch: cray/csm/1.5.8
       import_date: 2021-06-01 22:55:34.869501
       ssh_url: git@vcs.SYSTEM_DOMAIN_NAME:cray/csm-config-management.git
     images:
       cray-shasta-csm-sles15sp2-barebones.x86_64-shasta-1.5:
         id: eea6f5d2-8fa0-4a58-a435-d519b0b7d481
     recipes:
       cray-shasta-csm-sles15sp2-barebones.x86_64-shasta-1.5:
         id: 31a85d14-400c-43ed-b0e8-33582cde709d
   ```

1. Set the RELEASE environment variable from the version number in import_branch.
   ```bash
   ncn# RELEASE=1.5.8
   ```

1. Obtain the password for the `crayvcs` user from the Kubernetes secret for use in the next step.

   ```bash
   ncn# kubectl get secret -n services vcs-user-credentials \
   --template={{.data.vcs_password}} | base64 --decode; echo ""
   8ac997acbd9e8e4a050fa8300257901a839c55bc780a3ebe60e2ff999c8ff964
   ```

1. Determine the commit ID.

   The `git ls-remote` command in this step will require a valid username and password in VCS. See previous step for the `crayvcs` username and its password.
   ```bash
   ncn# COMMIT=$(git ls-remote \
   https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git \
   refs/heads/cray/csm/${RELEASE} | awk '{print $1}')
   Username for 'https://api-gw-service-nmn.local': crayvcs
   Password for 'https://crayvcs@api-gw-service-nmn.local': 
   ncn-m001# echo $COMMIT
   43ecfa8236bed625b54325ebb70916f55884b3a4
   ```

1. Create a JSON file with just the CSM configuration information in it using the RELEASE and COMMIT collected above.

   ```bash
   ncn# cat <<'EOF' > csm-config-$RELEASE.json
   {
      "layers": [
         {
            "name": "csm-@RELEASE@",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
            "playbook": "site.yml",
            "commit": "@COMMIT@"
         }
      ]
   }
   EOF
   ncn# sed -i -e "s:@RELEASE@:$RELEASE:g" \
   -e "s:@COMMIT@:$COMMIT:g" csm-config-$RELEASE.json
   ```

1. If this is a first time install and only the CSM software product has been installed, then this file can become
   the original `ncn-personalization.json` file to which other software products can be added as they are installed.

   ```bash
   ncn# cp -p csm-config-$RELEASE.json ncn-personalization.json
   ```

   And then skip to [Upload and Apply the CFS Configuration File](#upload_and_apply_the_cfs_configuration_file)

   If this is not a first time install, then the `csm-config-$RELEASE.json` contents should be added to
    `ncn-personalization.json` using the configuration layer order suggested in [Create a CFS configuration JSON file](#create_a_cfs_configuration_json_file)

<a name="set_root_password"></a>
#### Setting the root Password

The root password is managed on NCNs by using the `csm.password` Ansible role
located in `roles/csm.password` in the CSM configuration management repository
and stored in VCS on the system. Root passwords are managed in Vault and applied
via NCN personalization.

By default, the `csm.password` role reads passwords from Vault using the
`secret/csm/management_nodes` secret and the `root_password` key in that secret.
To set the password in Vault, follow steps 1-3 in the
[Update NCN Passwords](#operations/security_and_authentication/Update_NCN_Passwords.md)
procedure.

This role is enabled by default in the CSM `site.yml` top-level play and assumes
the password change is for the root user. To rotate or set the root password on
the NCNs, create a CFS session with using the  [CSM Configuration Layer](#csm_configuration_layer)
with `site.yml` as the playbook. This will re-run NCN personalization and all of
its configuration layers. To only change the root password, use the
`rotate-pw-mgmt-nodes.yml` playbook by following the instructions in the
[Update NCN Passwords](#operations/security_and_authentication/Update_NCN_Passwords.md)
procedure.

<a name="create_a_cfs_configuration_json_file"></a>
### Create a CFS Configuration JSON File

1. For every layer of configuration, four fields are required.
   * `name` of the layer
   * `cloneUrl` which indicates where to find the configuration management repository in VCS
   * `playbook` to be run for this layer
   * `commit` ID in the named `cloneUrl` in VCS

1. Create a CFS configuration JSON file for NCN personalization.

   **Note:** During the early part of a first time installation of software, the CSM product is the only one
   which is available to be added to the configuration layers. As more software product streams are installed,
   these other layers will become available to be added to the NCN personalization.

   All products that must be configured on the NCNs must have a corresponding layer in the CFS JSON file. Each node
   in the HPE Cray EX system can only have one configuration applied. The CSM layer must always be the first
   layer in the file, if present. This procedure assumes that the example CFS configuration file is saved as
   ncn-personalization.json on a master node. Replace the values for commit and cloneUrl with the
   values obtained for each of the configuration repositories.

   When multiple layers are present, the expected order is:
   1. CSM (optional, see [CSM Configuration Layer](#csm_configuration_layer))
   1. SAT
   1. SMA
   1. COS
   1. CPE (optional)
   1. Analytics (optional)
   1. customer (optional)

   A product may have multiple layers using one commit ID and reference different playbooks from that repository in VCS,
   such as the sma-base-config and sma-ldms-ncn layers for SMA.

   Obtain the git commit ID and cloneUrl for the appropriate branch or branches using
   the same method used for CSM or the method recommended by the documentation for that product stream.

   It is possible for a customer to create their own repository in VCS with Ansible plays which are to be run on
   the management nodes as another layer in the CFS configuration file for NCN personalization. That layer is not
   included in this sample ncn-personalization.json file.

   ```bash
   ncn# vi ncn-personalization.json
   ncn# cat ncn-personalization.json
   {
      "layers": [
         {
            "name": "csm-1.5.8",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
            "playbook": "site.yml",
            "commit": "755820ea8a999121c7191519309eaedc17b4e3d4"
         },
         {
           "name": "sat-ncn",
           "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/sat-config-management.git",
           "playbook": "sat-ncn.yml",
           "commit": "2a388b1dcdaf59710b9c4a7ece0b549a4e95bae5"
         },
         {
            "name": "sma-base-config",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/sma-config-management.git",
            "playbook": "sma-base-config.yml",
            "commit": "eb724e7135dc60d3fdfff9fb01672538f241e588"
         },
         {
            "name": "sma-ldms-ncn",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/sma-config-management.git",
            "playbook": "sma-ldms-ncn.yml",
            "commit": "eb724e7135dc60d3fdfff9fb01672538f241e588"
         },
         {
            "name": "cos-integration-2.1.0",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git",
            "playbook": "ncn.yml",
            "commit": "ccd964f8eeeb52ab8f895b480c5d1142c7bc0a8e"
         },
         {
            "name": "cpe-integration-21.6.4",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/cpe-config-management.git",
            "playbook": "pe_deploy.yml",
            "commit": "fde47749dcbe2fedca5a546a478115cc6468fa7f"
         },
         {
            "name": "analytics-integration-1.0.0",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/analytics-config-management.git",
            "playbook": "site.yml",
            "commit": "c018395aba3ec588fde4b4eeb41efef90f16c1fb"
         }
      ]
   }
   ```

<a name="upload_and_apply_the_cfs_configuration_file"></a>
### Upload and Apply the CFS Configuration File

1. Upload the configuration file to CFS and give the configuration a name.

   ```bash
   ncn# cray cfs configurations update ncn-personalization --file \
   ncn-personalization.json --format json
   {
      "lastUpdated": "2020-12-16T16:34:19Z",
      "layers": [
         {
            "name": "csm-1.5.8",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/csm-config-management.git",
            "playbook": "site.yml",
            "commit": "755820ea8a999121c7191519309eaedc17b4e3d4"
         },
         {
           "name": "sat-ncn",
           "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/sat-config-management.git",
           "playbook": "sat-ncn.yml",
           "commit": "2a388b1dcdaf59710b9c4a7ece0b549a4e95bae5"
         },
         {
            "name": "sma-base-config",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/sma-config-management.git",
            "playbook": "sma-base-config.yml",
            "commit": "eb724e7135dc60d3fdfff9fb01672538f241e588"
         },
         {
            "name": "sma-ldms-ncn",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/sma-config-management.git",
            "playbook": "sma-ldms-ncn.yml",
            "commit": "eb724e7135dc60d3fdfff9fb01672538f241e588"
         },
         {
            "name": "cos-integration-2.1.0",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git",
            "playbook": "ncn.yml",
            "commit": "ccd964f8eeeb52ab8f895b480c5d1142c7bc0a8e"
         },
         {
            "name": "cpe-integration-21.6.4",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/cpe-config-management.git",
            "playbook": "pe_deploy.yml",
            "commit": "fde47749dcbe2fedca5a546a478115cc6468fa7f"
         },
         {
            "name": "analytics-integration-1.0.0",
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/analytics-config-management.git",
            "playbook": "site.yml",
            "commit": "c018395aba3ec588fde4b4eeb41efef90f16c1fb"
         }
      ],
      "name": "ncn-personalization"
   }
   ```

   > When running the above step, the CFS session may fail. The TrustedUserCAKeys may not exist. Run
   > `systemctl restart cfs-state-reporter` on all NCNs which will automatically add the
   > TrustedUserCAKeys entry to /etc/ssh/sshd_config.
   >
   > ```bash
   > ncn# systemctl restart cfs-state-reporter
   > ```

1. Optional: Obtain the xnames of all NCNs that will be configured by NCN Personalization by running this
   command on each node:

   Skip this step if the required xnames have already been obtained.
   ```bash
   ncn# ssh ncn-w001 cat /etc/cray/xname
   x3000c0s7b0n0
   ```

1. Update the CFS component for all NCNs. Replace NCN_XNAME in the following command with the xname of an NCN.

   ```bash
   ncn# cray cfs components update --desired-config ncn-personalization \
   --enabled true --format json NCN_XNAME
   ```

   After the previous command is issued, the cfs-state-reporter pod will dispatch a CFS job to configure
   the NCN. The same will happen every time the NCN boots.

1. Optional: Query the status of the NCN Personalization process.
   The following example command for node x3000c0s7b0n0 will return `"configurationStatus":
   "pending"` until that configuration completes. When it completes, the command will return
   `"configurationStatus": "configured"`.

   ```bash
   ncn# cray cfs components describe x3000c0s7b0n0 --format json
   {
      "configurationStatus": "pending",
      "desiredConfig": "ncn-personalization",
      "enabled": true,
      "errorCount": 0,
      "id": "x3000c0s7b0n0",
      "retryPolicy": 3,
   }
   ncn# cray cfs components describe x3000c0s7b0n0 --format json
   {
      "configurationStatus": "configured",
      "desiredConfig": "ncn-personalization",
      "enabled": true,
      "errorCount": 0,
      "id": "x3000c0s7b0n0",
      "retryPolicy": 3,
      "state": [
         {
            "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git",
            "commit": "4f8e919ede7143929e26ee8d97e04c12572a2f90_skipped",
            "lastUpdated": "2020-12-15T21:04:32Z",
            "playbook": "ncn.yml",
            "sessionName": "batcher-d4aa7928-0c59-4057-9bd6-2c819f3f9b7d"
         }
      ]
   }
   ```

1. Repeat the last three steps for all master, worker, and storage nodes.
This will ensure that all management nodes will be automatically configured by NCN Personalization.

<a name="rerun_ncn_personalization_on_an_ncn"></a>
### Rerun NCN Personalization on an NCN

Rerun the configuration for a management node (NCN) by clearing the state of the node.
Clearing the node will cause the Configuration Framework Service (CFS) to reconfigure the management node
through NCN personalization.

This procedure should be used for changes to any of the configuration layers which CFS needs to apply
to a management node.


1. Retrieve the authenticated credentials required to rerun the configuration for a node.

   ```bash
   ncn# ADMIN_SECRET=$(kubectl get secrets admin-client-auth \
   -ojsonpath='{.data.client-secret}' | base64 -d)
   ```

1. Clear the state of the node using CFS.

   Replace the XNAME value in the following command with the xname of the node being reconfigured.

   ```bash
   ncn# cray cfs components update XNAME --state '[]'
   ```

1. Optional: Clear the state of the node in CFS using the following commands if the previous step was
   unsuccessful.

   Replace the XNAME value in the following command with the xname of the node being reconfigured.

   ```bash
   ncn# function get_token { curl -s -d grant_type=client_credentials \
   -d client_id=admin-client -d client_secret=$ADMIN_SECRET \
   https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
   | python -c 'import sys, json; print json.load(sys.stdin)["access_token"]';}
   ncn# curl -H "Authorization: Bearer $(get_token)" https://api-gw-service-nmn.local/apis/cfs/v2/components/XNAME \
   -X PATCH -H "Content-type: application/json" -d '{"state": []}'
   ```

1. Clear the error count for the node in CFS.

   Replace the XNAME value in the following command before running it.
   ```bash
   ncn# cray cfs components update --error-count 0 XNAME
   ```

