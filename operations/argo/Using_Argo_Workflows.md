# Using Argo Workflows

This page provides information on operating Argo workflows in CSM and describes how Argo workflows behave once starting.

* [Basic behavior](#basic-behavior)
* [Starting a new workflow after a failed workflow](#starting-a-new-workflow-after-a-failed-workflow)

## Basic behavior

* Once a workflow is started, it will proceed through multiple steps in a set order. Most steps depend on previous steps and will wait for its dependencies to finish before starting.
* If any step fails, by default, that step will be continuously retried until it succeeds.
There are two ways to make Argo not continuously retry a failed step.

    1. When initiating a workflow, use the `--no-retry` flag.

        (`ncn-m001#`) Example of starting a workflow with `--no-retry` flag

        ```bash
        /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-s001 --no-retry
        ```

        > Note: `--no-retry` will not work if the `--force` flag is also used.

    1. If a workflow has already started, then the current running process can be exited with `control-c`. The workflow will continue until all steps succeed or a step fails. If a step fails, then the workflow will stop and will not retry.

## Starting a new workflow after a failed workflow

Generally, any workflow that is partially complete has the right of way. A partially complete workflow is any workflow that is currently running or any workflow that has a failed step that prevented it from completing successfully.

* To start an entirely new workflow of the same type (worker or storage) as a workflow that is partially complete, the `--force` flag must be used. This deletes the partially complete workflow of the same type, and creates a new workflow.

    (`ncn-m001#`) Example of starting a new workflow with `--force` flag:

    ```bash
    /usr/share/doc/csm/upgrade/scripts/upgrade/ncn-upgrade-worker-storage-nodes.sh ncn-s001 --force
    ```

* If there is a partially complete workflow and `--force` is not used when starting a new workflow of the same type, then the initial workflow will be picked up where it left off. No new workflow will be created.
