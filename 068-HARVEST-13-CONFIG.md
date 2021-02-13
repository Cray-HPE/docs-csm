# HARVEST 13 CONFIG

This procedure provides advice for information to collect from a healthy Shasta v1.3 system.

* Collect data needed to prepare Shasta v1.4 installation pre-config files
* Save operational information about which components are disabled and why
* Save site customizations to use as a guide for customizing a Shasta v1.4 system

Although some configuration data can be saved from a Shasta v1.3 system, there are new configuration files
needed for Shasta v1.4.  Some of this data is easier to collect from a running Shasta v1.3 system.

There may be some operational data to be saved such as any nodes which are disabled or marked down in a
workload manager.  These nodes might need hardware or firmware actions to repair them.  If not addressed,
and the newer firmware in v1.4 does not improve their performance or operation, then these may need to be
disabled with v1.4 as well.

There may be site modifications to the system from v1.3 which are desired in v1.4.  They cannot be directly
copied to v1.4, however, recommendation will be made about what to save.  Some saved information from v1.3
may be referenced when making a similar site modification to v1.3.


1. Start a prep.install typescript with timestamps and run commands to collect information.

   Although Some of the commands in this procedure will output to a file, others will output to stdout and be captured by this typescript file.

    ```bash
    user@host> ssh ncn-w001
    ncn-w001# mkdir -p ~/prep.install.1.4
    ncn-w001# cd ~/prep.install.1.4
    ncn-w001# script -af prep.install.1.4.$(date +%Y-%m-%d).txt
    ncn-w001# export PS1='\u@\H \D{%Y-%m-%d} \t \w # '
    ```

2. Confirm installed version of CLE software.

    Some of the steps below will be different for v1.3.0 versus v1.3.2. Any variation in commands will be marked.

    ```bash
    ncn-w001# cat /opt/cray/etc/release/cle
    PRODUCT="Cray's Linux Environment"
    OS=SLES15SP1
    ARCH=x86_64
    VERSION=1.3.2
    DATE=20201014142855
    ```

3. Obtain the user ID and passwords for system components:

    a. Obtain user ID and passwords for all the system management network spine, leaf, CDU, and aggregation switches. For example:

    sw-spine01-mtl
    sw-spine02-mtl
    sw-leaf01-mtl
    sw-leaf02-mtl
    sw-cdu01-mtl
    sw-cdu02-mtl

    User id: admin
    Password: PASSWORD

    b. If necessary, obtain the user ID and password for the ClusterStor primary management node. For example, cls01053n00.

    User id: admin
    Password: PASSWORD

    c. If necessary, obtain the user ID and password for the Arista edge switches.

4. Confirm BMC username/password for management NCNs.

    User id: root
    Password: PASSWORD

    Note: The external connection for ncn-w001 (BMC and node) will be moved to ncn-m001 for installation of the v1.4 software in a later step. It is critical that you be able to connect to the ncn-m001 BMC using a valid administrative username and password.

5. Check switches are reachable.

    Substitute the system switch names in the following command for the correct number of spine, leaf, CDU, and aggregation swtiches in this system.

    ```bash
    ncn-w001# for switch in sw-leaf0{1,2}-mtl sw-spine0{1,2}-mtl sw-cdu0{1,2}-mtl; do while true; \
    do ping -c 1 $switch > /dev/null; if [[ $? == 0 ]]; then echo "switch $switch is up"; break; \
    else echo "switch $switch is not up"; fi; sleep 5; done; done
    switch sw-leaf01-mtl is up
    switch sw-leaf02-mtl is up
    switch sw-spine01-mtl is up
    switch sw-spine02-mtl is up
    switch sw-cdu01-mtl is up
    switch sw-cdu02-mtl is up
    ```

    Note: The IP addresses for these switches will need to be changed in a later step to align with v1.4 software.

6. Collect the current IP addresses for the switches.

    ```bash
    ncn-w001# grep sw /etc/hosts | grep mtl
    10.1.0.1        sw-spine01-mtl.local sw-spine01-mtl                               #-label-10.1.0.1
    10.1.0.2        sw-leaf01-mtl.local sw-leaf01-mtl                                 #-label-10.1.0.2
    10.1.0.3        sw-spine02-mtl.local sw-spine02-mtl                               #-label-10.1.0.3
    10.1.0.4        sw-leaf02-mtl.local sw-leaf02-mtl                                 #-label-10.1.0.4
    10.1.0.5        sw-cdu01-mtl.local sw-cdu01-mtl                                   #-label-10.1.0.5
    10.1.0.6        sw-cdu02-mtl.local sw-cdu02-mtl                                   #-label-10.1.0.6
    ```

7. Check firmware on all leaf, spine, CDU, and aggregation switches meets expected level for v1.4. If they need to be updated, remember that for later in this procedure.

    For minimum Network switch versions see [Network Firmware](251-FIRMWARE-NETWORK.md)

    Check the version for each leaf switch:

    ```bash
    ncn-w001# ssh admin@sw-leaf01-mtl
    switch# show version
    Dell EMC Networking OS10 Enterprise
    Copyright (c) 1999-2019 by Dell Inc. All Rights Reserved.
    OS Version: 10.5.0.2P1
    Build Version: 10.5.0.2P1.482
    Build Time: 2019-10-29T19:58:10+0000
    System Type: S3048-ON
    Architecture: x86_64
    Up Time: 9 weeks 5 days 05:17:33
    ```

    Check the version for each spine switch:

    ```bash
    ncn-w001# ssh admin@spine01-mtl
    Mellanox Switch
    sw-spine01 [standalone: master] > show version
    Product name:      Onyx
    Product release:   3.9.0300
    Build ID:          #1-dev
    Build date:        2020-02-26 19:25:24
    Target arch:       x86_64
    Target hw:         x86_64
    Built by:          jenkins@7c42130d8bd6
    Version summary:   X86_64 3.9.0300 2020-02-26 19:25:24 x86_64
    Product model:     x86onie
    Host ID:           506B4BF4FCB0
    System serial num: MT1845X03127
    System UUID:       7ce27170-e2ba-11e8-8000-98039befd600
    Uptime:            68d 5h 21m 36.256s
    CPU load averages: 3.20 / 3.20 / 3.18
    Number of CPUs:    2
    System memory:     2763 MB used / 5026 MB free / 7789 MB total
    Swap:              0 MB used / 0 MB free / 0 MB total
    ```

    Check the version for each CDU switch:

    ```bash
    ncn-w001# ssh admin@sw-cdu01-mtl
    switch# show version
    Dell EMC Networking OS10 Enterprise
    Copyright (c) 1999-2019 by Dell Inc. All Rights Reserved.
    OS Version: 10.5.0.2P1
    Build Version: 10.5.0.2P1.482
    Build Time: 2019-10-29T19:58:10+0000
    System Type: S4148T-ON
    Architecture: x86_64
    Up Time: 4 weeks 6 days 04:01:07
    ```

    Check the version for each aggregation switch:

    ```bash
    ncn-w001# ssh admin@sw-agg01-mtl
    switch# show version
    Dell EMC Networking OS10 Enterprise
    Copyright (c) 1999-2019 by Dell Inc. All Rights Reserved.
    OS Version: 10.5.0.2P1
    Build Version: 10.5.0.2P1.482
    Build Time: 2019-10-29T19:58:10+0000
    System Type: S4148T-ON
    Architecture: x86_64
    Up Time: 4 weeks 6 days 04:01:07
    ```

8. Check firmware on Gigabyte nodes. If they need to be updated, remember that for later in this procedure.

    For minimum NCN firmware versions see [Node Firmware](252-FIRMWARE-NODE.md)

    Gigabyte nodes should be at the 20.03.00 version released after Shasta v1.3.2 in December 2020.

    ```
    BIOS version C20
    BMC version 12.84.09
    CMC version 62.84.02
    ```

    Check which version of sh-svr rpms are installed. If they are less than 20.03.00, then the firmware update bundle has not been installed or applied to the Gigabyte nodes. You will need to have both the firmware release tarball and the Gigabyte Node Firmware Update Guide (1.3.2) S-8010 to upgrade the firmware on Gigabyte nodes when indicated later in this procedure.

    ```bash
    ncn-w001# rpm -qa | grep sh-svr 
    sh-svr-1264up-bios-20.02.00-20201022025951_2289a89.x86_64
    sh-svr-3264-bios-crayctldeploy-0.0.14-20201022025951_2289a89.x86_64
    sh-svr-3264-bios-20.02.00-20201022025951_2289a89.x86_64
    sh-svr-5264-gpu-bios-20.02.00-20201022025951_2289a89.x86_64
    sh-svr-5264-gpu-bios-crayctldeploy-0.0.14-20201022025951_2289a89.x86_64
    sh-svr-1264up-bios-crayctldeploy-0.0.14-20201022025951_2289a89.x86_64
    ```

    If the 20.03.00 rpms have been installed, then run this script to check whether the firmware update has been applied to the nodes. Information about how to interpret the output of this command and the procedures for updating Gigabyte compute node firmware or Gigabyte non-compute node firmware is in the Gigabyte Node Firmware Update Guide (1.3.2) S-8010

    Check the BIOS, BMC, and CMC firmware versions on nodes.

    ```bash
    ncn-w001# bash /opt/cray/FW/bios/sh-svr-1264up-bios/sh-svr-scripts/find_GBT_Summary_for_Shasta_v1.3_rack.sh \
    2>&1 | tee /var/tmp/rvr-inv
    ```

9. Determine which Boot Orchestration Service (BOS) templates to use to shutdown compute nodes and UANs.

    For example:

    Compute nodes: cle-1.3.2
    UANs: uan-1.3.2

10. Obtain the authorization key for SAT.

    See System Security and Authentication, Authenticate an Account with the Command Line, SAT
    Authentication in the Cray Shasta Administration Guide 1.3 S-8001 for more information.

    * v1.3.0: Use Rev C of the guide
    * v1.3.2: Use Rev E or later

11. Save the list of nodes that are disabled.

    ```bash
    ncn-w001# sat status --filter Enabled=false > sat.status.disabled
    ```

12. Save a list of nodes that are off.

    ```bash
    ncn-w001# sat status --filter State=Off > sat.status.off
    ```

13. Save the Slurm status on nodes.

    ```bash
    ncn-w001# ssh nid001000 sinfo > sinfo
    ```

14. Save the Slurm list of nodes down and the reason why they are down.

    ```bash
    ncn-w001# ssh nid001000 sinfo --list-reasons > sinfo.reasons
    ```

15. Get for PBS status on nodes (which are offline or down)

    ```bash
    ncn-w001# ssh nid001000 pbsnodes -l > pbsnodes
    ```

16. Check Slingshot port status.

    ```bash
    ncn-w001# /opt/cray/bringup-fabric/status.sh > fabric.status
    ```

17. Verify Rosetta switches are accessible and healthy

    ```bash
    ncn-w001# /opt/cray/bringup-fabric/ssmgmt_sc_check.sh > fabric.ssmgmt_sc_check
    ```

18. Check current firmware.

    ```bash
    ncn-w001# sat firmware > sat.firmware
    ```

    There will be a point after the v1.4 software has been installed when firmware needs to be updated on many components.
    Those components which need a firmware update while v1.3 is booted, will be addressed later.


19. Check Lustre server health.

    ```bash
    ncn-w001# ssh admin@cls01234n00.system.com
    admin@cls01234n00 ~]$ cscli show_nodes
    ```

20. Save information from HSM about any site-defined groups/labels applied to nodes.

    HSM groups might be used in BOS session templates, but they may be used in conjunction with Ansible plays in VCS to configure nodes. Saving this information now will make it easier to reload it after v1.4 has been installed.

    Save information about label, description, and members of each group in HSM.

    ```bash
    ncn-w001# cray hsm groups list --format json > hsm.groups
    ```

    Here is a sample group from that output.

    ```json
      {
        "description": "NCNs running Lustre", 
        "members": {
          "ids": [
            "x3000c0s7b0n0", 
            "x3000c0s9b0n0", 
            "x3000c0s11b0n0", 
            "x3000c0s25b0n0", 
            "x3000c0s13b0n0"
          ]
        }, 
        "label": "lnet_ncn"
      }
    ```

21. Save a copy of the master branch in VCS with all of the site modifications from v1.3.

    See https://git-scm.com/book/en/v2/Git-Tools-Bundling for information about how to manipulate this bundle repo to extract information.

    Note: This data cannot be directly imported and used on v1.4, but can serve as a reference to site modifications done with v1.3 which might be similar to those needed with v1.4.

    ```bash
    ncn-w001# git clone https://api-gw-service-nmn.local/vcs/cray/config-management.git
    Cloning into 'config-management'...
    remote: Enumerating objects: 3148, done.
    remote: Counting objects: 100% (3148/3148), done.
    remote: Compressing objects: 100% (846/846), done.
    remote: Total 3148 (delta 1341), reused 2518 (delta 1049)
    Receiving objects: 100% (3148/3148), 10.35 MiB | 27.59 MiB/s, done.
    Resolving deltas: 100% (1341/1341), done.
    ```

    Make a git bundle which is transportable as a single file "VCS.bundle".

    ```bash
    ncn-w001# git bundle create VCS.bundle HEAD master
    ```

    Check for other branches. There may be other branches, in addition to master, which could be saved.

    ```bash
    ncn-w001# git branch -a
      remotes/origin/HEAD -> origin/master
      remotes/origin/cray/cme-premium/1.3.0
      remotes/origin/cray/cme-premium/1.3.2
      remotes/origin/cray/cray-pe/20.08
      remotes/origin/cray/cray-pe/20.09
      remotes/origin/cray/cray-pe/20.11
      remotes/origin/master
      remotes/origin/slurm
      remotes/origin/slurm2
    ```

22. Save a copy of any site-modified recipes in IMS.

    You do not need to save any of the HPE-provided recipes, but you may want to use any modified recipes as a guide to how the v1.4 HPE-provided recipes may need to be modified to meet site needs.

    List all recipes in IMS

    ```json
    ncn-w001# cray ims recipes list --format json
    ```
    [
      {
        "recipe_type": "kiwi-ng", 
        "linux_distribution": "sles15", 
        "created": "2020-09-04T03:22:15.764123+00:00", 
        "link": {
          "path": "s3://ims/recipes/0bfcf98b-3b73-49ad-ab08-5b868ed3dda2/recipe.tar.gz", 
          "etag": "dec4e4b7dd734a0a24dcf4b67e69c2f5", 
          "type": "s3"
        }, 
        "id": "0bfcf98b-3b73-49ad-ab08-5b868ed3dda2", 
        "name": "cray-sles15sp1-barebones-0.1.4"
      }, 
      {
        "recipe_type": "kiwi-ng", 
        "linux_distribution": "sles15", 
        "created": "2020-09-04T03:38:07.259114+00:00", 
        "link": {
          "path": "s3://ims/recipes/b463fb84-ffaf-4e00-81f1-1682acae2f25/recipe.tar.gz", 
          "etag": "42f7b0c58ef5db1828dd772405f376b7", 
          "type": "s3"
        }, 
        "id": "b463fb84-ffaf-4e00-81f1-1682acae2f25", 
        "name": "cray-sles15sp1-cle"
      }, 
      {
        "recipe_type": "kiwi-ng", 
        "linux_distribution": "sles15", 
        "created": "2020-10-29T23:31:51.340962+00:00", 
        "link": {
          "path": "s3://ims/recipes/49c703e9-3b95-4409-804f-b9c0e790487b/recipe.tar.gz", 
          "etag": "", 
          "type": "s3"
        }, 
        "id": "49c703e9-3b95-4409-804f-b9c0e790487b", 
        "name": "cray-sles15sp1-cle-1.3.26"
      }
    ]
    ```

    Review the list of IMS recipes to determine which you want to save.

    For each IMS recipe that you want to save, use `cray artifacts get ims <object> <filename>` where object is the S3 key for the recipe.tgz (from the recipe list and filename is the filename you want to save the object to. Once downloaded, uncompress the tgz file to view the files and directories that comprise the recipe.

    From the output above, IMS has this metadata about the cray-sles15sp1-barebones-0.1.4 recipe.

    ```
      {
        "recipe_type": "kiwi-ng", 
        "linux_distribution": "sles15", 
        "created": "2020-09-04T03:22:15.764123+00:00", 
        "link": {
          "path": "s3://ims/recipes/0bfcf98b-3b73-49ad-ab08-5b868ed3dda2/recipe.tar.gz", 
          "etag": "dec4e4b7dd734a0a24dcf4b67e69c2f5", 
          "type": "s3"
        }, 
        "id": "0bfcf98b-3b73-49ad-ab08-5b868ed3dda2", 
        "name": "cray-sles15sp1-barebones-0.1.4"
      }, 
    ```


    This command will extract the recipe from the IMS S3 bucket and place it into a filename which is based on the name from the IMS recipe.

    ```bash
    ncn-w001# cray artifacts get ims recipes/0bfcf98b-3b73-49ad-ab08-5b868ed3dda2/recipe.tar.gz cray-sles15sp1-barebones-0.1.4.tgz
    ```

23. Save a copy of any BOS session templates of interest.

    There might be organizational information, such as the names of BOS session templates or how they specify the nodes to be booted using a list of groups or list of nodes, but there might also be special kernel parameters added by the site.

    ```bash
    command TBD
    ```

24. Save a copy of any IMS images which might have been directly customized.

    If all images were built from an IMS recipe and then customized with CFS before booting, then this step can be skipped.

    List all IMS images.

    ```bash
    ncn-w001# cray ims images list --format json
    [
      {
        "link": {
          "path": "s3://boot-images/9f32ed7b-9e1c-444d-8b63-40cefbf7e846/manifest.json", 
          "etag": "db1b16d771a5a88cb320519e066348b8", 
          "type": "s3"
        }, 
        "id": "9f32ed7b-9e1c-444d-8b63-40cefbf7e846", 
        "name": "cle_default_rootfs_cfs_2488e992-ee60-11ea-88f1-b42e993b710e", 
        "created": "2020-09-04T03:42:51.474549+00:00"
      }, 
      {
        "link": {
          "path": "s3://boot-images/dc1a430f-82cb-4b9b-a1dd-7c8540721013/manifest.json", 
          "etag": "5f243b60b4211c47e79b837df2271692", 
          "type": "s3"
        }, 
        "id": "dc1a430f-82cb-4b9b-a1dd-7c8540721013", 
        "name": "cle_default_rootfs_cfs_test_20200914125841b", 
        "created": "2020-09-14T20:46:51.367749+00:00"
      }, 
    ]
    ```

    Review the list of IMS images to determine which you want to save.

    This example uses the "cle_default_rootfs_cfs_test_20200914125841b" image from above.

    For each image that you want to save perform the following steps, use `cray artifacts get boot-images <object> <filename>` where object is the S3 key for the IMS manifest file and filename is the filename you want to save the manifest file to.

    For each artifact in the manifest file, use `cray artifacts get boot-images <object> <filename>` where object is the S3 key for the image artifact (from the manifest file) and filename is the filename you want to save the artifact to.

    Get the manifest file using the path to the S3 boot-images bucket and save as a local filename "manifest.json".

    ```bash
    ncn-w001# cray artifacts get boot-images fe4b8429-4ea7-4696-8018-2c7950a75e4b/manifest.json manifest.json
    ```
 
    Example manifest.json file for an IMS image

    ```bash
    ncn-w001# cat manifest.json
    {
        "artifacts": [
            {
                "link": {
                    "etag": "1f9f88a65be7fdd8190008e06b1da2c0-175",
                    "path": "s3://boot-images/dc1a430f-82cb-4b9b-a1dd-7c8540721013/rootfs",
                    "type": "s3"
                    },
                "md5": "d402ea98531f995106918815e4d74cc4",
                "type": "application/vnd.cray.image.rootfs.squashfs"
            },
            {
                "link": {
                    "etag": "d76adf4ee44b6229dad69103c38d49ca",
                    "path": "s3://boot-images/dc1a430f-82cb-4b9b-a1dd-7c8540721013/kernel",
                    "type": "s3"
                },
                "md5": "d76adf4ee44b6229dad69103c38d49ca",
                "type": "application/vnd.cray.image.kernel"
            },
            {
                "link": {
                    "etag": "43b0f96a951590cc478ae7b311e3e413-4",
                    "path": "s3://boot-images/dc1a430f-82cb-4b9b-a1dd-7c8540721013/initrd",
                    "type": "s3"
                },
                "md5": "9112b42d5e3da6902cc62158d6482552",
                "type": "application/vnd.cray.image.initrd"
            }
        ],
        "created": "2020-09-14 20:47:01.211752",
        "version": "1.0"
    }
    ```

    Changes might have been made in the initrd or in the rootfs or both. This example shows how to extract one of those files.

    Extract the rootfs (squashfs) file.

    ```bash
    ncn-w001# cray artifacts get boot-images dc1a430f-82cb-4b9b-a1dd-7c8540721013/rootfs rootfs
    ```

25. Dump the information from SLS.

    Some information from SLS can be extracted for use in the pre-config file, hmn_connections.json, and cabinets.yaml for the v1.4 installation.  The Cray Shasta_administration Guide 1.3 S-8001 has a section "Dump SLS Information".

    If there is a fully current SHCD (Shasta Cabling Diagram, previously called CCD for Cray Cabling Diagram) spreadsheet file for this system, there is a way to extract information from it to create the hmn_connections.json file later in the v1.4 installation process.  However, SLS data may be more current than the SHCD or there may not be a valid SHCD file for this system if cabling changes have not been recorded as updates to the SHCD file.  Saving this SLS information while v1.3 is booted may provide a point of comparison with the data in the SHCD.

    This procedure will create three files in the current directory (private_key.pem, public_key.pem, sls_dump.json). These files should be kept in a safe and secure place as the private key can decrypt the encrypted passwords stored in the SLS dump file.

    Use the get_token function to retrieve a token to validate requests to the API gateway.

    ```bash
    ncn-w001# function get_token () {
        ADMIN_SECRET=$(kubectl get secrets admin-client-auth -ojsonpath='{.data.client-secret}' | base64 -d)
        curl -s -d grant_type=client_credentials -d client_id=admin-client -d client_secret=$ADMIN_SECRET \
            https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token | python \
            -c 'import sys, json; print json.load(sys.stdin)["access_token"]'
    }
    ```

    Generate a private and public key pair.

    Execute the following commands to generate a private and public key to use for the dump.

    ```bash
    ncn-w001# openssl genpkey -out private_key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
    ncn-w001# openssl rsa -in private_key.pem -outform PEM -pubout -out public_key.pem
    ```

    The above commands will create two files the private key private_key.pem file and the public key public_key.pem file.

    Make sure to use a new private and public key pair for each dump operation, and do not reuse an existing private and public key pair. The private key should be treated securely because it will be required to decrypt the SLS dump file when the dump is loaded back into SLS. Once the private key is used to load state back into SLS, it should be considered insecure.

    Perform the SLS dump.

    The SLS dump will be stored in the sls_dump.json file. The sls_dump.json and private_key.pem files are required to perform the SLS load state operation.

    ```bash
    ncn-w001# curl -X POST \
    https://api-gw-service-nmn.local/apis/sls/v1/dumpstate \
    -H "Authorization: Bearer $(get_token)" \
    -F public_key=@public_key.pem > sls_dump.json
    
      % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                     Dload  Upload   Total   Spent    Left  Speed
    100  591k    0  590k  100   663   122k    137  0:00:04  0:00:04 --:--:--  163k
    ```

26. Save the contents of the /opt/cray/site-info directory.

     The customizations.yaml and certs subdirectory have information which is needed for the v1.4 install.

    ```bash
    ncn-w001# tar cf site-info.tar /opt/cray/site-info
    ```

27. Collect MAC address information from the leaf switches for each management NCN and its BMC.

     This will be used during the v1.4 install in the ncn_metadata.csv file.

    ```bash
    ncn-w001# ssh admin@sw-leaf01-mtl
    ```

    Show vlan 4 which is the NMN. This shows the MAC addresses which will be used to boot the nodes.

    ```bash
    sw-leaf01# show mac address-table vlan 4
    VlanId  Mac Address             Type            Interface
    4       00:0a:5c:90:1b:bf       dynamic         port-channel100
    4       00:0a:9c:62:20:2e       dynamic         ethernet1/1/41
    4       00:40:a6:82:f7:73       dynamic         ethernet1/1/42
    4       00:40:a6:83:07:ff       dynamic         ethernet1/1/43
    4       00:40:a6:83:08:65       dynamic         ethernet1/1/44
    4       00:40:a6:83:08:8d       dynamic         ethernet1/1/45
    4       3c:2c:30:67:c0:b5       dynamic         port-channel100
    4       50:6b:4b:9c:c6:48       dynamic         port-channel100
    4       50:9a:4c:e0:32:d1       dynamic         port-channel100
    4       50:9a:4c:e0:88:d1       dynamic         port-channel100
    4       98:03:9b:ef:d6:48       dynamic         port-channel100
    4       b4:2e:99:3b:70:28       dynamic         ethernet1/1/46
    4       b4:2e:99:3b:70:30       dynamic         ethernet1/1/47
    4       b4:2e:99:3b:70:50       dynamic         ethernet1/1/34
    4       b4:2e:99:3b:70:58       dynamic         ethernet1/1/48
    4       b4:2e:99:3b:70:c0       dynamic         ethernet1/1/38
    4       b4:2e:99:3b:70:c8       dynamic         ethernet1/1/36
    4       b4:2e:99:3b:70:d0       dynamic         ethernet1/1/37
    4       b4:2e:99:3b:70:d4       dynamic         port-channel100
    4       b4:2e:99:3b:70:d8       dynamic         port-channel100
    4       b4:2e:99:3e:82:66       dynamic         ethernet1/1/33
    4       b4:2e:99:a6:5d:df       dynamic         ethernet1/1/25
    4       b8:59:9f:2b:2f:9e       dynamic         port-channel100
    4       b8:59:9f:2b:30:fa       dynamic         port-channel100
    4       b8:59:9f:34:88:be       dynamic         port-channel100
    4       b8:59:9f:34:88:c6       dynamic         port-channel100
    4       b8:59:9f:34:89:3a       dynamic         port-channel100
    4       b8:59:9f:34:89:46       dynamic         port-channel100
    4       b8:59:9f:34:89:4a       dynamic         port-channel100
    4       b8:59:9f:f9:1b:e6       dynamic         port-channel100
    ```

    Show vlan 1 which is the HMN which has the node's BMC MAC address. This is needed for DHCP of the node BMC.

    ```bash
    sw-leaf01# show mac address-table vlan 1
    VlanId  Mac Address             Type            Interface
    1       3c:2c:30:67:c0:b5       dynamic         port-channel100
    1       50:6b:4b:9c:c6:20       dynamic         port-channel100
    1       50:6b:4b:9c:c6:48       dynamic         port-channel100
    1       50:9a:4c:e0:32:d1       dynamic         port-channel100
    1       50:9a:4c:e0:88:d1       dynamic         port-channel100
    1       98:03:9b:ef:d6:20       dynamic         port-channel100
    1       98:03:9b:ef:d6:48       dynamic         port-channel100
    1       b8:59:9f:2b:2e:aa       dynamic         port-channel100
    1       b8:59:9f:2b:2e:b6       dynamic         port-channel100
    1       b8:59:9f:2b:2f:9e       dynamic         port-channel100
    1       b8:59:9f:2b:30:82       dynamic         port-channel100
    1       b8:59:9f:2b:30:fa       dynamic         port-channel100
    1       b8:59:9f:2b:31:0a       dynamic         port-channel100
    1       b8:59:9f:34:88:be       dynamic         port-channel100
    1       b8:59:9f:34:88:c6       dynamic         port-channel100
    1       b8:59:9f:34:89:3a       dynamic         port-channel100
    1       b8:59:9f:34:89:46       dynamic         port-channel100
    1       b8:59:9f:34:89:4a       dynamic         port-channel100
    1       b8:59:9f:f9:1b:e6       dynamic         port-channel100
    sw-leaf01# exit
    ```

    Another way to collect information about the BMC MAC address is this loop. Set the correct number of storage and worker nodes.

    ```bash
    ncn-w001# nodes=""
    ncn-w001# for name in ncn-m00{1,2,3}  ncn-s00{1,2,3} ncn-w00{1,2,3,4,5}; do nodes="$nodes $name"; done
    ncn-w001# echo $nodes
    ncn-m001 ncn-m002 ncn-m003 ncn-s001 ncn-s002 ncn-s003 ncn-w001 ncn-w002 ncn-w003 ncn-w004 ncn-w005
    ```

    Use "ipmitool lan print" to determine the BMC MAC address.

    * Gigabayte nodes should use "lan print 1".
    * Intel nodes should use "lan print 3".

    ```bash
    ncn-w001# for ncn in $nodes; do echo $ncn; ssh $ncn ipmitool lan print 1 | grep "MAC Address"; done
    ncn-m001
    MAC Address             : b4:2e:99:3b:70:c0
    ncn-m002
    MAC Address            : b4:2e:99:3b:70:d0
    ncn-m003
    MAC Address             : b4:2e:99:3b:70:c8
    ncn-s001
    MAC Address             : b4:2e:99:3b:70:d8
    ncn-s002
    MAC Address             : b4:2e:99:3b:70:d4
    ncn-s003
    MAC Address             : b4:2e:99:3b:70:58
    ncn-w001
    MAC Address            : b4:2e:99:3b:71:10
    ncn-w002
    MAC Address            : b4:2e:99:3b:70:50
    ncn-w003
    MAC Address             : b4:2e:99:3e:82:66
    ncn-w004
    MAC Address             : b4:2e:99:a6:5d:df
    ncn-w005
    MAC Address             : b4:2e:99:3b:70:28
    ```

28. Collect output from "ip address" for all management NCNs. 

    This is another source of MAC address information, but also indicates the device names which will be used for the bonded interface bond0.

    ```bash
    ncn-w001# for ncn in $nodes; do echo $ncn; ssh $ncn ip address ; done
    ```

29. Check full BMC information for ncn-w001 because the connection will be moved to ncn-m001. 

    The IP address, subnet mask, and default gateway IP will be needed.

    ```bash
    ncn-w001# ipmitool lan print
    Set in Progress         : Set Complete
    Auth Type Support       : NONE MD2 MD5 PASSWORD OEM 
    Auth Type Enable        : Callback : MD5 
                            : User     : MD5 
                            : Operator : MD5 
                            : Admin    : MD5 
                            : OEM      : MD5 
    IP Address Source       : Static Address
    IP Address              : 172.30.56.3
    Subnet Mask             : 255.255.240.0
    MAC Address             : b4:2e:99:3b:71:10
    SNMP Community String   : AMI
    IP Header               : TTL=0x40 Flags=0x40 Precedence=0x00 TOS=0x10
    BMC ARP Control         : ARP Responses Enabled, Gratuitous ARP Disabled
    Gratituous ARP Intrvl   : 1.0 seconds
    Default Gateway IP      : 172.30.48.1
    Default Gateway MAC     : 00:00:00:00:01:50
    Backup Gateway IP       : 0.0.0.0
    Backup Gateway MAC      : 00:00:00:00:00:00
    802.1q VLAN ID          : Disabled
    802.1q VLAN Priority    : 0
    RMCP+ Cipher Suites     : 0,1,2,3,6,7,8,11,12,15,16,17
    Cipher Suite Priv Max   : caaaaaaaaaaaXXX
                            :     X=Cipher Suite Unused
                            :     c=CALLBACK
                            :     u=USER
                            :     o=OPERATOR
                            :     a=ADMIN
                            :     O=OEM
    Bad Password Threshold  : 0
    Invalid password disable: no
    Attempt Count Reset Int.: 0
    User Lockout Interval   : 0 
    ```

30. Check Mellanox firmware for the CX-4 and CX-5 on management NCNs.

    For minimum NCN firmware versions see [Node Firmware](252-FIRMWARE-NODE.md)

    Confirm the version of the mft rpm installed on the management NCNs. The mft-4.14.0-105.x86_64 version is known to work to report the firmware version installed.

    ```bash
    ncn-w001# for ncn in $nodes; do echo $ncn; ssh $ncn rpm -q mft; done
    ```

    Check version of firmware installed.

    ```bash
    ncn-w001# for ncn in $nodes; do echo $ncn; ssh $ncn mlxfwmanager | egrep "FW|Device" ; done
    ```

    Output from each node will look like this. Compare this information with the versions in [Node Firmware](252-FIRMWARE-NODE.md)

    ```bash
    Device #1:
      Device Type:      ConnectX4
      PCI Device Name:  0000:42:00.0
         FW             12.26.4012     N/A           
    Device #2:
      Device Type:      ConnectX5
      PCI Device Name:  0000:41:00.0
         FW             16.28.4000     N/A           
    Device #3:
      Device Type:      ConnectX5
      PCI Device Name:  0000:81:00.0
         FW             16.28.4000     N/A           
    ```

31. Is there any information to export from SDU data or plugins before it is wiped out by the v1.4 install?
    CASMINST-1268

32. Is there any information to export from SMF or other log sources before it is wiped out by the v1.4 install?
    CASMINST-1269

33. Is there any information to export from LDMS before it is wiped out by the v1.4 install?
    CASMINST-1270

34. The checks have all completed.  

    Finish the typescript file
    ```bash
    ncn-w001# exit
    ```

    Save the typescript file and the output from all of the above commands somewhere off the Shasta v1.3 system.


