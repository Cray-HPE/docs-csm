## Enable Nvidia GPU Support

Enable Nvidia Cuda support on the system via a Content Projection Service \(CPS\) bind image.

### Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.

### Procedure

1.  Download and enable the Nvidia Cuda drivers and the HPC SDK toolkit.

    1.  Download Nvidia HPC SDK Version 20.9.

        The content can be downloaded at the following locations:

        -   Download the drivers: [https://www.nvidia.com/Download/driverResults.aspx/165286/en-us](https://www.nvidia.com/Download/driverResults.aspx/165286/en-us)
        -   Download the toolkit: [https://developer.nvidia.com/nvidia-hpc-sdk-209-downloads](https://developer.nvidia.com/nvidia-hpc-sdk-209-downloads)

            Download the Linux x86\_64 RPM version under the "Bundled with the newest CUDA version” header.

    1.  Download the HPC SDK package to an appropriate staging area.

        `ncn-m001` is the most common location.

        ```bash
        ncn-m001# wget \
        https://developer.download.nvidia.com/hpc-sdk/20.9/nvhpc-20-9-20.9-1.x86_64.rpm \
        https://developer.download.nvidia.com/hpc-sdk/20.9/nvhpc-2020-20.9-1.x86_64.rpm \
        https://developer.download.nvidia.com/hpc-sdk/20.9/nvhpc-20-9-cuda-multi-20.9-1.x86_64.rpm
        ```

    1.  Unpack the drivers from the nvidia-driver-local-repo-sles15-450.80.02-1.0-1.x86\_64.rpm file downloaded from the drivers download URL to make all Nvidia drivers available.

        The following command will unpack the container RPM locally. All Nvidia driver packages will then be available at the var/nvidia-driver-local-repo-sles15-450.80.02/ path where the RPM was unpacked.

        ```bash
        ncn-m001# rpm2cpio nvidia-driver-local-repo-sles15-450.80.02-1.0-1.x86_64.rpm | cpio -idmv
        ```

1.  Create a Nexus Zypper repository on the system to be installed that will contain the HPC SDK and the Cuda drivers content.

    1.  Log into Nexus.

        See the instructions in [Manage Repositories with Nexus](../package_repository_management/Manage_Repositories_with_Nexus.md)

        Use the following URL to access Nexus:

        ```screen
        https://nexus.SHASTA_DOMAIN/
        ```

    1.  Create a new Nexus repository to host the Cuda content.

        See the instructions in the "Create a New Repository in Nexus" procedure in the *HPE Cray EX System Administration Guide S-8001*.

    1.  Select the **yum \(hosted\)** option on the Select Recipe page.

        This step creates a repository capable of hosting Zypper RPMs with storage provided by the Simple Storage Service \(S3\) on the target system.

    1.  Fill in the name field for the new Yum repository.

        Use the default name of hpc-sdk-20.9. Otherwise, edit the target repository path in the system's Ansible configuration in a later step to find a differently named repository.

    1.  Select **zero** for the Repodata Depth field.

        This step tells Zypper to create its repository files at the top level of the repository layout.

    1.  Select **cos**, **default**, or another appropriate storage option for the Blob store option.

        This step tells Nexus where in S3 storage to locate the new Nexus repository.

    1.  Select the **allow redeploy** option under the Hosted - Deployment policy field.

        This step allows changes to be made to the repository in the future.

    1.  Click the **Create Repository** button to create the Nexus repository.

        If successful, the details of the new repository are available to view in the Repositories tab on the left side of the screen.

#### UPLOAD NVIDIA HPC SDK CONTENT

1.  Verify the new repository is available.

    The following command will show all Nexus repositories on the system.

    ```bash
    ncn-m001# curl https://packages.local/service/rest/v1/repositories \
    -H "Content-type: application/json" --http1.1
    "name" : "hpc-sdk-20.9",
    "format" : "yum",
    "type" : "hosted",
    "url" : "https://packages.local/repository/hpc-sdk-20.9", <<-- Note this value
    "attributes" : { }
    ```

1.  Upload the Nvidia HPC SDK content and the Nvidia drivers content to the Nexus repository.

    This step needs to be done from the location where the HPC SDK packages and the drivers packages were downloaded. Use the URL from the previous step as the repository target. All RPMs might not show up in the returned list.

    Push all RPMs in the local directory to the target repository:

    ```bash
    ncn-m001# for i in `find . -name *.rpm`; do curl -v --upload-file ./$i \
    https://packages.local/repository/hpc-sdk-20.9/ ; done
    ```

1.  Verify that the uploaded Cuda packages are correct on the Nexus repository manager web GUI.

    1.  Log back into Nexus.

    1.  Select the box icon at the top of the page.

    1.  Select the **Browse** option from the toolbar on the left side of the screen.

    1.  Select the new hpc-sdk-20.9 repository from the list of available repositories.

    1.  Verify that all expected RPMs are present in the browse list for the target repository.

1.  Rebuild the repository index via the Nexus GUI.

    1.  Select the gear icon at the top of the page.

    1.  Select **repositories** in the toolbar on the left side of the page.

    1.  Click the name of the new repository in the repositories list.

    1.  Click the **Rebuild Index** button at the top of the Repository View page and verify that it reports success.

1.  Verify the new repository is available on the target system via standard zypper repository commands.

    1.  Add the repositories with the zypper command.

        ```bash
        ncn-m001# zypper ar --no-gpgcheck https://packages.local/repository/hpc-sdk-20.9 hpc-sdk-20.9
        ```

    1.  List the defined repositories.

        ```bash
        ncn-m001# zypper lr -u
        ```

    1.  Refresh the repository.

        ```bash
        ncn-m001# zypper ref
        ```

    1.  Search for the repository.

        The upload was successful if Zypper can find the recently uploaded Cuda RPMs.

        ```bash
        ncn-m001# zypper search -s nvhpc
        ```

        To search for Nvidia content:

        ```bash
        ncn-m001# zypper search -s nvidia
        ```

    1.  Remove the repository from the NCN list so it does not accidentally interfere with any installs.

        ```screen
        ncn-m001# zypper rr hpc-sdk-20.9
        ```

#### MANAGE CONTENT IN CONFIG-MANAGEMENT BRANCH

<a name="vcs-password"></a>

1.  Record the Version Control Service \(VCS\) password for future reference.

    The command below retrieves the default Gitea server password for the `crayvcs` user.

    ```bash
    ncn-m001# kubectl get secret -n services vcs-user-credentials \
    --template={{.data.vcs_password}} | base64 --decode
    ```

1.  Clone the VCS config-management branch to the staging area.

    ```bash
    ncn-m001# git clone https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git
    ```

1.  Determine the current default config-management commit ID for the system that is used to boot the Grizzly Peak compute nodes.

    The branch used for booting and configuring the system may not be the default master branch for the Git clone. The correct commit ID to use will vary depending on the system.

    1.  Review the Boot Orchestration Service \(BOS\) session template in use on the system for the target Grizzly Peak nodes.

        Obtain the CFS configuration name returned in the output.

        ```bash
        ncn-m001# cray bos v1 sessiontemplate describe SESSION_TEMPLATE_NAME
        ```

        If the session template name is not known, run the following command:

        ```bash
        ncn-m001# cray bos v1 sessiontemplate list
        ```

    1.  Retrieve the commit ID by describing the Configuration Framework Service \(CFS\) configuration session.

        ```bash
        ncn-m001# cray cfs configurations describe CFS_SESSION_NAME --format json
        {
          "lastUpdated": "2020-11-21T21:09:27Z",
          "layers": [
            {
              "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git",
              "commit": "5fb065ffc32414f02543654211486216f058986b", <<-- Note this ID
              "name": "cos-sp1-config",
              "playbook": "site.yml"
            }
          ],
          "name": "cos-sp1-config"
        }
        ```

1. Determine the branches on the system using the commit ID.

    If a new branch is desired, skip this step and create a new branch directly from the commit ID.

    ```bash
    ncn-m001# git name-rev COMMIT_ID
    ```

1. Create a branch to track the default branch used to boot the Grizzly Peak compute nodes.

    Replace the NEW\_BRANCH\_NAME and DEFAULT\_COMPUTE\_BRANCH values before running the command.

    ```bash
    ncn-m001# git checkout -b NEW_BRANCH_NAME origin/DEFAULT_COMPUTE_BRANCH
    ```

1. Verify that the configuration management files refer to the correct Nexus repository path.

    The file in the Git branch that provides the repository information is roles/cray\_nvidia\_customize/defaults/main.yml.

    If the default repository path differs from the newly-created one, update the hpc-sdk\_repo\_uri and hpc-sdk\_repo fields in that file to refer to the recently created packages.local branch path and name.

    ```bash
    ncn-m001# vi roles/cray_nvidia_customize/defaults/main.yml
    ```

1. Enable the GPU on compute nodes.

    Create a new .yml file in the Git branch under the group\_vars/Compute directory. The recommended file name is gpu\_info.yml, and the file must contain the following:

    ```bash
    ncn-m001# vi group_vars/Compute/gpu_info.yml
    gpu: nvidia
    ```

1. Push the Git branch to the VCS server.

    1.  Add the files to the branch.

        ```bash
        ncn-m001# git add -A
        ```

    1.  Check the Git status.

        ```bash
        ncn-m001# git status
        ```

    <a name="commit-id"></a>

    1.  Commit the changes.

        Add a meaningful comment.

        ```bash
        ncn-m001# git commit -am 'comment'
        ```

        Use the git log command to store the commit ID. The commit ID is required to create a [CFS configuration](#config).

    1.  Push the changes to VCS.

        Push the branch using the new name rather than updating the original to leave an unaltered fallback branch if there are issues. Use the crayvcs and vcs secret recorded in the step for [retrieving the password](#vcs-password).

        ```bash
        ncn-m001# git push origin HEAD:BRANCH_NAME
        ```

    3.  Check the branch setup via the Gitea GUI tool.

        -   Non-airgapped systems:

            Point a browser at the following URL:

            ```bash
            https://vcs.SHASTA_DOMAIN
            ```

            Airgapped systems:

            ```screen
            ncn-m001# git branch -r
            ```

#### FIND THE COMPUTE NODE BOOT IMAGE

<a name="boot-image"></a>

1.  Determine the default Grizzly Peak compute node boot image rootfs value in the Image Management Service \(IMS\).

    1.  Find the IMS image ID.

        The default boot template used to boot the Grizzly Peak nodes contains the boot images rootfs IMS image ID.

        ```bash
        ncn-m001# cray bos v1 sessiontemplate describe SESSION_TEMPLATE_NAME | grep path
        path = "s3://boot-images/**14cb61b9-ac46-420a-8e67-4042ed14265d**/manifest.json"
        ```

        Create a variable for the IMS image ID using the value in bold in the returned output.

        ```bash
        ncn-m001# IMS_IMAGE_ID=14cb61b9-ac46-420a-8e67-4042ed14265d
        ```

    1.  Verify the IMS image ID is for the expected image.

        ```bash
        ncn-m001# cray ims images describe $IMS_IMAGE_ID
        ```

    1.  Compare the image ID against what is currently running on the nodes.

        The output will show the matching image ID value in the kernel, initrd, and craycps root image path if booted via the default session template.

        ```bash
        ncn-m001# cray bss bootparameters list --nid GRIZZLYPEAK_COMPUTE_NID
        ```

#### CREATE A CONFIGURATION SESSION

<a name="config"></a>

1.  Generate an image using the new VCS branch by triggering a CFS image customization job.

    1.  Create a CFS configuration that will be used to create a CFS job.

        Create the cuda\_configuration.json file to hold data about the CFS configuration with the following content.

        ```bash
        ncn-m001# cat > cuda_configuration.json
        {
          "layers": [
            {
              "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git",
              “name”: “cuda_configuration”,
              "commit": "01b8083dd89c394675f3a6955914f344b90581e2",
              "playbook": "site.yml"
            }
          ]
        }
        ```

        The commit ID used in this file is the commit ID obtained in the step for doing a [Git commit](#commit-id).

    1.  Create a new CFS configuration.

        ```bash
        ncn-m001# cray cfs configurations update cuda_configuration \
        –-file cuda_configuration.json
        ```

    1.  Create variables for the CFS job.

        ```bash
        ncn-m001# export CFS_SESSION=CUSTOM_SESSION_NAME
        ncn-m001# export CFS_CONFIGURATION=cuda_configuration
        ```

    1.  Run the CFS session.

        ```bash
        ncn-m001# cray cfs sessions create --name $CFS_SESSION \
        --target-definition image \
        --target-group Compute $IMS_IMAGE_ID \
        --configuration-name=$CFS_CONFIGURATION
        ```

1.  Monitor the CFS job and ensure it is running.

    ```bash
    ncn-m001# cray cfs sessions describe $CFS_SESSION
    ```

1.  Verify the Ansible configuration plays ran successfully by monitoring the Ansible logs for the CFS worker pod.

    1.  Retrieve the CFS job.

        ```bash
        ncn-m001# cray cfs sessions describe $CFS_SESSION | grep job
        job = "cfs-ff124b54-ca10-47d2-babe-cdd1dabfe8a8"
        ```

    1.  Get the CFS worker pod with the CFS job ID returned in the previous step.

        ```bash
        ncn-m001# kubectl get pods -n services | grep CFS_JOB_ID
        cfs-ff4ba897-812b-4a5c-9987-63726abc8ae6-r6htb       0/3     Running     0     2m35s
        ```

    1.  Access the log for the CFS pod found in the previous step.

        Follow the Ansible log as it runs the jobs to install and configure the image. Watch for errors in the Ansible plays. At the end of the run, check the "PLAY RECAP" output for any failed Ansible plays.

        ```bash
        ncn-m001# kubectl logs -n services CFS_POD_ID -f -c ansible-0
        ...
        PLAY RECAP *********************************************************************
        x5000c3s0b0n1              : ok=120  changed=80   unreachable=0    failed=0    skipped=182  rescued=0    ignored=2
        ```

1.  Monitor the CFS session until it completes and reports as successful.

    When the Ansible play completes, CFS will package the newly-generated image and upload it to S3. This can take a while to complete. Wait for the CFS session to report status: complete and targets: success: 1.

    ```bash
    ncn-m001# cray cfs sessions describe $CFS_SESSION
    ```

<a name="resultant-id"></a>

1.  Record the resultant image ID reported under the artifacts section.

    The result\_id value is the IMS image ID for the newly-created Nvidia CPS image.

    ```bash
    ncn-m001# cray cfs sessions describe $CFS_SESSION | grep result_id
    result_id: 5d0e451f-3e2f-4e15-a8e7-5dd73ce36ebb
    ```

    Create a variable for the result\_id value.

    ```bash
    ncn-m001# export RESULTANT_IMAGE_ID=5d0e451f-3e2f-4e15-a8e7-5dd73ce36ebb
    ```

1. Verify the new image is in IMS.

    ```bash
    ncn-m001# cray ims images describe $RESULTANT_IMAGE_ID
    ```

1. Check the contents of the Nvidia CPS image.

    ```bash
    ncn-m001# cray artifacts get boot-images $RESULTANT_IMAGE_ID/rootfs ./rootfs
    ncn-m001# ls
    ncn-m001# mount -t squashfs -o loop ./rootfs /mnt/img
    ncn-m001# chroot /mnt/img
    ```

1. Clean up the CFS session after it completes.

    ```bash
    ncn-m001# cray cfs sessions delete $CFS_SESSION
    ```

#### UPDATE THE GRIZZLY PEAK CONFIGURATION MANIFEST

1. Update the Grizzly Peak configuration manifest branch so it is aware of the CPS image.

    Use the same branch created in [Git commit step](#commit-id).

    1.  Ensure the correct branch is being used.

        ```bash
        ncn-m001# git fetch
        ncn-m001# git pull
        ```

    1.  Edit the roles/cray\_nvidia\_common/defaults/main.yml file.

        Edit the "cray\_nvidia\_sqfs\_img\_id" field to provide the resultant IMS image ID of the newly-created CPS image from the step to retrieve the [resultant ID](#resultant-id).

        ```bash
        ncn-m001# vim roles/cray_nvidia_common/defaults/main.yml
        cray_nvidia_sqfs_img_id: 3d3ebe19-560f-433d-8b69-7c557961e460
        ```

1.  Commit the new changes to the Grizzly Peak configuration manifest branch and push the branch to VCS.

    1.  Add the files to the branch.

        ```bash
        ncn-m001# git add -A
        ```

    <a name="grizzly-peak-commit"></a>

    1.  Commit the changes.

        Add a meaningful comment.

        ```bash
        ncn-m001# git commit -am 'comment'
        ```

        Use the git log command to store the commit ID. The commit ID is required to create a new CFS configuration.

    1.  Push the changes to the branch service.

        Push the branch using the new name rather than updating the original to leave an unaltered fallback branch if there are issues. Use the crayvcs and vcs secret recorded in step for retrieving the [VCS credentials](#vcs-password).

        ```bash
        ncn-m001# git push origin HEAD:BRANCH_NAME
        ```

    1.  Verify the changes were made.

        ```bash
        ncn-m001# git status
        ```

#### REBOOT/RECONFIGURE GRIZZLY PEAK COMPUTE NODES

1.  Create a new BOS session template to be used to boot and configure the Grizzly Peak nodes with a newly-created CFS configuration.

    1.  Create a new CFS configuration JSON file using the new commit ID generated in the step to commit changes to the [Grizzly Peak configuration manifest branch](#grizzly-peak-commit).

        Follow the same process used in the step to create a [CFS configuration session](#config).

    2.  Clone the default boot session template found in the step to find the [compute node boot image](#boot-image).

        ```bash
        ncn-m001# cray bos v1 sessiontemplate describe \
        DEFAULT_BOS_TEMPLATE_NAME --format json > template.default
        ```

2.  Add the information for the new CFS configuration to the local clone of the default session template.

    The following is an example of a BOS session template input file:

    ```bash
    ncn-m001# vi template.default
     { 
      "enable_cfs": true, 
      "name": "cle-1.2.0", 
      "boot_sets": { 
        "boot_set1": {
          "network": "nmn", 
          "boot_ordinal": 1, 
          "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=256M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell k8s_gw=api-gwservice-nmn.local quiet turbo_boost_limit=999",
          "rootfs_provider": "cpss3", 
          "node_list": [ 
            "x3000c0s19b1n0" 
          ], 
          "etag": "90b2466ae8081c9a604fd6121f4c08b7", 
          "path": "s3://boot-images/06901f40-f2a6-4a64-bc26-772a5cc9d321/manifest.json", 
          "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:eth0", 
          "type": "s3" 
          } 
        }, 
      "partition": "", 
      “cfs”: {
        "configuration": "wlm-config-0.1.0”
       },
       }
    ```

    1.  Edit the "configuration" field with the name of the new CFS configuration.

    2.  Edit the "name" field with an identifiable name different from the default name.

    3.  Edit the "node\_list" field with a comma separated list of the Grizzly Peak node xnames.

        Remove any nodes that are not Grizzly Peak nodes from the list. To determine the Grizzly Peak nodes on the system:

        ```bash
        ncn-m001# sat hwinv | grep Grizz
        ```

3.  Push the updated local template file to BOS.

    ```bash
    ncn-m001# cray bos v1 sessiontemplate create \
    -–file template.default --name SESSION_TEMPLATE_NAME
    ```

4.  Verify the new session template was pushed successfully and the contents are correct.

    ```bash
    ncn-m001# cray bos v1 sessiontemplate describe SESSION_TEMPLATE_NAME
    ```

5.  Remove Grizzly Peak nodes from the original default session template.

    If the default session template that was cloned in a previous step contained any Grizzly Peak nodes, they will need to be removed from that session template.

    1.  Edit the "node\_list" field to remove any Grizzly Peak xnames from the list that are now booted via the new Grizzly Peak template.

        ```bash
        ncn-m001# vi SESSION_TEMPLATE_NAME
        ```

    2.  Push the updated template to BOS.

        ```bash
        ncn-m001# bos_session_template ./SESSION_TEMPLATE_NAME
        ```

<a name="bos-session"></a>

1.  Create a BOS session to reboot or reconfigure the Grizzly Peak nodes.

    Rebooting or reconfiguring the nodes will make the Nvidia content available.

    Set the --operation parameter to `Reboot` or `Configure`.

    ```bash
    ncn-m001# cray bos v1 session create --template-uuid \
    SESSION_TEMPLATE_NAME --operation Reboot
    operation = "Reboot"
    templateUuid = "TEMPLATE_UUID"
    [[links]]
    href = "foo-c7faa704-3f98-4c91-bdfb-e377a184ab4f"
    jobId = "boa-a939bd32-9d27-433f-afc2-735e77ec8e58" <<-- Note the session ID
    rel = "session"
    type = "GET
    ```

    Create a variable for the jobId field:

    ```bash
    ncn-m001# export BOS_SESSION_JOB_ID=boa-a939bd32-9d27-433f-afc2-735e77ec8e58
    ```

1. Track the status of the Boot Orchestration Agent \(BOA\) pods for the BOS session.

    1.  Get the name of the BOA Kubernetes pod ID.

        ```bash
        ncn-m001# kubectl get pods -n services | grep $BOS_SESSION_JOB_ID
        ```

        Create a variable for the returned pod ID:

        ```bash
        ncn-m001# export BOA_POD_ID=boa-a939bd32-9d27-433f-afc2-735e77ec8e58-ztscd
        ```

    1.  Watch the log for the BOA Kubernetes pod.

        The BOA log will run until the nodes have reported either a completed boot and configure, or just a configuration depending on what BOS operation was performed.

        ```bash
        ncn-m001# kubectl logs -n services $BOA_POD_ID -c boa
        ```

    1.  Verify the configuration was successful by monitoring the CFS worker pod.

        To find the CFS pods that corresponds with the BOS session:

        ```bash
        ncn-m001# cray cfs sessions list
        ```

        If successful, the end of the CFS Ansible log will report a number of successful Ansible plays and no failures. If there are issues, review the log output for the failing play.

        ```bash
        ncn-m001# kubectl logs -n services cfs-ff124b54-ca10-47d2-babe-cdd1dabfe8a8 -c ansible
        ```

1. Monitor the BOS job until it finishes.

    A finished pod will report the field complete = true, have a stop time listed, and report the field in\_progress = false. Grizzly Peak compute node boot and CFS post-boot personalization is now complete.

    ```bash
    ncn-m001# cray bos v1 session describe $BOS_SESSION_JOB_ID
    status_link = "/v1/session/f4eebe51-a217-46d0-8733-b9499a092042/status"
    complete = true
    start_time = "2020-07-22 13:39:07.706774"
    templateUuid = TEMPLATE_UUID
    boa_job_name = "boa-f4eebe51-a217-46d0-8733-b9499a092042"
    stop_time = "2020-07-22 13:50:07.706774"
    in_progress = false
    operation = "reboot"
    ```

1. Clean up the BOS session when it is finished.

    ```bash
    ncn-m001# cray bos v1 session delete $BOS_SESSION_JOB_ID
    ```

#### CHECK GRIZZLY PEAK COMPUTE NODE HEALTH

1. SSH to a Grizzly Peak compute node.

    ```bash
    ncn-m001# ssh XNAME
    ```

1. Verify the Nvidia drivers are loaded.

    1.  Check for the four main Nvidia drivers.

        The following drivers should be present:

        -   nvidia\_modeset
        -   nvidia\_drm
        -   nvidia\_uvm
        -   nvidia
        
        The nv\_peer\_mem driver will also be present.

        ```bash
        # lsmod | grep nv
        ```

    1.  Confirm the gdrdrv module is loaded.

        The gdrdrv module is the driver for the gdrcopy package.

        ```bash
        # lsmod | grep gdr
        ```

1. Verify the Nvidia GPUs are healthy.

    Verify all four GPUs are found and running. Verify the "persistence mode" setting is reporting as `On`.

    ```bash
    # nvidia-smi -q
    ```

1. Run the gdrcopy sanity tests.

    ```bash
    # which sanity
    # sanity -v
    # which copybw
    # copybw
    ```

1. Verify the HPC SDK module file is available.

    ```bash
    # module avail | grep cuda
    # module load cudatoolkit
    ```

1. Report the BOS session template as the default to be used to reboot and configure Grizzly Peak nodes in the future.

#### UPDATE UAN INFORMATION

1. Update the configuration manifest branch for the UANs to make HPC SDK available on the node.

    <a name="configuration-information"></a>
    
    1.  Determine the current configuration commit ID used to boot and configure the UAN.

        The branch can be found by reviewing the default Boot Orchestration Service \(BOS\) session template for the UAN nodes. The master branch might not be in use.

        ```bash
        ncn-m001# cray bos v1 sessiontemplate describe SESSION_TEMPLATE_NAME
        ```

    1.  Clone the configuration management from https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git.

    1.  Create a branch to track the appropriate commit ID or UAN branch from the commit ID using git name-rev.

        Replace the NEW\_BRANCH\_NAME and DEFAULT\_BRANCH values before running the command.

        ```bash
        ncn-m001# git checkout -b NEW_BRANCH_NAME origin/DEFAULT_BRANCH
        ```

1. Verify that the patched files refer to the correct Nexus repository path.

    The file in the Git branch that provides the repository information is roles/cray\_nvidia\_customize/defaults/main.yml.

    If the default repository path differs from the newly-created one, update the nvidia\_repo\_uri and nvidia\_repo fields in that file to refer to the recently created packages.local branch path and name.

    ```bash
    ncn-m001# vi roles/cray_nvidia_customize/defaults/main.yml
    ```

1. Enable the GPU on UANs.

    Create a new .yml file in the Git branch under the group\_vars/Application directory. The recommended file name is gpu\_info.yml, and the file must contain the following:

    ```bash
    ncn-m001# vi group_vars/Application/gpu_info.yml
    gpu: nvidia
    ```

1. Push the Git branch to the VCS server.

    1.  Add the files to the branch.

        ```bash
        ncn-m001# git add -A
        ```

    <a name="new-commit-id"></a>

    1.  Commit the changes.

        Add a meaningful comment.

        ```bash
        ncn-m001# git commit -am 'comment'
        ```

        Make a note of the new commit ID to be used to create a new CFS configuration.

    1.  Push the changes to the branch service.

        Push the branch using the new name rather than updating the original to leave an unaltered fallback branch if there are issues. Use the crayvcs and vcs secret recorded in the step to retrieve the [VCS credentials](#vcs-password).

        ```bash
        ncn-m001# git push origin HEAD:BRANCH_NAME
        ```

1. Repeat the steps in the "UPDATE THE GRIZZLY PEAK CONFIGURATION MANIFEST" and "REBOOT/RECONFIGURE GRIZZLY PEAK COMPUTE NODES" sections for UANs, replacing "Compute" with "UAN" or "Application" if appropriate to configure the UAN with support for Cuda content.

    Add the resultant CPS image ID to the UAN config branch.

1. Create a new BOS session template to be used to boot and configure UANs.

    Clone the default boot session template for the UAN nodes found in the step for finding the [configuration information](#configuration-information).

    ```bash
    ncn-m001# cray bos v1 sessiontemplate describe \
    DEFAULT_BOS_TEMPLATE_NAME --format json > UAN_template.default
    ```

1. Create a new CFS configuration with the Commit ID obtained in the [Git commit](#new-commit-id).

1. Add the information for the CFS configuration to the local clone of the default session template.

    The following is an example of a BOS session template input file:

    ```bash
    ncn-m001# vi UAN_template.default
     { 
      "enable_cfs": true, 
      "name": "cle-1.2.0", 
      "boot_sets": { 
        "boot_set1": {
          "network": "nmn", 
          "boot_ordinal": 1, 
          "kernel_parameters": "console=ttyS0,115200 bad_page=panic crashkernel=256M hugepagelist=2m-2g intel_iommu=off intel_pstate=disable iommu=pt ip=dhcp numa_interleave_omit=headless numa_zonelist_order=node oops=panic pageblock_order=14 pcie_ports=native printk.synchronous=y rd.neednet=1 rd.retry=10 rd.shell k8s_gw=api-gwservice-nmn.local quiet turbo_boost_limit=999",
          "rootfs_provider": "cpss3", 
          "node_list": [ 
            "x3000c0s19b1n0" 
          ], 
          "etag": "90b2466ae8081c9a604fd6121f4c08b7", 
          "path": "s3://boot-images/06901f40-f2a6-4a64-bc26-772a5cc9d321/manifest.json", 
          "rootfs_provider_passthrough": "dvs:api-gw-service-nmn.local:300:eth0", 
          "type": "s3" 
          } 
        }, 
      "partition": "", 
      "cfs": {
      "configuration": "wlm-config-0.1.0"
      },
      }
    ```

    1.  Edit the "configuration" field with the name of the new CFS configuration.

    1.  Edit the "name" field with an identifiable name different from the original default.

1. Push the updated local template file to BOS.

    ```bash
    ncn-m001# bos_session_template ./UAN_template.default
    ```

1. Verify the new session template was pushed successfully and the contents are correct.

    ```bash
    ncn-m001# cray bos v1 sessiontemplate describe SESSION_TEMPLATE_NAME
    ```

1. Reboot or Reconfigure the UAN nodes to make the Cuda content available on the node.

    Follow the same process used in the previous step to create a [BOS session](#bos-session).

1. Verify the cudatoolkit contents are as expected on the reconfigured UAN.

    The Nvidia drivers will not be loaded on the UAN since there is no GPU hardware.

    1.  Ensure the cudatoolkit module file is available.

        ```bash
        # module avail cuda
        # module load cudatoolkit
        ```

    1.  Ensure the Cuda jobs are buildable.

        ```bash
        # which nvcc
        ```

1. Report the UAN BOS session template as the default to be used to reboot or configure UANs.

