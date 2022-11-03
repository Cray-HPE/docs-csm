# Accessing `sat bootprep` Files

When performing an upgrade, NCN image customization and node personalization must be performed with the NCN worker node image to ensure the appropriate CFS layers are applied.
This step involves configuring CFS to use the default `sat bootprep` files from the `hpc-csm-software-recipe` repository and rebuilding the NCN worker nodes so they boot the newly customized image.

The following procedure describes how to access the CFS configuration. This procedure is used for both image customization and node personalization of NCNs.

1. (`ncn-m#`) Set up a script to obtain the `crayvcs` user password from the Kubernetes secret.

    ```bash
    cat > vcs-creds-helper.sh << EOF
    #!/bin/bash
    kubectl get secret -n services vcs-user-credentials -o jsonpath={.data.vcs_password} | base64 -d
    EOF
    
    chmod u+x vcs-creds-helper.sh
    
    export GIT_ASKPASS="$PWD/vcs-creds-helper.sh"
    ```

1. (`ncn-m#`) Clone the software recipe repo from the local Version Control Service (VCS).

    ```bash
    git clone https://crayvcs@api-gw-service-nmn.local/vcs/cray/hpc-csm-software-recipe.git
    ```

1. (`ncn-m#`) Change the current directory to the cloned repository.

    ```bash
    cd hpc-csm-software-recipe
    ```

1. (`ncn-m#`) (Optional) Disable the pager for Git command output.

    ```bash
    export GIT_PAGER=
    ```

1. (`ncn-m#`) Show the remote branches.

    ```bash
    git branch -r 
    ```

1. (`ncn-m#`) Check out the branch for the installed version.

    ```bash
    git checkout cray/hpc-csm-software-recipe/22.11
    ```

1. (`ncn-m#`) List the default `sat bootprep` input files in this repository:

    ```bash
    ls bootprep
    ```
