# Troubleshoot Ceph image with tag:'&lt;none&gt;'

Use the following procedure to fix a Ceph image with tag: '&lt;none&gt;'.

All of the following commands should be run from the storage node that contains Ceph image with tag: '&lt;none&gt;'.

1. Run `podman images`.

   ```bash
    podman images
    ```

    Expected output:

    ```bash
    ncn-s002:~ # podman images
    REPOSITORY                                                                          TAG         IMAGE ID      CREATED        SIZE
    localhost:5000/ceph/ceph                                                            v17.2.5     1fa37f0e9d66  7 days ago     1.44 GB
    registry.local/ceph/ceph                                                            v17.2.5     1fa37f0e9d66  7 days ago     1.44 GB
    artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph                         v17.2.5     1fa37f0e9d66  7 days ago     1.44 GB
    localhost/registry                                                                  2.8.1       9fad34515fca  7 days ago     25.5 MB
    registry.local/ceph/ceph                                                            v16.2.9     695e78c903d1  7 days ago     1.24 GB
    artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph                         v16.2.9     695e78c903d1  7 days ago     1.24 GB
    localhost:5000/ceph/ceph                                                            v16.2.9     695e78c903d1  7 days ago     1.24 GB
    registry.local/ceph/ceph-grafana                                                    8.3.5       38b86afe3b11  7 days ago     788 MB
    registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph-grafana  8.3.5       38b86afe3b11  7 days ago     788 MB
    artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph-grafana                 8.3.5       38b86afe3b11  7 days ago     788 MB
    registry.local/quay.io/ceph/ceph-grafana                                            8.3.5       38b86afe3b11  7 days ago     788 MB
    localhost:5000/ceph/ceph-grafana                                                    8.3.5       38b86afe3b11  7 days ago     788 MB
    registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph          <none>      a3d3e58cb809  4 months ago   1.24 GB
    registry.local/quay.io/prometheus/node-exporter                                     v1.2.2      781e38abcb5c  18 months ago  22.6 MB
    artifactory.algol60.net/csm-docker/stable/quay.io/prometheus/node-exporter          v1.2.2      781e38abcb5c  18 months ago  22.6 MB
    ...
    ```

1. Fix the tag by running the following script on the storage node with the tag: '&lt;none&gt;'.

    1. Copy the script below and paste it into `/usr/share/doc/csm/scripts/fix_ceph_image_tag.sh`.

        ```bash
        #!/bin/bash

        images_tagged_none=$(podman images | grep "<none>" | awk '{print $1","$3}')
        for image in $images_tagged_none; do
            image_name=$(echo $image | cut -d',' -f1)
            image_id=$(echo $image | cut -d',' -f2)
            full_id=$(podman images $image_name --format json | jq '.[].Id' | grep $image_id | tr -d '"' | tail -1)
            version=$(podman images $image_name --format json | jq --arg FULL_ID $full_id '.[] | select (.Id == $FULL_ID) | .Labels."org.opencontainers.image.version"' | tr -d '"' | tail -1)
            podman pull ${image_name}:${version}
        done
        ```

    1. Change the mode of the script.

        ```bash
        chmod u+x /usr/share/doc/csm/scripts/fix_ceph_image_tag.sh
        ```

    1. Execute the script.

        ```bash
        /usr/share/doc/csm/scripts/fix_ceph_image_tag.sh
        ```

1. Verify the tag has been fixed by re-running `podman images`.

    ```bash
    podman images
    ```

    ```bash
    ncn-s002:~ # podman images
    REPOSITORY                                                                          TAG         IMAGE ID      CREATED        SIZE
    localhost:5000/ceph/ceph                                                            v17.2.5     1fa37f0e9d66  7 days ago     1.44 GB
    registry.local/ceph/ceph                                                            v17.2.5     1fa37f0e9d66  7 days ago     1.44 GB
    artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph                         v17.2.5     1fa37f0e9d66  7 days ago     1.44 GB
    localhost/registry                                                                  2.8.1       9fad34515fca  7 days ago     25.5 MB
    registry.local/ceph/ceph                                                            v16.2.9     695e78c903d1  7 days ago     1.24 GB
    artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph                         v16.2.9     695e78c903d1  7 days ago     1.24 GB
    localhost:5000/ceph/ceph                                                            v16.2.9     695e78c903d1  7 days ago     1.24 GB
    registry.local/ceph/ceph-grafana                                                    8.3.5       38b86afe3b11  7 days ago     788 MB
    registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph-grafana  8.3.5       38b86afe3b11  7 days ago     788 MB
    artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph-grafana                 8.3.5       38b86afe3b11  7 days ago     788 MB
    registry.local/quay.io/ceph/ceph-grafana                                            8.3.5       38b86afe3b11  7 days ago     788 MB
    localhost:5000/ceph/ceph-grafana                                                    8.3.5       38b86afe3b11  7 days ago     788 MB
    registry.local/artifactory.algol60.net/csm-docker/stable/quay.io/ceph/ceph          v16.2.9     a3d3e58cb809  4 months ago   1.24 GB
    registry.local/quay.io/prometheus/node-exporter                                     v1.2.2      781e38abcb5c  18 months ago  22.6 MB
    artifactory.algol60.net/csm-docker/stable/quay.io/prometheus/node-exporter          v1.2.2      781e38abcb5c  18 months ago  22.6 MB
    ...
    ```
