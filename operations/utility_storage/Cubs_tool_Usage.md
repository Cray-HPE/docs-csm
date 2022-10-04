# Cubs_tool Usage

## Introduction

Cubs_tool is a python script developed as a second tier Ceph upgrade watching tool.  This was to better integrate the Ceph upgrade process with the upgrade workflow tooling.

## Glossary

* **in_family** - is referring to an upgrade staying within the same major version of Ceph.  E.g, Any upgrade withing the same CSM release will container the same Major version of Ceph, but could have minor version bumps or patched containers.
  
## Usage

***IMPORTANT:*** The cubs_tool.py utility at this time will only work on `ncn-s00[1-3]`.  Please ensure you are only attempting to run this tool from one of those servers.  

```text
 # ./cubs_tool.py --help
usage: cubs_tool.py [-h] [--report] [--version VERSION] [--registry REGISTRY]
                    [--upgrade] [--in_family_override] [--quiet]

Ceph upgrade script

optional arguments:
  -h, --help            show this help message and exit
  --report              Provides a report of the state and versions of ceph
  --version VERSION     The target version to upgrade to or to check against.
                        Format example v15.2.15
  --registry REGISTRY   The registry where ceph container images are stored
  --upgrade             Upgrade toggle. Defaults to False
  --in_family_override  Flag to allow for "in family" upgrades and testing.
  --quiet               Toggle to enable/disable visual output
  ```

## Use Cases

1. Version and status report

   ```bash
   # ./cubs_tool.py --report
   +----------+-------------+-----------------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   |   Host   | Daemon Type |        ID       | Version |  Status |                                                              Image Name                                                             |
   +----------+-------------+-----------------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   | ncn-s001 |     mgr     | ncn-s001.onqtdd |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s002 |     mgr     | ncn-s002.wvswup |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s003 |     mgr     | ncn-s003.shehyr |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   +----------+-------------+-----------------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   +----------+-------------+----------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   |   Host   | Daemon Type |    ID    | Version |  Status |                                                              Image Name                                                             |
   +----------+-------------+----------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   | ncn-s001 |     mon     | ncn-s001 |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s002 |     mon     | ncn-s002 |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s003 |     mon     | ncn-s003 |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   +----------+-------------+----------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   +----------+-------------+----------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   |   Host   | Daemon Type |    ID    | Version |  Status |                                                              Image Name                                                             |
   +----------+-------------+----------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   | ncn-s001 |    crash    | ncn-s001 |  16.2.9 | running |                                                     localhost/ceph/ceph:v16.2.9                                                     |
   | ncn-s002 |    crash    | ncn-s002 |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s003 |    crash    | ncn-s003 |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   +----------+-------------+----------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   +----------+-------------+----+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   |   Host   | Daemon Type | ID | Version |  Status |                                                              Image Name                                                             |
   +----------+-------------+----+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   | ncn-s001 |     osd     | 1  |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s001 |     osd     | 5  |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s001 |     osd     | 8  |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s002 |     osd     | 2  |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s002 |     osd     | 3  |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s002 |     osd     | 7  |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s003 |     osd     | 0  |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s003 |     osd     | 4  |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s003 |     osd     | 6  |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   +----------+-------------+----+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   +----------+-------------+------------------------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   |   Host   | Daemon Type |           ID           | Version |  Status |                                                              Image Name                                                             |
   +----------+-------------+------------------------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   | ncn-s001 |     mds     | cephfs.ncn-s001.oqemhh |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s002 |     mds     | cephfs.ncn-s002.icrynx |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s003 |     mds     | cephfs.ncn-s003.xiwxma |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   +----------+-------------+------------------------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   +----------+-------------+-----------------------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   |   Host   | Daemon Type |           ID          | Version |  Status |                                                              Image Name                                                             |
   +----------+-------------+-----------------------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   | ncn-s001 |     rgw     | site1.ncn-s001.ssomes |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s002 |     rgw     | site1.ncn-s002.lezusi |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   | ncn-s003 |     rgw     | site1.ncn-s003.elzhgw |  16.2.9 | running | artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph@sha256:91a3dd8d1f4534590897f65c4883459261f812027d783cbeec3ccc9718c128d6 |
   +----------+-------------+-----------------------+---------+---------+-------------------------------------------------------------------------------------------------------------------------------------+
   ```

1. Upgrade check

   ```bash
    # ./cubs_tool.py --version 16.2.10 --registry localhost
      Upgrade Available!!  The specified version v16.2.10 has been found in the registry
    ```

1. Upgrade

   ```bash
    # ./cubs_tool.py --version 16.2.10 --registry localhost --upgrade
   ```

1. In-family Upgrade

   ```bash
    # ./cubs_tool.py --version 16.2.10 --registry localhost --upgrade
   ```

## Troubleshooting

1. Upgrade is taking to long or is not reporting the status correctly
   1. There is a scenario where the upgrade could get wedged.  This typically occurs when there is an issue with pulling an image.
      1. Utilize `ceph orch upgrade status` to get the true status of the upgrade.
         1. If it is showing `"in_progress": false` then the upgrade has either completed or failed. This can be confirmed by checking the output of a `cubs_tool.py --report` and verifying the image sha and version are correct.
