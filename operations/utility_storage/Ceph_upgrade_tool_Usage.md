# `ceph-upgrade-tool.py` Usage

* [Introduction](#introduction)
* [Usage](#usage)
* [What is `ceph-upgrade-tool.py`](#what-is-ceph-upgrade-toolpy)
* [Troubleshooting](#troubleshooting)

## Introduction

The `ceph-upgrade-tool.py` is a python script developed as a second tier Ceph upgrade watching tool, in order to better integrate the Ceph upgrade process with the upgrade workflow tooling.

## Usage

The `ceph-upgrade-tool.py` is called by the storage node upgrade Argo Workflow. This is not something that is run manually.
However, for troubleshooting purposes and if there is a specific instance where the `ceph-upgrade-tool.py` is run manually, this documentation provides an overview of the tool.

This script can be run from master nodes.

(`ncn-m#`) Run the following command to see the tool usage.

```bash
/usr/share/doc/csm/upgrade/scripts/ceph/ceph-upgrade-tool.py --help
```

Example output:

```bash
usage: ceph-upgrade-tool.py [-h] --version VERSION [--print_basic]

Ceph upgrade script

optional arguments:
  -h, --help         show this help message and exit
  --version VERSION  The target version to upgrade Ceph to. Format example
                     v15.2.15
  --print_basic      Basic status will be printed in text. A pretty-table will
                     not be printed.
```

To upgrade to Ceph version: `x.y.z`, the following command could be used.

```bash
/usr/share/doc/csm/upgrade/scripts/ceph/ceph-upgrade-tool.py --version "x.y.z"
```

## What is `ceph-upgrade-tool.py`

The `ceph-upgrade-tool.py` tool starts a Ceph upgrade to the version provided. It does this in the following way.

1. It verifies that the Ceph version provided is valid.
1. It verifies that the Ceph container image can be pulled from Nexus. It specifically tries to pull the container image from `registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v<input_version>`.
1. If the container exists in Nexus, then the script will start a Ceph upgrade by running `ceph orch upgrade start --image <container_image>`.
1. It then monitors the upgrade by running `ceph orch upgrade status` and printing a pretty-table of the results.

## Troubleshooting

* To manually check the status of a Ceph upgrade, run `ceph orch upgrade status`.
* To stop a Ceph upgrade, run `ceph orch upgrade stop`.
* If an upgrade appears stuck, make sure all of the `mgr` daemons have been upgraded. The 3 `mgr` daemons should be the first to upgrade. If only one or two have upgraded and the third is not being upgraded for some reason, try running the following steps.

    1. Stop the current upgrade.

        ```bash
        ceph orch upgrade stop
        ```

    2. Manually try and force the `mgr` daemon onto the new container image. Set the container image that the `mgr` should be upgraded to and set the name of the `mgr` daemon that needs to be upgraded.

        ```bash
        container_image="registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph:v<version>"
        mgr_daemon="mgr.ncn-s00X.xxxxx"
        ```

        ```bash
        ceph orch daemon redeploy $mgr_daemon $container_image
        ```

        If the above command fails, try running `ceph mgr fail` and then rerunning the command above.

    3. Once all three `mgr`s are running the upgraded container image, restart the Ceph upgrade.
    You can restart the upgrade by running `ceph-upgrade-tool.py` or by manually restarting it with `ceph orch upgrade start --image $container_image`.
