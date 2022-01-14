
## Remove Artifacts from Product Installations

Remove product artifacts that were imported from various Cray products. These instructions provide guidance for removing Image Management Service (IMS) images, IMS recipes, and Git repositories present in the Cray Product Catalog from the system.

The examples in this procedure show how to remove the product artifacts for the Cray System Management (CSM) product.

**WARNING:** If individual Cray products have removal procedures, those instructions supersede this procedure.

### Procedure

1. View the imported artifacts by printing them from the Cray Product Catalog ConfigMap.

    ```bash
    ncn-m001# kubectl get cm cray-product-catalog -n services -o json | jq -r .data.csm
    ```

    Example output:

    ```
    1.0.0:
    configuration:
        clone_url: https://vcs.SYSTEM_DOMAIN_NAME/vcs/cray/csm-config-management.git
        commit: 123264ba75c809c0db7742ea83ff57f713bc1562
        import_branch: cray/csm/1.4.5
        import_date: 2021-03-12 15:12:49.938936
        ssh_url: git@vcs.SYSTEM_DOMAIN_NAME:cray/csm-config-management.git
    images:
        cray-shasta-csm-sles15sp1-barebones.x86_64-shasta-1.4:
        id: 4871cb4a-e055-4131-a228-c0a26f0903cd
    recipes:
        cray-shasta-csm-sles15sp1-barebones.x86_64-shasta-1.4:
        id: 5f5a74e0-108e-4159-9699-47dd2a952205
    ```

2. Remove the imported IMS images using the ID of each image in the *images* mapping.

   The example in step 1 includes one image with the *id = 4871cb4a-e055-4131-a228-c0a26f0903cd* value. Remove the image with the following command:

    ```bash
    ncn-m001# cray ims images delete 4871cb4a-e055-4131-a228-c0a26f0903cd
    ```

3. Remove the imported IMS recipes using the ID of each recipe in the *recipes* mapping.

   The example in step 1 includes one recipe with the *id = 5f5a74e0-108e-4159-9699-47dd2a952205* value. Remove the image with the following command:

    ```bash
    ncn-m001# cray ims recipes delete 5f5a74e0-108e-4159-9699-47dd2a952205
    ```

4. Remove the Gitea repositories or branches.

    To delete a Git branch as specified in the product catalog, follow the external instructions to [delete Git remote branches](https://git-scm.com/book/en/v2/Git-Branching-Remote-Branches). The branch name is located in the *import_branch* field.

    If only one version of the product exists (as in the CSM example), the user can remove the entire repository instead of a single branch. Gitea repositories can be removed via the Gitea web interface or via the Gitea REST API.

    **Gitea web interface:**

       1. Log in to Gitea as the *crayvcs* user.
          1. From the dashboard, select the repository to delete based on the name of the repository in the *clone_url* field of the product catalog.
          2. Click on "Settings" and scroll to the bottom of the page to the "Danger Zone" section. Follow the instructions to delete the repository.

    **Gitea REST API:**

    Run the following commands on a CSM Kubernetes master or worker node, replacing the name of the repository in the second command.

    ```bash
    ncn-m001# VCSPWD=$(kubectl get secret -n services vcs-user-credentials \
    --template={{.data.vcs_password}} | base64 --decode)
    ncn-m001# curl -X DELETE -u crayvcs:${VCSPWD} \
    https://api-gw-service-nmn.local/vcs/api/v1/repos/cray/{name of repository}
    ```

5. Update the product catalog.

    Once the images, recipes, and repositories/branches have been removed from the system, update the product catalog to remove the references to them. This is done by editing the cray-product-catalog Kubernetes ConfigMap.

    ```bash
    ncn-m001# kubectl edit configmap -n services cray-product-catalog
    ```

    In the editor, delete the entries for the artifacts that were deleted on the system for the specific version of the product. In this example, all artifacts were deleted and only a single product version exists, so the entire entry in the product catalog for the CSM product can be deleted. Save the changes and exit the editor to persist the changes in the ConfigMap.

