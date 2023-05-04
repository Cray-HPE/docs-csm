# CRUS Subcommands Missing From Cray CLI

- [Summary](#summary)
- [Checking CLI version](#checking-cli-version)
- [Symptom](#symptom)
  - [Cray CLI](#cray-cli)
  - [`cmsdev` health check](#cmsdev-health-check)
- [Workaround](#workaround)
- [Fix](#fix)

## Summary

In version 0.71.0 of the Cray CLI RPM (shipped with CSM 1.4.0), the CRUS subcommands are mistakenly missing from
the CLI. This is corrected in version 0.72.0 of the Cray CLI, which ships with CSM 1.4.1.

## Checking CLI version

(`ncn#`) The version of the installed Cray CLI RPM can be checked using the following command:

```bash
rpm -q craycli
```

If the version of the RPM with this error is installed, then the output will be:

```text
craycli-0.71.0-1.x86_64
```

## Symptom

### Cray CLI

(`ncn#`) The problem can be seen when attempting to run CRUS commands in the Cray CLI. For example:

```bash
cray crus session list
```

On the Cray CLI version where this error is present, this command will result in the following error message:

```text
Usage: cray [OPTIONS] COMMAND [ARGS]...
Try 'cray --help' for help.

Error: No such command 'crus'.
```

### `cmsdev` health check

This error can also cause a failure when running the `cmsdev` health check utility. In that case, the error will resemble the following:

```text
ERROR (run tag KPEqc-crus): CLI command failed (and does not look like a CLI config issue) (crus session list --format json)
```

## Workaround

Until the update Cray CLI RPM is installed, the only workaround is to access CRUS directly using its API. For details on how to use the API,
see its [Swagger specification](https://github.com/Cray-HPE/cray-crus/blob/v1.11.2/api/openapi.yaml).

## Fix

This issue is corrected in version 0.72.0 of the Cray CLI RPM, which ships as part of CSM 1.4.1. After upgrading to CSM 1.4.1, the updated CLI RPM
will be installed on management nodes after they have successfully completed
[Management Node Personalization](../../operations/configuration_management/Management_Node_Personalization.md). To verify that the new version is
installed, use the command from the [Checking CLI version](#checking-cli-version) section.
