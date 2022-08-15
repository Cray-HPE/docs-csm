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

  - The `cray-crus-` pod is expected to be in the `Init` state until Slurm and MUNGE
    are installed. In particular, this will be the case if executing this as part of the validation after completing the
    [Install CSM Services](../install/install_csm_services.md).

    If in doubt, validate the CRUS service using the [CMS Validation Tool](../../operations/validate_csm_health.md#3-software-management-services-health-checks).
    If the CRUS check passes using that tool, then do not worry about the `cray-crus-` pod state.

  - The `hmn-discovery` and `cray-dns-unbound-manager` cronjob pods may be in a `NotReady` state. This is expected because these pods are periodically started
    and often can be caught in intermediate states.
