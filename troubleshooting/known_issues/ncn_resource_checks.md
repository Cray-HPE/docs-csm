# Known issues with NCN resource checks

- `pods_not_running`

  - If the output of `pods_not_running` indicates that there are pods in the `Evicted` state, it may be because of the root file system
    being filled up on the Kubernetes node in question. Kubernetes will begin evicting pods once the root file system space is at 85%
    full, and will continue to evict them until it is back under 80%. This commonly happens on `ncn-m001`, because it is a location where
    install and documentation files may have been downloaded. It may be necessary to clean up space in the `/` directory if this is the
    root cause of pod evictions.

    - (`ncn-mw#`) View the free space in the root file system.

        ```bash
        df -h /
        ```

    - (`ncn-mw#`) See how much space is being used in `/root/`.

        ```bash
        du -h -s /root/
        ```

    - (`ncn-mw#`) List the top 10 files in `/root/` that are 1024M or larger.

        ```bash
        du -ah -B 1024M /root | sort -n -r | head -n 10
        ```

  - The `hmn-discovery` and `cray-dns-unbound-manager` cronjob pods may be in a `NotReady` state. This is expected because these pods are periodically started
    and often can be caught in intermediate states.

  - If some `*postgresql-db-backup` cronjob pods are in `Error` state, they can be ignored if the most recent pod `Completed`.
    The `Error` pods are cleaned up over time but are left to troubleshoot issues in the case that all retries for the `postgresql-db-backup` job fail.
