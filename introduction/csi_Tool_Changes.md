# `csi` Tool Changes

CSM 1.7.0 includes a major version bump for [Cray Site Init (CSI)](../glossary.md#cray-site-init-csi).

* [Main feature](#main-feature)
* [IPv6 support](#ipv6-support)
    * [`csi patch csm ipv6`](#csi-patch-csm-ipv6)
        * [Removing/undoing IPv6](#removingundoing-ipv6)
        * [Scoping](#scoping)
* [Behavior changes](#behavior-changes)
    * [System administrator changes](#system-administrator-changes)
    * [Other behavior changes](#other-behavior-changes)
* [Flag changes](#flag-changes)
    * [`csi config init` flag changes](#csi-config-init-flag-changes)
        * [`csi config init` new flags](#csi-config-init-new-flags)
        * [`csi config init` deprecated flags](#csi-config-init-deprecated-flags)
    * [`csi` main program new flags](#csi-main-program-new-flags)
* [Sub-command changes](#sub-command-changes)
    * [`csi patch` new sub-commands](#csi-patch-new-sub-commands)
    * [`csi patch` deprecated sub-commands](#csi-patch-deprecated-sub-commands)
    * [Removed sub-commands](#removed-sub-commands)
* [Bugfixes](#bugfixes)

## Main feature

* **Added IPv6 enablement for fresh installs and already deployed CSM systems**
* cloud-init data for IPv6 addresses and gateways on the
  [CMN](../glossary.md#customer-management-network-cmn)
* [SLS](../glossary.md#system-layout-service-sls) data for IPv6 addresses and gateways on the CMN and
  [CHN](../glossary.md#customer-high-speed-network-chn)
* Supports IPv6 NTP servers
* Supports IPv6 site link (only supports IPv4 or IPv6 exclusively)
* **Extensive usage changes** and bug fixes in support of the new features. This includes behavior
  changes to `csi config` that administrators performing fresh installs of CSM should be aware of.

## IPv6 support

IPv6 data is now consumed during a fresh install during `csi config init` by including the new IPv6 keys:

* `chn-gateway6`
* `chn-cidr6`
* `cmn-gateway6`
* `cmn-cidr6`

> These new keys deprecate some existing keys. For details, see
> [`csi config init` new flags](#csi-config-init-new-flags).

For runtime/upgrades, the same flags are used but with the `csi patch csm ipv6` command. This
command will patch SLS with IPv6 reservations for the `bootstrap_dhcp` and `network_hardware`
subnets in the CHN and CMN. The list of subnets can be overridden, but not the list of networks,
and only during the `csi patch csm ipv6` command (not during `csi config init`). This command is
designed to be repeatable for use after new hardware has been added.

### `csi patch csm ipv6`

This command defaults to a dry run; all proposed changes to BSS and SLS are written to a
timestamped subdirectory of the current working directory (unless otherwise overridden by
`-b|--backup-dir`) along with backups of the original data.

Passing `--commit` to the command disables the dry run; all proposed changes and backups are
written in the same manner as the dry run, before being applied to
[BSS](../glossary.md#boot-script-service-bss) and SLS.

This command skips entries that already have IPv6 data unless the `-f|--force` flag is present.
This means:

* Re-running `csi patch csm ipv6` on an already patched system with no hardware changes will result
  in no change
* Re-running `csi patch csm ipv6` on an already patched system *with new hardware added* will result
  in new IP address reservations and BSS data *for only that hardware*
* Re-running `csi patch csm ipv6 --force` will update existing IPv6 addresses within
  the scope of `csi patch csm ipv6`

Without `--force`, `csi patch csm ipv6` respects any existing `IPAddress6` reservations in BSS and
SLS installed by hand (e.g. by the customer or administrator). Be aware that after the first run of
CSI `--commit`, the generated backups are the only way to restore the manually added `IPAddress6`
reservations.

#### Removing/undoing IPv6

`csi patch csm ipv6` has a `--remove` flag, and by default this flag runs as a dry run unless
`--commit` is present. This removes all IPv6 data in BSS and SLS within the scope of
`csi patch csm ipv6`, e.g. the CHN, CMN, and their `bootstrap_dhcp` and `network_hardware` subnets
(unless otherwise overridden with `--subnets`).

`--remove` creates backups in the same manner as the `patch` command.

#### Scoping

By default, `csi patch csm ipv6` targets the `bootstrap_dhcp` and `network_hardware` subnets within the
[Customer High-speed Network (CHN)](../glossary.md#customer-high-speed-network-chn) and
[Customer Management Network (CMN)](../glossary.md#customer-management-network-cmn).

* The list of targeted subnets can be overridden with the `--subnets` flag (see usage)
* The list of targeted networks **are not** configurable beyond the CHN and CMN;
  In order to exclude one or the other, omit the corresponding flags (e.g. leave out
  `--chn-cidr6/--chn-gateway6` to omit the CHN)

> ***NOTE***: Any SLS `IPReservation` within the target subnets will be given IPv6 leases (e.g. every
> `IPReservation` entry in the CMN's `bootstrap_dhcp` subnet will receive an `IPAddress6` entry; there
> is no hardware filter or differentiator to choose otherwise).

## Behavior changes

### System administrator changes

These changes may be particularly important for system administrators and configuration maintainers
to be aware of.

* `csi config init empty` and `csi config init` produce `system_config.yaml` files without deprecated
  flags, alias flags, and program assistant flags.
    * Examples of flags that are now omitted in the generated `system_config.yaml` files:
        * `config` and `help`
        * `cmn-gw` and `can-gw`
        * Deprecated keys (e.g. `bgp-peers`)
    * For more details on newly deprecated `csi config init` flags, see
      [`csi config init` deprecated flags](#csi-config-init-deprecated-flags).
    * ***It is strongly recommended*** to update saved configurations with the new `system_config.yaml`
      after running this newer CSI.
        * CSI will remind users to replace existing backups with the newly generated `system_config.yaml`
          file after running `csi config init`
* All generated files from `csi config init` now include additional information in their headers.
    * This is not true in cases where this would be illegal for the particular file format.
    * The following new information is added:
        * The version of CSI that generated them
        * A timestamp of when `csi config init` was called
    * Example:

        ```text
        #
        ## This file was generated by cray-site-init.
        ## Version: 2.0.5
        ## Generated time: 2025-08-02T21:09:36.528837Z
        #
        ```

### Other behavior changes

* `csi config init` will exit immediately if any generated file fails to template.
    * Previously, `csi` would carry on and possibly leave the user with malformed files. The user would
      need to decipher an error happened between the dozens of innocuous messages printed to screen.
    * Now, if a template fails to generate for any reason the program will exit with an error.
    * *NOTE* Some templates required a refactor for this failure to be properly acknowledged, and while
      this issue is fixed, it remains broken for templates like `metallb.yaml`
* ***IMPORTANT*** 1-2 addresses shift IP address reservations in some subnets
    * Previously, all subnet reservations started with a +2 deviation from their subnet's IP address to
      account for the subnet IP address and gateway IP address
    * Now, this logic only applies to a subnet that shares the same IP address as its "super net" network
    * ***IMPORTANT*** Systems that are fresh installing CSM 1.7 that had been running a previous version
      of CSM 1.6 must regenerate their switch configurations in order for BGP to work.

## Flag changes

### `csi config init` flag changes

#### `csi config init` new flags

> In some cases, a new flag deprecates an existing flag.
> Using deprecated flags will cause a warning to be emitted.

* `chn-gateway6`
* `chn-cidr6`
* `cmn-gateway6`
* `cmn-cidr6`
* `cmn-cidr4`
    * *Deprecates* `cmn-cidr`
* `cmn-gateway4`
    * *Deprecates* `cmn-gateway`
* `chn-cidr4`
    * *Deprecates* `chn-cidr`
* `chn-gateway4`
    * *Deprecates* `chn-gateway`

#### `csi config init` deprecated flags

> Some existing flags are deprecated by new flags.
> Using deprecated flags will cause a warning to be emitted.

* `cmn-cidr`
    * Deprecated by `cmn-cidr4`
* `cmn-gateway`
    * Deprecated by `cmn-gateway4`
* `chn-cidr`
    * Deprecated by `chn-cidr4`
* `chn-gateway`
    * Deprecated by `chn-gateway4`

### `csi` main program new flags

* `--input-dir`/`-i` specifies the directory to look in for input files
    * `system_config.yaml` is an exception
        * This flag has no impact on where `csi` looks for `system_config.yaml`
        * By default, `system_config.yaml` is looked for in the current working directory
        * An alternative path to `system_config.yaml` can be specified using `--config`/`-c`
    * This defaults to the current working directory
    * (`pit#`) Usage example on a PIT node:

        ```bash
        /tmp/csi config init -i /var/www/ephemeral/prep -c /var/www/ephemeral/prep/system_config.yaml
        ```

    * (`linux#`) Usage example on a local workstation:

        ```bash
        ./csi config init -i ~/gitstuff/hpc-shasta-system-config/redbull/1.6 -c ~/gitstuff/hpc-shasta-system-config/redbull/1.6/system_config.yaml
        ```

* `--k8s-secret-name` and `--k8s-namespace` can be used to override the location to read the OpenID token
    * Used with a completed CSM installation
    * These default to `admin-client-auth` and `default`, respectively
* `--csm-api-url` can be used to change the target API URL
    * Used with a completed CSM installation
    * This defaults to `https://api-gw-service-nmn.local`

## Sub-command changes

### `csi patch` new sub-commands

> In some cases, a new sub-command deprecates an existing sub-command.
> Deprecated sub-commands will not appear in `csi --help` usage, and invoking them will emit a warning.

* `csi patch csm ipv6` will patch IPv6 data into CSM for network devices, application nodes,
  and non-compute nodes.
* `csi patch init ca`
    * *Deprecates* `csi patch ca`
* `csi patch init packages`
    * *Deprecates* `csi patch packages`

### `csi patch` deprecated sub-commands

> Some existing sub-commands are deprecated by new sub-commands.
> Deprecated sub-commands will not appear in `csi --help` usage, and invoking them will emit a warning.

* `csi patch ca`
    * Deprecated by `csi patch init ca`
* `csi patch packages`
    * Deprecated by `csi patch init packages`

### Removed sub-commands

* `csi config load` (no longer used and had outdated/unmaintained structures)
* `csi pit get` (no longer used and was causing problems with the lint workflow
  and circular dependencies)

## Bugfixes

* Fixed an erroneous message during `csi config init` where "disk configuration"
  would print once for each NCN.
* Fixed a bug in the DNSMasq files where the `domain=` key was set to the SLS subnet
  start and end IP address, instead of the entire network.
* Fixes an issue where deprecated keys that had aliases were still required. This problem
  was caused by the split-brain aspect of the Cobra command line vs. the Viper configurations.
  Now keys are merged and removed and replaced with aliased values as defined by Cobra. This was
  necessary for the proper deprecation of `chn-cidr`, `chn-gateway`, `cmn-cidr`, and `cmn-gateway`.
* Now prohibits setting overlapping CIDRs between the `*-cidr` parameters during `csi config init`
  and `csi patch csm ipv6`.

[introduction/csi_Tool_Changes.md](#bugfixes)

[introduction/csi_Tool_Changes.md](#csi-config-init-deprecated-flags)

[introduction/csi_Tool_Changes.md](#csi-patch-deprecated-sub-commands)

[introduction/csi_Tool_Changes.md](#other-behavior-changes)

[introduction/csi_Tool_Changes.md](#removed-sub-commands)
