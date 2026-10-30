# Post-Rollout Verification

1. [Post-Rollout Verification Steps](#1-post-rollout-verification-steps)
1. [Stop the typescript](#2-stop-the-typescript)
1. [References](#3-references)
1. [Next Steps](#4-next-steps)

## 1. Post-Rollout Verification Steps

After all nodes are rolled out, validate the system:

- **Online:** [Validate CSM Health](https://cray-hpe.github.io/docs-csm/en-17/operations/validate_csm_health/)
- **On-system:** `/usr/share/doc/csm/operations/validate_csm_health.md`

1. Confirm all management nodes are running the expected kernel:

   ```bash
   pdsh -w $(echo $(ceph orch host ls | grep ncn | cut -f1 -d" " | xargs) $(kubectl get nodes | grep ncn | cut -f1 -d" " | xargs) | sed 's/ /,/g') 'uname -r' |dshbak -c
   ```

   Example output:

   ```bash
   ----------------
   ncn-m[001-003],ncn-s[001-003],ncn-w[001-004]
   ----------------
   <NEW_KERNEL_VERSION>
   ```

   **Important:** Note that the kernel version `NEW_KERNEL_VERSION` is the version based on the current CSM version and RRU version, as specified in [Valid update paths](README.md#valid-update-paths).

1. Verify the `csm-security` product is registered in the product catalog:

   ```bash
   sat showrev --products | grep csm-security
   ```

   Expected output:

   ```bash
   | csm-security                        | <NEW_RRU_VERSION> | -                                           | -                                                   |
   ```

   **Important:** Note that `NEW_RRU_VERSION` is replaced with RRU version based on the current CSM version, as specified in [Valid update paths](README.md#valid-update-paths)

## 2. Stop the typescript

For any typescripts that were started during this preparation stage, stop them with the exit command.

## 3. References

- [Validate CSM Health](https://cray-hpe.github.io/docs-csm/en-17/operations/validate_csm_health/)

## 4. Next steps

- Return to the
  [Deploying Rapid Release Update with IUF](installation_iuf.md)
  workflow to continue the install.
