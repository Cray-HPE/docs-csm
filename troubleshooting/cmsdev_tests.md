# `cmsdev` Tests

The `cmsdev` test tool verifies the health, functionality, and API operations of critical system services, including
[BOS](../glossary.md#boot-orchestration-service-bos) (Boot Orchestration Service),
[CFS](../glossary.md#configuration-framework-service-cfs) (Configuration Framework Service), console services,
[IMS](../glossary.md#image-management-service-ims) (Image Management Service), iPXE, TFTP, and
[VCS](../glossary.md#version-control-service-vcs) (Version Control Service).

This document provides detailed information about the `cmsdev` test tool, including the tests available for each service, command-line options, and usage examples.

* [Overview](#overview)
* [Test execution](#test-execution)
* [Interpreting results](#interpreting-results)
* [Command-line options](#command-line-options)
    * [List available tests](#list-available-tests)
    * [Test control options](#test-control-options)
        * [Retry behavior](#retry-behavior)
    * [Output control options](#output-control-options)
* [Service-specific tests](#service-specific-tests)
    * [BOS tests](#bos-tests)
    * [CFS tests](#cfs-tests)
    * [Conman tests](#conman-tests)
    * [IMS tests](#ims-tests)
    * [iPXE/TFTP tests](#ipxetftp-tests)
    * [VCS tests](#vcs-tests)
* [Usage examples](#usage-examples)
    * [Basic test execution](#basic-test-execution)
    * [Advanced test scenarios](#advanced-test-scenarios)
* [Version information](#version-information)
* [Logging](#logging)
    * [Log changes](#log-changes)
        * [Log file migration](#log-file-migration)
        * [Run tags](#run-tags)
* [Additional resources](#additional-resources)

## Overview

The `cmsdev` test suite validates the health and functionality of Software Management Services by performing the following types of checks:

* Kubernetes resource validation
    * Verifies that pods, persistent volume claims (PVCs), and other Kubernetes resources exist and are in expected states.
* API operation testing
    * Tests CRUD (Create, Read, Update, Delete) operations via REST APIs to ensure services respond correctly.
* CLI operation testing
    * Validates Cray CLI commands for services (when `--include-cli` flag is used).
* Multi-tenancy testing
    * Tests tenant-specific operations (when `--include-tenant` flag is used). See [Multi-Tenancy Support](../operations/multi-tenancy/Overview.md) for more information on multi-tenancy in CSM.
* Service-specific functionality
    * Specialized tests unique to each service (e.g., TFTP file transfers, VCS repository operations).

## Test execution

This test requires that the Cray CLI is configured on nodes where the test is executed.
See [Cray command line interface](../operations/validate_csm_health.md#0-cray-command-line-interface).

This test can be run on any Kubernetes NCN (any master or worker NCN, but **not** the PIT node).
When run on a Kubernetes master NCN, the TFTP file transfer subtest is omitted. However, that TFTP subtest is
run on a worker NCN as part of the Goss NCN health checks.

(`ncn-mw#`) The following command runs the `cmsdev` test suite for all services.
CLI and multi-tenancy subtests will be excluded (see [Test control options](#test-control-options) for details on how to include them).
Additionally, the TFTP file transfer subtest is omitted on master NCNs, as noted earlier.

```bash
/usr/local/bin/cmsdev test -q all
```

The `-q` (quiet) or `-v` (verbose) flags can be added to decrease or increase the amount of information sent to the screen.
The same amount of data is written to the log file in either case. For more details on the log file, see [Logging](#logging).

## Interpreting results

* If all checks are passed, the following will be true:
    * The return code will be zero.
    * The final line of output will begin with `SUCCESS`.
        * For example: `SUCCESS: All 6 service tests passed: bos, cfs, conman, ims, tftp, vcs`
* If one or more checks are failed, the following will be true:
    * The return code will be non-zero.
    * The final line of output will begin with `FAILURE` and lists the failed checks.
        * For example: `FAILURE: 2 service tests FAILED (conman, ims), 4 passed (bos, cfs, tftp, vcs)`
    * After remediating a test failure for a particular service, just that single service test can be rerun by replacing
      `all` in the `cmsdev` command line with the name of the service. For example: `/usr/local/bin/cmsdev test -q cfs`

Additional test execution details can be found in the log file.
For more details on the log file, see [Logging](#logging).

## Command-line options

The `cmsdev test` command supports various options to control test execution, output, and logging.

### List available tests

(`ncn-mw#`) To list all available service tests, run the following command:

```bash
/usr/local/bin/cmsdev test --list
```

Example output:

```text
all bos cfs conman ims ipxe tftp vcs gitea
```

### Test control options

| Option | Short | Description |
|--------|-------|-------------|
| `--include-cli` | | Include CLI tests for applicable services |
| `--include-tenant` | | Include tenant-specific tests (multi-tenancy validation) for applicable services |
| `--retry` | `-r` | Retry failed tests with exponential backoff until timeout |
| `--no-cleanup` | | Do not remove temporary test files after execution |

By default, only API tests are run. CLI and tenant tests are optional.

#### Retry behavior

When `--retry` is specified, tests will retry on failure after waiting for an interval of time.

* After the first failure, the initial retry interval is 5 seconds
* Each subsequent interval is 5 seconds longer than the previous interval
* The interval is capped at a maximum of 1/6 of the test timeout value
* The test timeout is the time after which the test will no longer retry on failure. This value varies for the different services.
    * For BOS, CFS, console services, iPXE/TFTP, and VCS, the timeout is 300 seconds
    * Otherwise, the timeout is 120 seconds

### Output control options

| Option | Short | Description |
|--------|-------|-------------|
| `--quiet` | `-q` | Quiet mode (minimal console output) |
| `--verbose` | `-v` | Verbose mode (detailed console output) |
| `--no-log` | | Do not write to log file |
| `--log-dir <path>` | | Specify custom base log directory where timestamped subdirectories will be created (default: `/opt/cray/tests/install/logs/cmsdev/`). See [Logging](#logging) for details. |

**Note**: `--quiet` and `--verbose` are mutually exclusive.

## Service-specific tests

### BOS tests

Validate the Boot Orchestration Service (BOS) service health, API operations, and CLI functionality using the following tests:

* Pod status verification (always run)
    * Verifies at least 3 BOS pods are running
    * Checks for BOS API, operator, and other component pods
    * Ensures migration pods (if present) have "Succeeded" status
    * Validates that all non-migration pods are in "Running" state
* API tests (always run)
    * Version endpoint: Validates BOS version information retrieval
    * `healthz` endpoint: Checks BOS health status endpoint
    * Options CRUD: Tests creation, retrieval, update, and deletion of BOS global options
    * Session templates CRUD
    * Retrieves image IDs from CSM product catalog for multiple architectures (`x86_64`, `aarch64`)
    * Creates session templates with architecture-specific configurations
    * Validates template structure and content
    * Retrieves templates by name and lists all templates
    * Updates template parameters (image IDs, CFS configurations)
    * Deletes templates and verifies removal
    * Sessions CRUD
        * Creates BOS sessions with different operation types (boot, reboot, shutdown)
        * Tests both staged and non-staged session creation
        * Retrieves session status and details
        * Lists all sessions
        * Deletes sessions and validates cleanup
    * Components operations: Tests BOS component listing and status retrieval
* CLI tests (only run when `--include-cli` is specified)
    * Validates all API operations using the Cray CLI (`cray bos` commands)
    * Tests session template operations via CLI
    * Verifies session operations via CLI
    * Ensures CLI output format consistency (JSON)
* Tenant tests (only run when `--include-tenant` is specified)
    * Tests BOS operations with both real and fake tenant contexts
    * Validates multi-tenancy isolation
    * Verifies tenant-scoped session templates and sessions
    * Tests operations with non-existent tenants (using fake tenant name)

The following information is collected on failure:

* Kubernetes cluster state
* Pod descriptions for all BOS pods
* Pod logs from failed components

### CFS tests

Validates Configuration Framework Service (CFS) service health, API operations, and configuration management using the following tests:

* Pod status verification (always run)
    * Verifies at least 2 CFS pods are running (API and operator)
    * Identifies and validates CFS API pod
    * Identifies and validates CFS operator pod
    * Checks that all CFS service pods are in "Running" state
    * Allows "Succeeded" status with warning (for completed jobs)
* API tests (always run)
    * `healthz` endpoint: Validates CFS service health status
    * Version endpoints: Tests multiple version endpoints
    * Options endpoint: Tests CFS global options retrieval for v2 and v3
    * Components endpoint: Lists and retrieves CFS components for v2 and v3
    * Sessions endpoint: Lists and retrieves CFS sessions for v2 and v3
    * CFS configurations CRUD:
        * Creates CFS configurations with single and multiple layers
        * Retrieves configurations by name
        * Lists all configurations (with pagination support in v3)
        * Updates configuration layers and parameters
        * Deletes configurations and verifies removal
        * Tests configurations with VCS repository references
        * Validates configuration layer commit, branch, and playbook settings
    * CFS sources CRUD (v3 only):
        * Creates CFS sources (Git repository references)
        * Retrieves source details
        * Updates source credentials and URLs
        * Deletes sources and validates cleanup
    * Product catalog integration: Retrieves and validates CSM configuration from product catalog
* CLI tests (only run when `--include-cli` is specified)
    * Validates CFS configuration operations via Cray CLI
    * Tests CFS source operations via CLI
    * Ensures CLI and API consistency
    * Tests both v2 and v3 API versions where applicable
* Tenant tests (only run when `--include-tenant` is specified)
    * Tests tenant-scoped CFS configurations (v3 only)
    * Validates multi-tenant isolation:
        * Verifies tenant A cannot see or modify tenant B's configurations
        * Tests admin ability to create configurations for specific tenants
        * Tests configurations with same name but different tenant ownership
    * Uses both real tenants and fake tenant for validation
    * Verifies tenant-specific configuration CRUD operations

The following information is collected on failure:

* Kubernetes cluster state
* Pod descriptions for CFS API and operator pods
* CFS service logs

### Conman tests

Validates console services infrastructure and pod health by performing the following tests:

* Persistent Volume Claims (PVC) verification
    * Validates `cray-console-operator-data-claim` PVC status (should be "Bound")
    * Validates `cray-console-node-agg-data-claim` PVC status (should be "Bound")
* Console data pod verification
    * Verifies exactly 1 main `cray-console-data-` pod (Running)
    * Verifies 1-3 `cray-console-data-postgres-#` pods (Running)
    * Allows 0 or more `cray-console-data-wait-for-postgres-#` pods (Succeeded)
    * Total: At least 4 `console-data` pods expected
* Console node pod verification
    * Verifies at least 2 `cray-console-node-#` pods (Running)
    * These pods aggregate console connections from compute nodes
* Console operator pod verification
    * Verifies exactly 1 `cray-console-operator` pod (Running)
    * This pod manages console service operations

The following information is collected on failure:

* Kubernetes cluster state
* Pod descriptions for all console-related pods
* PVC descriptions

**Note**: These tests do not perform API or CLI operations; they focus on Kubernetes resource health and availability.

### IMS tests

Validates Image Management Service (IMS) health, image management operations, and recipe handling by performing the following tests:

* Pod status verification (always run)
    * Verifies exactly 1 IMS service pod is running
    * Checks pod status is "Running"
* Persistent Volume Claims (PVC) verification (always run)
    * Validates IMS-related PVC status (should be "Bound")
* Recipe pod verification (always run)
    * Checks for `cray-init-recipe` pods
    * Verifies default recipe pods have "Succeeded" status
    * Validates recipe environment variables (if `IMS_RECIPE_NAME` and `IMS_RECIPE_DISTRO` are set)
* API tests (always run)
    * Images CRUD
        * Creates IMS images with various parameters
        * Links images to S3 artifacts
        * Retrieves image details by ID
        * Lists all images
        * Updates image metadata (name, description)
        * Deletes images and verifies S3 artifact cleanup
    * Recipes CRUD
        * Creates IMS recipes with `recipe_type` and `linux_distribution`
        * Retrieves recipe details
        * Lists all recipes with filtering
        * Updates recipe parameters
        * Deletes recipes and validates removal
    * Public keys CRUD
        * Creates SSH public keys for image customization
        * Retrieves public key details
        * Lists all public keys
        * Updates public key metadata
        * Deletes public keys
* CLI tests (only run when `--include-cli` is specified)
    * Validates all image operations via Cray CLI (`cray ims images` commands)
    * Tests recipe operations via CLI
    * Tests public key operations via CLI
    * Ensures CLI output format consistency

The following environment variables control the behavior of the IMS tests (they are all optional):

| Environment variable | Description | Default if unset |
| ----- | ----- | ---- |
| `IMS_RECIPE_NAME` | Specifies the IMS recipe name to verify | No recipe verification is performed if this is unset |
| `IMS_RECIPE_DISTRO` | Specifies the distribution of the IMS recipe being validated |  `sles15` |

The following information is collected on failure:

* Kubernetes cluster state
* Pod descriptions for IMS service and recipe pods
* PVC descriptions

### iPXE/TFTP tests

**Aliases**: The service can be tested using either `ipxe` or `tftp` as the service name.

Validates iPXE binary build process and TFTP file transfer functionality by performing the following tests:

* iPXE pod verification
    * Verifies iPXE build pods for supported architectures:
        * `x86_64` (`amd64`)
        * `aarch64` (`arm64`)
    * Checks that iPXE containers are ready
    * Validates pod status is "Running"
* TFTP pod verification
    * Verifies at least 1 TFTP service pod is running
    * Checks pod status is "Running"
* Persistent Volume Claims (PVC) verification
    * Validates `cray-tftp-shared-pvc` PVC status (should be "Bound")
* iPXE binary ConfigMap validation
    * Retrieves iPXE binary names from Kubernetes ConfigMap
    * Validates ConfigMap structure and content
* TFTP file transfer test (only run on worker NCNs)
    * Tests file transfer from TFTP services:
        * `cray-tftp` ([NMN](../glossary.md#node-management-network-nmn) network)
        * `cray-tftp-hmn` ([HMN](../glossary.md#hardware-management-network-hmn) network)
    * For each architecture:
        * Retrieves iPXE binary file via TFTP
        * Validates successful file transfer
        * Verifies file content integrity
    * **Note**: This test is automatically skipped on master NCNs

The following information is collected on failure:

* Kubernetes cluster state
* Pod descriptions for iPXE and TFTP pods
* PVC descriptions

### VCS tests

**Aliases**: The service can be tested using either `vcs` or `gitea` as the service name.

Validates the Version Control Service (VCS) health and Gitea repository operations by performing the following tests:

* Pod status verification
    * Verifies at least 2 VCS pods are present
    * Expected pods:
        * Exactly 1 main `gitea-vcs` pod (Running)
        * 1 or more `gitea-vcs-postgres-#` pods (Running)
        * 0 or more `gitea-vcs-wait-for-postgres-#` pods (Succeeded)
        * 0 or more `logical-backup-gitea-vcs-postgres-` pods (Succeeded, Running, or Pending)
* Persistent Volume Claims (PVC) verification
    * Validates `gitea-vcs-data-claim` PVC status (should be "Bound")
    * For each `postgres` pod, validates corresponding `pgdata-gitea-vcs-postgres-#` PVC
* Backup pod validation
    * Identifies the most recent backup pod
    * Verifies backup pod status is acceptable (Succeeded, Running, or Pending)
    * Warns if backup pod has unexpected status
* VCS repository operations
    * Repository creation
        * Creates a new Git repository in VCS using API
        * Validates repository creation response
    * Repository cloning
        * Clones the repository using Git client
        * Tests VCS authentication (username/password from secrets)
    * File operations
        * Creates and commits new files to repository
        * Pushes changes to VCS
    * Repository listing
        * Lists all repositories via VCS API
        * Verifies created repository appears in list
    * Repository deletion
        * Deletes test repository via API
        * Validates repository removal

VCS authentication is required for the tests. The tests retrieve the VCS credentials from the `vcs-user-credentials` Kubernetes secret.
The credentials are used for Git operations and API calls.

The following information is collected on failure:

* Kubernetes cluster state
* Pod descriptions for all VCS pods
* PVC descriptions
* VCS service logs

## Usage examples

### Basic test execution

#### Run tests for all services in quiet mode

> This excludes CLI and multi-tenancy tests.

```bash
/usr/local/bin/cmsdev test -q all
```

#### Run tests for a specific single service in verbose mode

> This excludes CLI and multi-tenancy tests.

```bash
/usr/local/bin/cmsdev test -v bos
```

#### Run tests for multiple specific services with retries on failure

> This excludes CLI and multi-tenancy tests.

```bash
/usr/local/bin/cmsdev test bos cfs ims -r
```

### Advanced test scenarios

#### Run BOS tests including CLI tests

```bash
/usr/local/bin/cmsdev test bos --include-cli
```

#### Run all service tests including both CLI and multi-tenancy tests, with retry on failure

```bash
/usr/local/bin/cmsdev test all --include-cli --include-tenant --retry
```

#### Run tests in quiet mode without logging to a file

```bash
/usr/local/bin/cmsdev test tftp --no-log -q
```

#### Run tests with custom log directory

```bash
/usr/local/bin/cmsdev test all --log-dir /tmp/my-cmsdev-logs
```

#### Run tests in verbose mode with retry and keep temporary files

```bash
/usr/local/bin/cmsdev test vcs --verbose --retry --no-cleanup
```

## Version information

(`ncn-mw#`) The following command displays the version of the `cmsdev` test tool.

```bash
/usr/local/bin/cmsdev version
```

Example output:

```text
cmsdev version 1.34.0
```

## Logging

> NOTE: `cmsdev` logging changed in `cmsdev` version 1.34.0. See [Log changes](#log-changes) for details.

Each `cmsdev` test run creates a timestamped subdirectory in `/opt/cray/tests/install/logs/cmsdev/`,
with a naming format of `YYMMDD_HHMMSS_microseconds_PID`. Inside of that directory, `cmsdev` logs to
a file named `cmsdev.log`. For example: `/opt/cray/tests/install/logs/cmsdev/20251012_050305_414367785_990773/cmsdev.log`.
In the case of a failure, a file named `artifacts.tgz` will also be saved to that directory.
It contains additional information that can help to debug the failures, if necessary.
For example, logs from relevant Kubernetes pods.

### Log changes

The logging behavior of `cmsdev` depends on the version of `cmsdev` being run.
See the [Version information](#version-information) section above for details on how to find the version.

| *CSM versions*     | `cmsdev` *versions* | *Logging*                                                         |
| ------------------ | ------------------- | ----------------------------------------------------------------- |
| >= 1.7.0           | >= 1.34.0           | Timestamped log directories, as described above. Previous log file converted using [Log file migration](#log-file-migration) |
| >= 1.4.0, <= 1.7.0 | >= 1.12.0, < 1.34.0 | Single log file: `/opt/cray/tests/install/logs/cmsdev/cmsdev.log` |
| < 1.4.0            | < 1.12.0            | Single log file: `/opt/cray/tests/cmsdev.log`                     |

#### Log file migration

The upgrade to `cmsdev` 1.34.0 or later automatically migrates the single log file into the new format,
if needed. It performs the following procedure if it finds the legacy single log file.

1. Scans the legacy `cmsdev.log` file and identifies all unique [run tags](#run-tags)
1. For each run tag:
    1. Identifies the earliest timestamp in `cmsdev.log` for that tag
    1. Creates a subdirectory using the timestamp (without PID, because it is unknown for legacy runs)
    1. Extracts log entries for that run tag and writes the filtered results to `cmsdev.log` in the new subdirectory
    1. If an artifact file exists for this run tag, moves it into the subdirectory and renames it to `artifacts.tgz`
1. Remove the original `cmsdev.log` file located at `/opt/cray/tests/install/logs/cmsdev/`

This ensures backward compatibility and preserves historical test data in the new organized structure.

#### Run tags

Prior to `cmsdev` 1.34.0, every execution of `cmsdev` had an associated "run tag", which was just a short, random
alphanumeric string. Every line in the log file had this run tag included. This allowed users to extract the logs
for an individual test run from the monolithic log file. Run tags are used in the [Log file migration](#log-file-migration)
procedure to automatically convert the monolithic log file into the new per-execution format.

With the move to separate log files per execution, this tag no longer serves a purpose, and is no longer generated or logged.

## Additional resources

* [Software Management Services Health Check - Known Issues](known_issues/sms_health_check.md) - Detailed troubleshooting guide
* [Configure the Cray CLI](../operations/configure_cray_cli.md)
* [Validate CSM health](../operations/validate_csm_health.md)
