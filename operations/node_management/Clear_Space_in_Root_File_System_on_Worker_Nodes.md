# Clear Space in Root File System on Worker Nodes

The disk space on an NCN worker node can fill up if any services are consuming a large portion of the root file system on the node. This procedure shows how to safely clear some space on worker nodes to return them to an appropriate storage threshold.

## Prerequisites

An NCN worker node has a full disk.

### Procedure

1. Check to see if Docker is running.

    ```bash
    ncn-w001# syctemctl status docker
    ● docker.service - Docker Application Container Engine
       Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor pres>
       Active: **active** (running) since Wed 2020-06-10 11:03:49 CDT; 2 months 2 days >
         Docs: http://docs.docker.com
     Main PID: 3062 (dockerd)
        Tasks: 145
       CGroup: /system.slice/docker.service
               ├─3062 /usr/bin/dockerd --add-runtime oci=/usr/sbin/docker-runc
               ├─3248 docker-containerd --config /var/run/docker/containerd/contain>
               ├─5557 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port >
               └─5576 docker-containerd-shim -namespace moby -workdir /var/lib/dock>

    ...
    ```

    If Docker is active, proceed to the next step to check its usage.

2. View the file space usage for Docker.

    ```bash
    ncn-w001# du -sh /var/lib/docker
    178G    /var/lib/docker
    ```

    If the output indicates usage is over 100GB, proceed to the next step to prune Docker.

3. Prune the Docker images.

    The `until=24` option in the command below preserves data less than one day old.

    ```bash
    ncn-w001# docker image prune -a --filter until=24h
    ```

    Check the usage again with the `du -sh /var/lib/docker` command.

4. Prune the Docker volumes.

    The `until=24` option in the command below preserves data less than one day old.

    ```bash
    ncn-w001# docker volume prune -a --filter until=24h
    ```

    Check the usage again with the `du -sh /var/lib/docker` command.

5. Check the usage of /var/log/cray.

    Another potentially large consumer of space is /var/log/cray when certain debug flags are enabled.

    ```bash
    ncn-w001# du -sh /var/log/cray
    76M     /var/log/cray
    ```

    If the usage is over 20GB, examine the logging and determine if any of the older log information needs to be kept. Candidates for clean up include old imfile-state files, as well as old forwarding-queue files. Reduce the quantity of any additional logging as soon as possible to prevent the disk from filling up again.
