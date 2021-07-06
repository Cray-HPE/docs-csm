## Configure Kubernetes on Compute Nodes

Cray's Linux Environment \(CLE\) ships with a set of Ansible plays that can be used to configure Kubernetes container orchestration runtime if it is installed in the compute image. Create site-specific Ansible code for the Configuration Framework Service \(CFS\).


### Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system.
-   Familiarity with Git workflows and a Git client compatible with the CFS-provided Git server are required.

### Limitations

The Configuration Framework Service \(CFS\) hangs when given an image ID that does not exist.

### Procedure

1.  Verify the Version Control Service \(VCS\) is running.

    ```bash
    ncn-m001# kubectl get pods --all-namespaces | grep vcs
    services          gitea-vcs-f57c54c4f-j8k4t          2/2     Running             1          11d
    services          gitea-vcs-postgres-0               2/2     Running             0          11d
    ```

2.  Retrieve the initial Gitea login credentials for the `crayvcs` username.

    ```bash
    ncn-m001# kubectl get secret -n services vcs-user-credentials \
    --template={{.data.vcs_password}} | base64 --decode
    ```

    These credentials can be modified in the vcs\_user role prior to installation or can be modified after logging in.

3.  Use an external web browser to verify the Ansible plays are available on the system.

    The URL will take on the following format:

    ```bash
    https://api.SYSTEM-NAME_DOMAIN-NAME/vcs
    ```

4.  Select an appropriate repository to create a branch in.

    View the available repositories on the Gitea web portal.

    ```bash
    https://vcs.SYSTEM-NAME.DOMAIN-NAME
    ```

5.  Make a new directory for the ck8s configuration.

    ```bash
    ncn-m001# cd
    ncn-m001# mkdir cf-ck8s && cd cf-ck8s
    ```

6.  Clone the current system configuration.

    Update the REPOSITORY\_NAME value before running the following command.

    ```bash
    ncn-m001# git clone https://api-gw-service-nmn.local/vcs/cray/REPOSITORY_NAME
    Cloning into 'REPOSITORY_NAME'...
    remote: Enumerating objects: 364, done.
    remote: Counting objects: 100% (364/364), done.
    remote: Compressing objects: 100% (225/225), done.
    remote: Total 364 (delta 38), reused 353 (delta 34)
    Receiving objects: 100% (364/364), 92.77 KiB | 23.19 MiB/s, done.
    Resolving deltas: 100% (38/38), done.
    ```

7.  Change to the cos-config-management directory.

    ```bash
    ncn-m001# cd cos-config-management/
    ```

8.  Create a new branch of for ck8s.

    ```bash
    ncn-m001# git checkout -b ck8s
    Switched to a new branch 'ck8s'
    ```

9.  Verify the desired Ansible plays are in the current directory.

    These plays may need to be added if the cloned repository is empty.

    ```bash
    ncn-m001# ls
    configure_fs.yml     cray_lnet_unload.yml               .git        host_vars                   keycloak-users.yml  motd.yml             plays          shadow.yml            sysconfig.yml
    cray_dvs_load.yml    cray-ncn-customization-load.yml    group_vars  hsn_computes.yml            library             overlay-preload.yml  rasdaemon.yml  site.yml              uan.yml
    cray_dvs_unload.yml  cray-ncn-customization-unload.yml  hosts       kdump.yml                   limits.yml          pedeploy.yml         roles          slurm_node.yml
    cray_lnet_load.yml   diagDeploy.yml                     hosts.yml   keycloak-users-compute.yml  localtime.yml       peinstall.yml        rsyslog.yml    sma-ldms-compute.yml
    ```

10. Add the ck8s roles to the site.yml file to target the compute nodes specified in the Hardware State Manager \(HSM\) dynamic inventory.

    To create a custom inventory or target a subset of the Compute nodes, please refer to the "Ansible Inventory" section in the Configuration Framework Service (CFS) documentation.

    ```bash
    ncn-m001# vi site.yml
    ```

    The following is an example site.yml file:

    ```bash
    #!/usr/bin/env ansible-playbook
    # Copyright 2019, Cray Inc. All Rights Reserved.
     
    ---
    - name: Standard UNIX configuration
      include: sysconfig.yml
     
    - hosts: Compute
      any_errors_fatal: true
      remote_user: root
      roles:
        - motd
        - overlay-preload
        - { role: munged, when: system_wlm is defined and system_wlm == "Slurm" }
        - { role: slurm_node, when: system_wlm is defined and system_wlm == "Slurm" }
        - sma-ldms-compute
     
    - hosts: hsn-cn
      gather_facts: yes
      gather_subset: min
      any_errors_fatal: true
      remote_user: root
      roles:
        - nms_hsn_interfaces
        - nms_hsn_etc_hosts
     
    - hosts: ck8s-nc-computes
      any_errors_fatal: true
      remote_user: root
      roles:
      - { role: ck8s/ck8s-key-generation }
       
    - hosts: ck8s-nc-computes
      any_errors_fatal: true
      remote_user: root
      roles:
      - { role: ck8s/ck8s-cn-dockerd }
       
    - hosts: ck8s-nc-computes
      any_errors_fatal: true
      remote_user: root
      roles:
      - { role: ck8s/ck8s-cn-kubespray }
    ```

11. Create compute node entries in the hosts file.

    Each node must be listed in an inventory file itself. Create a static inventory file in a hosts directory at the root of the configuration management repository in Ansible INI format.

    For example:

    ```bash
    ncn-m001# mkdir -p hosts; cd hosts; cat > static <<EOF
    [test_nodes]
    nid000001-nmn
    EOF
    ```

    The following is an example hosts file:

    ```bash
    # Copyright 2019, Cray Inc. All Rights Reserved.
    # This file is only used if the target definition is "repo".
    # By default dynamic inventory is used and this file is ignored.
     
    [ck8s-ncn-master]
    sms01-nmn
    [ck8s-nc-master]
    nid000001-nmn
    nid000002-nmn
    nid000003-nmn
    [ck8s-nc-etcd]
    nid000001-nmn
    nid000002-nmn
    nid000003-nmn
    [ck8s-nc-computes]
    nid000001-nmn
    nid000002-nmn
    nid000003-nmn
    nid000004-nmn
    [ck8s-nc-computes-master]
    nid000001-nmn
    ```

12. Change the storage limit for docker images per node.

    ```bash
    ncn-m001# vi roles/ck8s/ck8s-cn-dockerd/defaults/main.yml
    ```

    The default storage limit is 50GB per node. Update the following line to change the limit:

    ```bash
    "ck8s_graph_size: 50G"
    ```

13. Verify the modified files are present when checking the git status.

    ```bash
    ncn-m001# git status
    On branch ck8s
    Changes not staged for commit:
    (use "git add <file>..." to update what will be committed)
    (use "git checkout -- <file>..." to discard changes in working directory)
    modified: hosts
    modified: site.yml
    no changes added to commit (use "git add" and/or "git commit -a")
    ```

14. Upload the new files to the ck8s branch.

    1.  Add the changes from the working directory to the staging area.

        ```bash
        ncn-m001# git add -A
        ```

    2.  Commit the changes.

        ```bash
        ncn-m001# git commit -m "ck8s deploy"
        [ck8s 6018955] ck8s deploy
         Committer: root <root@ncn-m001.local>
        Your name and email address were configured automatically based
        on your username and hostname. Please check that they are accurate.
        You can suppress this message by setting them explicitly. Run the
        following command and follow the instructions in your editor to edit
        your configuration file:
         
            git config --global --edit
         
        After doing this, you may fix the identity used for this commit with:
         
            git commit --amend --reset-author
         
         2 files changed, 68 insertions(+), 2 deletions(-)
        ```

    3.  Push the commit.

        ```bash
        ncn-m001# git push --set-upstream origin ck8s
        Username for 'https://api-gw-service-nmn.local': crayvcs
        Password for 'https://crayvcs@api-gw-service-nmn.local':
        Counting objects: 4, done.
        Delta compression using up to 40 threads.
        Compressing objects: 100% (4/4), done.
        Writing objects: 100% (4/4), 871 bytes | 871.00 KiB/s, done.
        Total 4 (delta 1), reused 0 (delta 0)
        remote:
        remote: Create a new pull request for 'ck8s':
        remote:   https://api-gw-service-nmn.local/vcs/cray/cos-config-management/compare/cray%2Fcme-premium%2F0.6.0...ck8s
        remote:
        To https://api-gw-service-nmn.local/vcs/cray/cos-config-management.git
         * [new branch]      ck8s -> ck8s
        Branch 'ck8s' set up to track remote branch 'ck8s' from 'origin'.
        ```

15. Create a CFS configuration.

    Refer to "Update a CFS Configuration" in the CFS documentation for more information.

    1.  Create a JSON file to hold data about the ck8s configuration.

        ```bash
        ncn-m001# cat cfs_config.json
        {
          "layers": [
            {
              "name": "CONFIGURATION_NAME",
              "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/REPO_NAME.git",
              "playbook": "site.yml",
              "commit": "COMMIT_ID"
            }
          ]
        }
        ```

    2.  Add the configuration to CFS with the JSON file.

        ```bash
        ncn-m001# cray cfs configurations update CONFIG_NAME --file cfs_config.json
        ```

16. Execute the play on the compute nodes.

    1.  Create a CFS configuration session.

        In this example, the play is executed on all nodes specified in the hosts file. See the "Ansible Inventory" section in the CFS documentation if the use of a static inventory file is desired.

        The example below also assumes a CFS configuration has already been created. All CFS create sessions will start by creating a configuration if one is not provided.

        ```bash
        ncn-m001# cray cfs sessions create --name ck8s \
        --configuration-name CFS_CONFIGURATION_NAME --verbose
         
        name = "ck8s"
        id = "f95089c4-be25-11e9-8249-a4bf0138ece7"
        [[links]]
        href = "/apis/cfs/sessions/ck8s"
        rel = "self"
         
        [[links]]
        href = "/apis/cms.cray.com/v1/namespaces/services/cfsessions/ck8s"
        rel = "k8s"
         
        [status]
        
        [configuration]
        name = sample-config
         
        [target]
        definition = "repo"
        groups = []
        ```

    2.  Create a variable for the Kubernetes pod created for the CFS configuration session.

        ```bash
        ncn-m001# CFS_POD=$(kubectl get pods --selector=cfsession=ck8s --all-namespaces \
        --no-headers -o=custom-columns=:.metadata.namespace,:.metadata.name)
        ```

    3.  Review the Ansible play logs for the configuration session.

        ```bash
        ncn-m001# kubectl logs -f --namespace=$CFS_POD -c ansible
        PLAY [computes] ****************************************************************
        skipping: no hosts matched
         [WARNING]: Could not match supplied host pattern, ignoring: Compute
         
        PLAY [Compute] *****************************************************************
        skipping: no hosts matched
         [WARNING]: Could not match supplied host pattern, ignoring: hsn-cn
         
        PLAY [hsn-cn] ******************************************************************
        skipping: no hosts matched
        ...
         
         
        TASK [ck8s/ck8s-cn-kubespray : run kubespray in online mode] *******************
        skipping: [nid000001-nmn]
         
        TASK [ck8s/ck8s-cn-kubespray : run kubespray in offline mode] ******************
        changed: [nid000001-nmn]
         
        PLAY RECAP *********************************************************************
        nid000001-nmn              : ok=47   changed=20   unreachable=0    failed=0    skipped=3    rescued=0    ignored=2
        nid000002-nmn              : ok=34   changed=14   unreachable=0    failed=0    skipped=2    rescued=0    ignored=2
        nid000003-nmn              : ok=34   changed=14   unreachable=0    failed=0    skipped=2    rescued=0    ignored=2
        nid000004-nmn              : ok=34   changed=14   unreachable=0    failed=0    skipped=2    rescued=0    ignored=2
        ncn-m001                   : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
        ```

    4.  Delete the CFS session.

        ```screen
        ncn-m001# cray cfs sessions delete ck8s
        ```

17. Verify the deployment.

    1.  Log into the ck8s master node \(`nid000001-nmn`\).

    2.  Check the running Docker containers.

        ```bash
        nid000001:~ # docker ps
        CONTAINER ID      IMAGE                                                         COMMAND                   CREATED          STATUS            PORTS        NAMES
        608bc7ae7202      98db19758ad4                                                  "/usr/local/bin/kube…"   5 minutes ago     Up 5 minutes                  k8s_kube-proxy_kube-proxy-wqgsf_kube-system_bfddaac1-be33-11e9-83e1-a4bf01560700_0
        b213c1018e7f      ncn-m001:5000/ck8s/gcr.io/google_containers/pause-amd64:3.1   "/pause"                  5 minutes ago     Up 5 minutes                  k8s_POD_kube-proxy-wqgsf_kube-system_bfddaac1-be33-11e9-83e1-a4bf01560700_0
        68fbfe9de926      221392217215                                                  "/install-cni.sh"         5 minutes ago     Up 5 minutes                  k8s_install-cni_kube-flannel-f7k72_kube-system_b4c7d042-be33-11e9-83e1-a4bf01560700_0
        1fd9266a1bcb      ff281650a721                                                  "/opt/bin/flanneld -…"   5 minutes ago     Up 5 minutes                  k8s_kube-flannel_kube-flannel-f7k72_kube-system_b4c7d042-be33-11e9-83e1-a4bf01560700_0
        dd38601b80b7      ncn-m001:5000/ck8s/gcr.io/google_containers/pause-amd64:3.1   "/pause"                  5 minutes ago     Up 5 minutes                  k8s_POD_kube-flannel-f7k72_kube-system_b4c7d042-be33-11e9-83e1-a4bf01560700_0
        0daef993079d      0482f6400933                                                  "kube-controller-man…"   7 minutes ago      Up 7 minutes                 k8s_kube-controller-manager_kube-controller-manager-nid000001_kube-system_3107cf6fc4bccdb80933833046f86891_0
        1db39258e071      fe242e556a99                                                  "kube-apiserver --al…"   7 minutes ago      Up 7 minutes                 k8s_kube-apiserver_kube-apiserver-nid000001_kube-system_8f15bd7298ea73bd06e06875551ae5ba_0
        b0655db4b84a      3a6f709e97a0                                                  "kube-scheduler --ad…"   7 minutes ago      Up 7 minutes                 k8s_kube-scheduler_kube-scheduler-nid000001_kube-system_97642c73bb31b2af5b91face60db1d38_0
        b48285dafba5      ncn-m001:5000/ck8s/gcr.io/google_containers/pause-amd64:3.1   "/pause"                  7 minutes ago      Up 7 minutes                 k8s_POD_kube-controller-manager-nid000001_kube-system_3107cf6fc4bccdb80933833046f86891_0
        062f5b86a082      ncn-m001:5000/ck8s/gcr.io/google_containers/pause-amd64:3.1   "/pause"                  7 minutes ago      Up 7 minutes                 k8s_POD_kube-apiserver-nid000001_kube-system_8f15bd7298ea73bd06e06875551ae5ba_0
        6cbd431ec8c2      ncn-m001:5000/ck8s/gcr.io/google_containers/pause-amd64:3.1   "/pause"                  7 minutes ago      Up 7 minutes                 k8s_POD_kube-scheduler-nid000001_kube-system_97642c73bb31b2af5b91face60db1d38_0
        895636b74cfa      ncn-m001:5000/ck8s/quay.io/coreos/etcd:v3.2.24                "/usr/local/bin/etcd"     9 minutes ago      Up 9 minutes                 etcd1
        ```

    3.  Check the Kubernetes node status.

        ```bash
        nid000001:~ # kubectl get nodes -o wide
        NAME        STATUS   ROLES         AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                          KERNEL-VERSION                      CONTAINER-RUNTIME
        nid000001   Ready    master,node   8m      v1.13.3   192.168.100.1   <none>        SUSE Linux Enterprise Server 15   4.12.14-15.5_8.1.96-cray_shasta_c   docker://18.9.2
        nid000002   Ready    master,node   7m4s    v1.13.3   192.168.100.2   <none>        SUSE Linux Enterprise Server 15   4.12.14-15.5_8.1.96-cray_shasta_c   docker://18.9.2
        nid000003   Ready    master,node   7m5s    v1.13.3   192.168.100.3   <none>        SUSE Linux Enterprise Server 15   4.12.14-15.5_8.1.96-cray_shasta_c   docker://18.9.2
        nid000004   Ready    node          6m23s   v1.13.3   192.168.100.4   <none>        SUSE Linux Enterprise Server 15   4.12.14-15.5_8.1.96-cray_shasta_c   docker://18.9.2
        ```




