# Create and Populate a VCS Configuration Repository

Create a new repository in the VCS and populate it with content for site customizations in a custom Configuration Framework Service
\(CFS\) configuration layer.

## Prerequisites

* The Version Control Service \(VCS\) login credentials for the `crayvcs` user are set up.
  See [VCS Administrative User](Version_Control_Service_VCS.md#vcs-administrative-user) in
  [Version Control Service (VCS)](Version_Control_Service_VCS.md) for more information.

## Procedure

1. Create the empty repository in VCS.

    Replace the `CRAYVCS_PASSWORD` value in the following command before running it.

    ```bash
    ncn-mw# curl -X POST https://api-gw-service-nmn.local/vcs/api/v1/org/cray/repos \
                -d '{"name": "NEW_REPO", "private": true}' -u crayvcs:CRAYVCS_PASSWORD \
                -H "Content-Type: application/json"
    ```

1. Clone the empty VCS repository.

    ```bash
    ncn-mw# git clone https://api-gw-service-nmn.local/vcs/cray/NEW_REPO.git
    ```

1. Change to the directory of the empty Git repository and populate it with content.

    ```bash
    ncn-mw# cd NEW_REPO
    ncn-mw# cp -a ~/user/EXAMPLE-config-management/*  .
    ```

1. Add the new content, commit it, and push it to VCS.

    The following command will move the content to the master branch of the repository.

    ```bash
    ncn-mw# git add --all && git commit -m "Initial config" && git push
    ```

1. Retrieve the Git hash for the CFS layer definition.

    ```bash
    ncn-mw# git rev-parse --verify HEAD
    ```
