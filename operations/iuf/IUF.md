# Install and Upgrade Framework

## Overview

The Install and Upgrade Framework (IUF) provides a CLI and API which automates operations required to install, upgrade
and deploy non-CSM product content onto an HPE Cray EX system. These products are documented in the
_HPE Cray EX System Software Stack Installation and Upgrade Guide for CSM (S-8052)_.
Each product distribution includes an `iuf-product-manifest.yaml` file which IUF uses to determine what operations are needed to
install, upgrade, and deploy the product. IUF operates on all of the product distribution files found in a single
media directory.

IUF groups the install, upgrade, and deploy operations into stages. The administrator can execute some or all of the stages
with one or multiple products in a single activity. `iuf` arguments for all stages can be specified prior to execution
in order to automate the operations and minimize user interaction.

In addition, IUF provides metric and annotation capabilities which can be used to view status and record historical
information associated with an install or upgrade.

IUF utilizes [Argo workflows](../argo/Using_Argo_Workflows.md) to execute and parallelize IUF operations and to provide
visibility into the status of the operations through the [Argo UI](../argo/Using_the_Argo_UI.md). The `iuf` CLI invokes
Argo workflows based on the subcommand specified. The Argo workflows are not controlled by `iuf` once they have been created, but
`iuf` does display status to the administrator as the Argo workflows execute.

**`NOTE`** Before starting, [Validate CSM Health](../validate_csm_health.md). Ensure sufficient memory, CPU and disk usage
is available (the following example commands are for reference only; change them accordingly based on number of products used by IUF).

(`ncn-m001#`) List processors and disk usage using built-in commands `nproc` and `df`.

```bash
nproc --all
df -h /
```

Example output:

```text
# nproc --all
40
# df -h /
Filesystem      Size    Used     Avail   Use%  Mounted on
LiveOS_rootfs   <N>G    <M>G     <N-M>G  45%   /
```

The following IUF topics are discussed in the sections below.

- [Limitations](#limitations)
- [Initial install and upgrade workflows](#initial-install-and-upgrade-workflows)
- [Activities](#activities)
- [Argo workflows](#argo-workflows)
- [Stages and hooks](#stages-and-hooks)
- [`iuf` CLI](#iuf-cli)
    - [Global arguments](#global-arguments)
    - [Input file](#input-file)
    - [Subcommands](#subcommands)
        - [run](#run)
        - [abort](#abort)
        - [resume](#resume)
        - [restart](#restart)
        - [activity](#activity)
        - [list-activities](#list-activities)
        - [list-stages](#list-stages)
        - [workflow](#workflow)
- [Output and log files](#output-and-log-files)
    - [`iuf` output](#iuf-output)
    - [Log files](#log-files)
- [Site and recipe variables](#site-and-recipe-variables)
- [`sat bootprep` configuration files](#sat-bootprep-configuration-files)
    - [ARM images](#arm-images)
- [Recovering from failures](#recovering-from-failures)
    - [Addressing the issue without changing products](#addressing-the-issue-without-changing-products)
    - [Addressing the issue by removing a product](#addressing-the-issue-by-removing-a-product)
    - [Addressing the issue by adding a new version of a product](#addressing-the-issue-by-adding-a-new-version-of-a-product)
- [Troubleshooting](#troubleshooting)
- [Install and Upgrade Observability Framework](#install-and-upgrade-observability-framework)

## Limitations

- `iuf` must be executed from `ncn-m001`.
- While IUF enables non-interactive deployment of product software, it does not automatically configure the software beyond merging new VCS release branch content to customer working branches. For example, if a product requires
  manual configuration, the administrator must stop IUF execution after the `update-vcs-config` stage, perform the manual configuration steps, and then resume with the next IUF stage (`update-cfs-config`).
- IUF leverages `sat bootprep` for CFS configuration and image creation. It is intended to be used with the configuration files provided in the HPC CSM Software Recipe and requires the administrator to verify and customize
  those configurations to their specific needs.
- IUF will fail and provide feedback to the administrator in the event of an error, but it cannot automatically resolve issues.
- IUF does not handle many aspects of installs and upgrades of CSM itself and cannot be used until a base level of CSM functionality is present.
- The `management-nodes-rollout` stage does not automatically upgrade `ncn-m001`. This node must be upgraded using non-IUF methods described in the IUF documentation.
- If the `iuf run` subcommand ends unexpectedly before the Argo workflow it created completes, there is no CLI option to reconnect to the Argo workflow and continue displaying status. It is recommended the administrator
  monitors progress via the Argo workflow UI and/or IUF log files in this scenario.
- It is currently not possible to add or remove product distribution files to an in progress IUF session without first re-executing the `process-media` stage and then re-executing any other stages required for that product. See
  [Recovering from failures](#recovering-from-failures) for details.

## Initial install and upgrade workflows

There are two separate workflows that utilize IUF when installing or upgrading non-CSM product content on a Cray EX system.

1. The [Install or upgrade additional products with IUF](workflows/install_or_upgrade_additional_products_with_iuf.md)
   workflow is used in either of the following scenarios:
   - An initial install of the system is being performed, including CSM and non-CSM products
   - An initial install or upgrade is being performed **with non-CSM products only**. In this
     scenario, the first step ("Perform an install of CSM") is skipped and all other steps are
     performed.
1. The [Upgrade CSM and additional products with IUF](workflows/upgrade_csm_and_additional_products_with_iuf.md)
   workflow is used when an upgrade is being performed **with CSM and non-CSM products**.

## Activities

An activity is a user-specified unique string identifier used to group and track IUF actions, typically those needed to complete an install or upgrade using a set of product distribution files. An example of an activity
identifier is `admin-230127`. `iuf` subcommands accept an activity as input, and the corresponding IUF output and log files are organized by that activity. The activity can be specified via an `iuf` argument or an environment
variable; for more details, see `iuf -h`. The activity will be created automatically upon the first invocation of `iuf` with that given activity string.

IUF provides operational metrics associated with an activity (e.g. the time duration of each stage executed). Users can also create annotations for an activity, e.g. to note that an operation has been paused, to note that time was
spent debugging an issue, etc. `iuf` subcommands can be invoked to display a summary of actions, annotations, and metrics associated with an activity.

IUF activities can be displayed by using the [`iuf list-activities`](#list-activities) subcommand.

The following example shows history and status information associated with the `admin-230127` activity:

(`ncn-m001#`) List operations for an IUF activity.

```bash
iuf -a admin-230127 activity
```

Example output:

```text
+-----------------------------------------------------------------------------------------------------------------------------------------------+
| Activity:  admin.05-17                                                                                                                        |
+---------------------------------+-------------+------------------------------------------------+-----------+----------+-----------------------+
| Start                           | Category    | Command / Argo Workflow                        | Status    | Duration | Comment               |
+---------------------------------+-------------+------------------------------------------------+-----------+----------+-----------------------+
| session: admin.05-17-4x1nn      |             | command: ./iuf -i input.yaml run -b \          |           |          |                       |
|                                 |             | process-media                                  |           |          |                       |
| 2023-05-17t20:52:41             | in_progress | admin.05-17-4x1nn-process-media-d2r6f          | Succeeded | 0:01:27  | Run process-media     |
| -------------------             | -----       | -----                                          | -----     | -----    | -----                 |
| session: admin.05-17-kshk3      |             | command: ./iuf -i input.yaml run -b \          |           |          |                       |
|                                 |             | process-media                                  |           |          |                       |
| 2023-05-17t20:54:08             | in_progress | admin.05-17-kshk3-pre-install-check-bd6sz      | Succeeded | 0:01:05  | Run pre-install-check |
| 2023-05-17t20:55:13             | in_progress | admin.05-17-kshk3-deliver-product-8c6bk        | Failed    | 0:03:40  | Run deliver-product   |
| 2023-05-17t20:58:53             | debug       | None                                           | None      | 0:01:19  | None                  |
| 2023-05-17t21:00:12             | None        | admin.05-17-kshk3-deliver-product-8c6bk        | resume    | 0:00:01  | resuming install      |
| 2023-05-17t21:00:13             | in_progress | admin.05-17-kshk3-deliver-product-8c6bk        | Unknown   | 0:00:00  | Run deliver-product   |
+---------------------------------+-------------+------------------------------------------------+-----------+----------+-----------------------+
Summary:
  Start time: 2023-05-17t20:52:41
  End time:   2023-05-17t21:00:13

  Time spent in sessions:
    admin.05-17-4x1nn: 0:01:27
    admin.05-17-kshk3: 0:06:05

  Stage Durations:
        process-media: 0:01:18
    pre-install-check: 0:00:52
      deliver-product: 0:03:39

  Time spent in states:
  in_progress: 0:06:12
        debug: 0:01:19

  Total time: 0:07:32
```

## Argo workflows

[Argo workflows](../argo/Using_Argo_Workflows.md) orchestrate jobs on Kubernetes. IUF utilizes Argo workflows to execute and manage product install, upgrade, and deploy operations. For example, if an administrator invokes IUF to
execute the `process-media` and `pre-install-check` stages for a product, two Argo workflows will be created: one associated with the `process-media` stage and one associated with the `pre-install-check` stage. Not all operations
in an activity are associated with an Argo workflow, however. For example, annotation events and time spent waiting for the administrator to invoke the next operation do not result in the execution of IUF install and upgrade
operations, and thus are not associated with an Argo workflow.

Each Argo workflow created by IUF has a unique string identifier associated with it. An example of an IUF Argo workflow identifier is `admin-230127-zb268-process-media-v5dsw`. Argo workflow identifiers are recorded in IUF log
files and are displayed by `iuf activity` as shown in the [Activities](#activities) section.

Most Argo workflows created by IUF create multiple independent Argo steps to execute the workflow. `iuf` displays both Argo workflow and Argo step information on standard output as an IUF session executes. Argo
workflow identifiers are prefixed with `ARGO WORKFLOW:` text and Argo steps for that workflow are displayed in an indented format underneath it. The [Output and log files](#output-and-log-files) section provides
an example of `iuf` output.

## Stages and hooks

Install and upgrade operations performed by IUF are organized into stages. The administrator can execute one or more stages in a single invocation of `iuf run`. A single stage can execute with the content of one or more products.
IUF operates on all products found in a single media directory specified by the administrator. When possible, IUF will parallelize execution for products within a stage, e.g. the `process-media` stage will extract content for all
products found in the media directory at the same time.

A stage will not complete until it has completed execution for all products specified in the activity. If an error is encountered while executing a stage for a given product, IUF will allow other products to complete the execution
of the stage and will then stop execution. It will create an entry within the activity with the corresponding Argo workflow, set its `Status` to `Failed`, and report the stage result as `Error`.

IUF provides a hook capability for all stages. This allows a product to execute additional scripts before and/or after a given stage executes. Hooks allow products to perform special actions that IUF does not perform itself at an
appropriate time in an initial install or upgrade workflow. These hook scripts are executed automatically by IUF; no input from the administrator is required. All product scripts registered via a pre-stage hooks must complete before
the stage executes, and no product post-stage hook will execute until the stage itself has completed.

The administrator may execute one, multiple, or all stages in a single `iuf run` invocation depending on the task to be accomplished. If multiple stages are specified, they must be executed in the order listed below. The `iuf run`
subcommand provides arguments to specify which stages are to be run and if any stages should be skipped. The following table lists all of the stages in the order they are executed when performing an initial install or upgrade of
one or more products. This information is also provided by the `iuf list-stages` subcommand.

**`NOTE`** Click the links in the `Stage` column for additional details about the stages.

| Stage                                                              | Description                                                                              |
|--------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| [process-media](stages/process_media.md)                           | Inventory and extract products in the media directory for use in subsequent stages       |
| [pre-install-check](stages/pre_install_check.md)                   | Perform pre-install readiness checks                                                     |
| [deliver-product](stages/deliver_product.md)                       | Upload product content onto the system                                                   |
| [update-vcs-config](stages/update_vcs_config.md)                   | Merge working branches and perform automated VCS configuration                           |
| [update-cfs-config](stages/update_cfs_config.md)                   | Update CFS configuration (executes `sat bootprep`)                                       |
| [prepare-images](stages/prepare_images.md)                         | Build and configure management node and/or managed node images (executes `sat bootprep`) |
| [management-nodes-rollout](stages/management_nodes_rollout.md)     | Rolling reboot or live update of management nodes                                        |
| [deploy-product](stages/deploy_product.md)                         | Deploy services to system                                                                |
| [post-install-service-check](stages/post_install_service_check.md) | Perform post-install checks of processed services                                        |
| [managed-nodes-rollout](stages/managed_nodes_rollout.md)           | Rolling reboot or live update of managed nodes                                           |
| [post-install-check](stages/post_install_check.md)                 | Perform post-install checks                                                              |

The `process-media` stage must be run at least once for a given activity before any of the other stages can be run. This is required because `process-media` associates the product content being installed or upgraded with an
activity identifier and that information is used for all other stages.

## `iuf` CLI

The `iuf` command-line interface is used to invoke all IUF operations. The `iuf` command provides the following subcommands.

| Subcommand        | Description                                             |
|-------------------|---------------------------------------------------------|
| `run`             | Initiates execution of IUF operations                   |
| `abort`           | Abort an IUF session                                    |
| `resume`          | Resume a previously aborted or failed IUF session       |
| `restart`         | Restart the most recently aborted or failed IUF session |
| `activity`        | Display IUF activity details, annotate IUF activity     |
| `list-activities` | List all activities present on the system               |
| `list-stages`     | Display stages and status for a given IUF activity      |
| `workflow`        | List workflows or information for a particular workflow |

### Global arguments

Global arguments may be specified when invoking `iuf`. They must be specified before any `iuf` subcommand and its subcommand-specific arguments are specified.

The following shows the global arguments available.

```text
usage: iuf [-h] [-i INPUT_FILE] [-w] [-a ACTIVITY] [-c CONCURRENCY] [-b BASE_DIR] [-s STATE_DIR] [-m MEDIA_DIR]
           [--log-dir LOG_DIR] [-l {CRITICAL,ERROR,WARNING,INFO,DEBUG,TRACE}] [-v]
           {run,activity,list-stages|ls,resume,restart,abort,list-activities|la,workflow} ...

The CSM Install and Upgrade Framework (IUF) CLI.

options:
  -h, --help            show this help message and exit
  -i INPUT_FILE, --input-file INPUT_FILE
                        YAML input file used to provide arguments to `iuf`. Command line arguments will override
                        entries in the input file. Can also be set via the IUF_INPUT_FILE environment variable.
  -w, --write-input-file
                        Create an input file for iuf populated with the command line options specified and exit.
                        This input file can be specified with the `-i` option on subsequent runs.  Using an input
                        file simplifies iuf commands with many options. Note that the general iuf command does not
                        change; so for a long iuf command, add this flag to the command to write the input file.
  -a ACTIVITY, --activity ACTIVITY
                        Activity name. Must be a unique identifier. Activity names must contain only lowercase letters (a-z),
                        numbers (0-9), periods (.), and dashes (-). Can also be set via the IUF_ACTIVITY environment
                        variable.
  -c CONCURRENCY, --concurrency CONCURRENCY
                        During stage processing Argo runs workflow steps in parallel. By default up to 10 steps will be
                        executed simultaneously. Use `--concurrency N` to decrease the limit to N. Increasing this limit
                        is not recommended.
  -b BASE_DIR, --base-dir BASE_DIR
                        Base directory for state and log file directories. Defaults to ${RBD_BASE_DIR}/iuf/[activity],
                        where ${RBD_BASE_DIR} is /etc/cray/upgrade/csm.
  -s STATE_DIR, --state-dir STATE_DIR
                        A directory used to store the current state of stages, used by `iuf` but primarily not of
                        interest to users. Defaults to [base-dir]/state.
  -m MEDIA_DIR, --media-dir MEDIA_DIR
                        Location of installation media to be used. Defaults to ${RBD_BASE_DIR}/[activity], where
                        ${RBD_BASE_DIR} is /etc/cray/upgrade/csm. `iuf` cannot access installation media outside of
                        ${RBD_BASE_DIR}, however input files provided by other `iuf` arguments can exist outside of
                        ${RBD_BASE_DIR}.
  --log-dir LOG_DIR     Location used to store log files. Defaults to [base-dir]/log.
  -l {CRITICAL,ERROR,WARNING,INFO,DEBUG,TRACE}, --level {CRITICAL,ERROR,WARNING,INFO,DEBUG,TRACE}
                        Set the log message level that determines what is displayed on `iuf` standard output. Messages
                        of this level or higher are displayed.
  -v, --verbose         generate more verbose messages

subcommands:
  {run,activity,list-stages|ls,resume,restart,abort,list-activities|la,workflow}
```

### Input file

As described in the [Output and log files](#output-and-log-files) section, the `-i INPUT_FILE` argument can be used to read `iuf` arguments and values from a YAML input file. Both global and subcommand-specific arguments can be
specified in the input file. If an input file is used in addition to `iuf` arguments, the `iuf` arguments take precedence. The name of an entries in the input file corresponds to the long form name of the `iuf` argument with
hyphens replaced by underscores.

The following is an example of a partial `iuf` input file. The first section displays global arguments and values and the following sections display subcommand arguments and values.

```yaml
global:
    activity: admin-230127
    concurrency: null
    base_dir: null
    state_dir: /etc/cray/upgrade/csm/iuf/admin-230127/state
    media_dir: /etc/cray/upgrade/csm/admin-230127
    media_host: ncn-m001
    log_dir: /etc/cray/upgrade/csm/iuf/admin-230127/log
    dryrun: false
    level: INFO
    verbose: false
abort:
    comment: null
    force: false
activity:
    time: null
    create: false
[...]
```

(`ncn-m001#`) An input file populated with default values can be created by using `iuf -w`:

```bash
iuf -a admin-230127 -i /tmp/default-input-file -w
```

Example output:

```text
Successfully wrote /tmp/default-input-file
```

### Subcommands

#### `run`

The `run` subcommand is used to execute one or more IUF stages. The `-b`, `-e`, `-r` and `-s` arguments can be specified to limit the stages executed. If none of those arguments are specified, `iuf run` will execute all stages
in order. If an activity identifier is not provided via `-a`, a new activity will be created automatically.

See the [Output and log files](#output-and-log-files) section for details on information printed on standard output as `iuf run` executes.

Using Ctrl-C with `iuf run` does not immediately abort the IUF session. The following options will be printed and the administrator can select the desired action:

```text
Would you like to abort this run?
    Enter Y, y, or yes to abort after the current stage completes.
    Enter F, f, or force to abort the current stage immediately.
    Enter D, d, or disconnect to exit the IUF CLI.  The install will continue in the background, however no logs will be collected.

    Enter <return> to resume monitoring.
    NOTE: The IUF CLI will remain connected until Argo completes the abort process. Use the disconnect option to exit the IUF CLI immediately.
    NOTE: All logging will be suspended when disconnected.
```

See the [resume](#resume) and [restart](#restart) sections for details on how to continue after aborting an IUF session.

The following arguments may be specified when invoking `iuf run`:

```text
usage: iuf run [-h] [-b BEGIN_STAGE] [-e END_STAGE] [-r RUN_STAGES [RUN_STAGES ...]] [-s SKIP_STAGES [SKIP_STAGES ...]] [-f]
               [-bc BOOTPREP_CONFIG_MANAGED] [-bm BOOTPREP_CONFIG_MANAGEMENT] [-bpcd BOOTPREP_CONFIG_DIR] [-rv RECIPE_VARS]
               [-sv SITE_VARS] [-mrs {reboot,stage}] [-cmrp CONCURRENT_MANAGEMENT_ROLLOUT_PERCENTAGE]
               [--limit-managed-rollout LIMIT_MANAGED_ROLLOUT [LIMIT_MANAGED_ROLLOUT ...]]
               [--limit-management-rollout LIMIT_MANAGEMENT_ROLLOUT [LIMIT_MANAGEMENT_ROLLOUT ...]]
               [-mrp MASK_RECIPE_PRODS [MASK_RECIPE_PRODS ...]]

Run IUF stages to execute install, upgrade and/or deploy operations for a given activity.

options:
  -h, --help            show this help message and exit
  -b BEGIN_STAGE, --begin-stage BEGIN_STAGE
                        The first stage to execute. Defaults to process-media
  -e END_STAGE, --end-stage END_STAGE
                        The last stage to execute. Defaults to post-install-check
  -r RUN_STAGES [RUN_STAGES ...], --run-stages RUN_STAGES [RUN_STAGES ...]
                        Run the specified stages only. This argument is not compatible with `-b`, `-e`, or `-s`.
  -s SKIP_STAGES [SKIP_STAGES ...], --skip-stages SKIP_STAGES [SKIP_STAGES ...]
                        Skip the execution of the specified stages.
  -f, --force           Force re-execution of stage operations.
  -bc BOOTPREP_CONFIG_MANAGED, --bootprep-config-managed BOOTPREP_CONFIG_MANAGED
                        `sat bootprep` config file for managed (compute and
                        application) nodes.  Note the path is relative to $PWD, unless an
                        absolute path is specified.  Omit this argument to skip building the
                        managed images (and ensure the `--bootprep-config-dir` option is not
                        specified).
  -bm BOOTPREP_CONFIG_MANAGEMENT, --bootprep-config-management BOOTPREP_CONFIG_MANAGEMENT
                        `sat bootprep` config file for management NCNs.  Note the
                        path is relative to $PWD, unless an absolute path is specified. Omit
                        this argument to skip building the management images (and ensure the
                        `--bootprep-config-dir` option is not specified).
  -bpcd BOOTPREP_CONFIG_DIR, --bootprep-config-dir BOOTPREP_CONFIG_DIR
                        Directory containing HPE `product_vars.yaml` and `sat bootprep` configuration files.
                        The expected content is:
                            $(BOOTPREP_CONFIG_DIR)/product_vars.yaml
                            $(BOOTPREP_CONFIG_DIR)/bootprep/compute-and-uan-bootprep.yaml
                            $(BOOTPREP_CONFIG_DIR)/bootprep/management-bootprep.yaml
                        Note the path is relative to $PWD, unless an absolute path is specified.
  -rv RECIPE_VARS, --recipe-vars RECIPE_VARS
                        Path to a recipe variables YAML file. HPE provides the `product_vars.yaml` recipe
                        variables file with each release. Note the path is relative to $PWD, unless
                        an absolute path is specified.
  -sv SITE_VARS, --site-vars SITE_VARS
                        Path to a site variables YAML file. This file allows the user to override values defined in
                        the recipe variables YAML file. Defaults to ${RBD_BASE_DIR}/${IUF_ACTIVITY}/site_vars.yaml.
                        Note the path is relative to $PWD, unless an absolute path is specified.
  -mrs {reboot,stage}, --managed-rollout-strategy {reboot,stage}
                        Method to update the managed nodes. Accepted values are 'reboot' (reboot nodes _now_) or
                        'stage' (set up nodes to reboot into new image after next WLM job). Defaults to 'stage'.
  -cmrp CONCURRENT_MANAGEMENT_ROLLOUT_PERCENTAGE, --concurrent-management-rollout-percentage CONCURRENT_MANAGEMENT_ROLLOUT_PERCENTAGE
                        Limit the number of management nodes that roll out
                        concurrently based on the percentage specified. Must be an integer
                        between 1-100. Defaults to 20 (percent).
  --limit-managed-rollout LIMIT_MANAGED_ROLLOUT [LIMIT_MANAGED_ROLLOUT ...]
                        Override list used to target specific nodes only when rolling out managed nodes. Arguments
                        should be xnames or HSM node groups. Defaults to the Compute role.
  --limit-management-rollout LIMIT_MANAGEMENT_ROLLOUT [LIMIT_MANAGEMENT_ROLLOUT ...]
                        List used to target specific hostnames or HSM management role_subrole only when rolling
                        out management nodes. Hostname arguments can only belong to a single node type. For example,
                        both master and worker hostnames can not be provided at the same time. Defaults to an empty list
                        which means no nodes will be rolled out.
  -mrp MASK_RECIPE_PRODS [MASK_RECIPE_PRODS ...], --mask-recipe-prods MASK_RECIPE_PRODS [MASK_RECIPE_PRODS ...]
                        If `--recipe-vars` is specified, mask the versions found within the recipe variables YAML
                        file for the specified products, such that the largest version of the package already installed on
                        the system (found in the product catalog) is used instead of the version supplied in the HPC CSM
                        Software Recipe. Note that the versions found via `--site-vars` (or the versions being installed)
                        will override it as well.
```

These [examples](examples/iuf_run.md) highlight common use cases of `iuf run`.

#### `abort`

The `abort` subcommand is specified by the administrator to end an IUF session. The IUF session will be terminated at the end of the current stage unless `-f` is specified, which causes the session to terminate immediately. Any
terminated Argo Workflows will have a `Status` of `Failed` when displayed via `iuf activity`.

The following arguments may be specified when invoking `iuf abort`:

```text
usage: iuf abort [-h] [-f] [comment ...]

Abort an IUF session for a given activity after the current stage completes.

positional arguments:
  comment      Add a comment to the activity log

options:
  -h, --help   show this help message and exit
  -f, --force  Force the abort immediately.
```

These [examples](examples/iuf_abort.md) highlight common use cases of `iuf abort`.

#### `resume`

The `resume` subcommand is specified by the administrator to resume a previously aborted or failed IUF session for a given activity. The resumed IUF session continues execution with any Argo steps that previously failed or were
not executed during the most recent stage.

The following arguments may be specified when invoking `iuf resume`:

```text
usage: iuf resume [-h] [comment ...]

Resume a previously aborted or failed IUF session for a given activity.

positional arguments:
  comment     Add a comment to the activity log

options:
  -h, --help  show this help message and exit
```

These [examples](examples/iuf_resume.md) highlight common use cases of `iuf resume`.

#### `restart`

Run the `restart` subcommand to restart a previously aborted or failed IUF session. This re-executes the most recent IUF session executed via `iuf run`. Any Argo step that already executed successfully is skipped if possible; the
Argo UI displays the step, but the corresponding log file will contain a message if the step operations were skipped. If the `-f` argument is specified, all stages specified by the most recent `iuf run` will be re-executed, regardless
of whether they succeeded or failed during the previous invocation of `iuf run`.

The following arguments may be specified when invoking `iuf restart`:

```text
usage: iuf restart [-h] [-f]

Restart a previously aborted or failed IUF session for a given activity.

positional arguments:
  comment      Add a comment to the activity log

options:
  -h, --help  show this help message and exit
  -f, --force  Force all operations to be re-executed irrespective if they have been successful in the past.
```

These [examples](examples/iuf_restart.md) highlight common use cases of `iuf restart`.

#### `activity`

The `activity` subcommand allows the administrator to create a new activity, display details for an activity, list activities, and create, update, and annotate activity states. These operations allow the administrator to easily determine the status
of IUF activity operations and associate time-based metrics and user-specified comments with them.

The activity details displayed are:

| Column                  | Description                                                          |
|-------------------------|----------------------------------------------------------------------|
| Start / Session         | The time that this operation began execution and name of session     |
| Category                | The state of the activity when the operation was created             |
| Command / Argo Workflow | The Argo workflow associated with the operation and command executed |
| Status                  | The status of the operation                                          |
| Duration                | How long the operation has been in this state (if not completed)     |
| Comment                 | User-specified comments associated with the operation                |

Values for `Category` are:

| Category Value   | Description                                                                          |
|------------------|--------------------------------------------------------------------------------------|
| `in_progress`    | An Argo workflow was initiated at the time recorded in `Start`                       |
| `waiting_admin`  | No activity operations were in progress beginning at time recorded in `Start`        |
| `paused`         | The administrator paused activity operations at the time recorded in `Start`         |
| `debug`          | The administrator started debugging an issue at the time recorded in `Start`         |
| `blocked`        | The administrator reported being blocked by an issue at the time recorded in `Start` |

Values for `Status` are:

| Status Value   | Description                                                                    |
|----------------|--------------------------------------------------------------------------------|
| `Succeeded`    | The `Argo Workflow` completed successfully                                     |
| `Failed`       | The `Argo Workflow` failed                                                     |
| `Running`      | The `Argo Workflow` is currently executing                                     |
| `n/a`          | The activity entry is not associated with an `Argo Workflow` and has no status |

**`NOTE`** Each row displayed by `iuf activity` is a historical entry associated with the recorded `Start` and the `Duration` time values. For example, the `Category` value `in_progress` signifies that an Argo Workflow was put
in progress at the time the entry was created, but it may not still be running when `iuf activity` is executed. The `Status` value provides context on whether an Argo Workflow is still executing.

The following arguments may be specified when invoking `iuf activity`:

```text
usage: iuf activity [-h] [--time TIME] [--create] [--comment COMMENT] [--status {Succeeded,Failed,Running,n/a}]
                    [--argo-workflow-id ARGO_WORKFLOW_ID]
                    [{in_progress,waiting_admin,paused,debug,blocked}]

Create, display, or annotate activity information.

positional arguments:
  {in_progress,waiting_admin,paused,debug,blocked}
                        activity state value

options:
  -h, --help            show this help message and exit
  --time TIME           A time value used when creating or modifying an activity entry. Must match an
                        existing time value to modify that entry. Defaults to now.
  --create              Create a new activity entry.
  --comment COMMENT     A comment to be associated with an activity entry.
  --status {Succeeded,Failed,Running,n/a}
                        A status value to be associated with an activity entry.
  --argo-workflow-id ARGO_WORKFLOW_ID
                        An Argo workflow identifier to be associated with an activity entry.
```

These [examples](examples/iuf_activity.md) highlight common use cases of `iuf activity`.

#### `list-activities`

The `list-activities` subcommand displays all activities present on the system.

The following arguments may be specified when invoking `iuf list-activities`:

```bash
usage: iuf list-activities [-h]

List all IUF activities stored in argo.

options:
  -h, --help  show this help message and exit
```

These [examples](examples/iuf_list_activities.md) highlight common use cases of `iuf list-activities`.

#### `list-stages`

The `list-stages` subcommand displays the stages for a given activity, the status of each stage, and the time spent in each stage.

The following arguments may be specified when invoking `iuf list-stages`:

```bash
usage: iuf list-stages [-h]

List IUF stage information and status for a given activity specified via `-a`.

options:
  -h, --help  show this help message and exit
```

These [examples](examples/iuf_list_stages.md) highlight common use cases of `iuf list-stages`.

### `workflow`

```bash
usage: iuf workflow [-h] [--debug] [workflows ...]

List information for a particular workflow

positional arguments:
  workflows    workflow to look up

options:
  -h, --help   show this help message and exit
  --debug, -d  Give more granular details about the workflow
```

These [examples](examples/iuf_workflow.md) highlight common use cases if `iuf workflow`.

## Output and log files

### `iuf` output

`iuf` subcommands display status information to standard output as IUF stages execute. Stages are made up of one or more Argo workflows, each performing a series of tasks via Argo steps. `iuf` output primarily consists of:

- stage begin messages
- stage end summaries
- Argo workflow identifiers created when executing a stage
- Argo pod and step begin and end messages
- completion status of each phase (Succeeded, Failed)
- time duration metrics

In addition, any IUF log messages generated by IUF or products with a severity of `INFO` or higher are displayed to standard output.

**`NOTE`** Messages from community software utilized by IUF and products being installed may also be displayed on `iuf` standard output if they match the message format and severity level `iuf` monitors.

The Argo workflow identifiers displayed, like `admin-05-15-psdlp-process-media-l8n8c` in the example below, can be queried in the [Argo UI](../argo/Using_the_Argo_UI.md) to provide access to more detailed log
information and monitoring capabilities. The lines prefixed with `BEG` and `END` primarily map to Argo steps and pods that are linked to the corresponding Argo workflow in the Argo UI.

(`ncn-m001#`) Example of `iuf` command and output.

```bash
iuf -a admin.05-15 run --site-vars /etc/cray/upgrade/csm/admin/site_vars.yaml --bootprep-config-managed /etc/cray/upgrade/csm/admin/compute-and-uan-bootprep.yaml --recipe-vars /etc/cray/upgrade/csm/admin/product_vars.yaml -e update-vcs-config
```

Example output:

```text
INFO All logs will be stored in /etc/cray/upgrade/csm/iuf/admin.05-15/log/20230516171522
WARN --bootprep-config-management was specified without --bootprep-config-managed.  The managed images will not be built.
INFO [ACTIVITY: admin.05-15                                    ] BEG Install started at 2023-05-16 17:15:22.812087
INFO [IUF SESSION: admin-05-15-psdlp                           ] BEG Started at 2023-05-16 17:15:24.849971
INFO [STAGE: process-media                                     ] BEG Argo workflow: admin-05-15-psdlp-process-media-l8n8c
INFO [extract-release-distributions                            ] BEG extract-release-distributions
INFO [extract-release-distributions                            ] BEG start-operation
INFO [extract-release-distributions                            ] END start-operation [Succeeded]
INFO [extract-release-distributions                            ] BEG list-tar-files
INFO [extract-release-distributions                            ] END list-tar-files [Succeeded]
INFO [extract-tar-files                                        ] BEG extract-tar-files
INFO [extract-tar-files(0:analytics-1.4.22.tar.gz)             ] BEG extract-tar-files(0:analytics-1.4.22.tar.gz)
INFO [extract-tar-files(0:analytics-1.4.22.tar.gz)             ] Extracting product tarball /etc/cray/upgrade/csm/admin.05-15/analytics-1.4.22.tar.gz
INFO [extract-tar-files(1:uss-1.0.0-61-cos-base-3.0.tar.gz)    ] Extracting product tarball /etc/cray/upgrade/csm/admin.05-15/uss-1.0.0-61-cos-base-3.0.tar.gz
INFO [extract-tar-files                                        ] END extract-tar-files [Succeeded]
INFO [extract-tar-files(0:analytics-1.4.22.tar.gz)             ] END extract-tar-files(0:analytics-1.4.22.tar.gz) [Succeeded]
INFO [extract-release-distributions                            ] BEG end-operation
INFO [extract-tar-files(1:uss-1.0.0-61-cos-base-3.0.tar.gz)    ] END extract-tar-files(1:uss-1.0.0-61-cos-base-3.0.tar.gz) [Succeeded]
INFO [extract-release-distributions                            ] END end-operation [Succeeded]
INFO [extract-release-distributions                            ] BEG prom-metrics
INFO [extract-release-distributions                            ] END extract-release-distributions [Succeeded]
INFO [extract-release-distributions                            ] END prom-metrics [Succeeded]
INFO [STAGE: process-media                                     ] END Succeeded in 0:01:43
INFO [IUF SESSION: admin-05-15-psdlp                           ] END Completed at 2023-05-16 17:17:20.954763
INFO [IUF SESSION: admin-05-15-o0o25                           ] BEG Started at 2023-05-16 17:17:21.781044
INFO [STAGE: pre-install-check                                 ] BEG Argo workflow: admin-05-15-o0o25-pre-install-check-9rlq6
INFO [preflight-checks-for-services                            ] BEG preflight-checks-for-services
[...]
```

### Log files

IUF stores detailed information in log files which are stored on a Ceph block device typically mounted at `/etc/cray/upgrade/csm/`. The default log file directory location can be overridden with the `iuf -b` and `iuf --log-dir`
options (see `iuf -h` for details).

Log files are organized by activity identifiers, for example `admin-230127`. The top-level `state` directory contains information internal to the implementation of IUF and is inessential to the administrator.
The content in the top-level `log` directory contains information about the operations executed while installing, upgrading and deploying product software and will likely be useful if a problem occurs. The following
describes the contents of the files in the `log` directory for an activity:

| Path                               | Description                                                                |
|------------------------------------|----------------------------------------------------------------------------|
| `log/install.log`                  | Link to most recent log file in `log/<directory>/`                         |
| `log/<directory>/`                 | Time-stamped directory created when a new `iuf` command is executed        |
| `log/<directory>/install.log`      | Log file with content created by `iuf`                                     |
| `log/<directory>/argo_logs/<file>` | Log files with content created by Argo as Argo pods execute IUF operations |

(`ncn-m001#`) Display log files for a given activity.

```bash
cd /etc/cray/upgrade/csm/iuf/admin-230127
find . -type f,l | sort -r
```

Truncated example output:

```text
./log/install.log
./log/20230127203740/install.log
./log/20230127203740/argo_logs/admin-230127-zb268-process-media-v5dsw-2642752133.txt
./log/20230127203740/argo_logs/admin-230127-zb268-process-media-v5dsw-2337635292.txt
./log/20230127203740/argo_logs/admin-230127-zb268-process-media-v5dsw-2192584523.txt
./log/20230127203740/argo_logs/admin-230127-f1w34-pre-install-check-ztsrg-3983759619.txt
./log/20230127203740/argo_logs/admin-230127-f1w34-pre-install-check-ztsrg-3010622324.txt
./log/20230127203740/argo_logs/admin-230127-f1w34-pre-install-check-ztsrg-1366701318.txt
```

## Site and recipe variables

IUF site and recipe variables allow the administrator to customize product, product version, and branch values used by IUF when
executing IUF stages. They ensure automated VCS branch merging, CFS configuration creation, and IMS image creation operations are
performed with values adhering to site preferences.

Recipe variables are provided via the `product_vars.yaml` file in the HPC CSM Software Recipe and provide a list of products and
versions intended to be used together. `product_vars.yaml` also contains default settings and `working_branch` variable entries for
products. `product_vars.yaml` is provided by HPE and the values are intended as defaults only.

Site variables, typically specified in a `site_vars.yaml` file, allow the administrator to override values provided by recipe
variables, including global default entries and product-specific entries. HPE does not provide a `site_vars.yaml` file as it is
strictly for site use cases. See the text at the top of the HPE-provided `product_vars.yaml` file for details on which override
values can be specified in `site_vars.yaml`. The `site_vars.yaml` file must reside on the Ceph block device typically mounted at
`/etc/cray/upgrade/csm/`.

If both files are used and specific variables are defined in both files, the values specified in the site variables file takes
precedence.

The `iuf run` subcommand has arguments that allow the administrator to reference the site and/or recipe variables files, `-sv` and `-rv`
respectively. The variables specified in the files are used by IUF when executing the `update-vcs-config`, `update-cfs-config`, and
`prepare-images` stages. For example, the `working_branch` variable defines the naming convention used by IUF to find or create a
product's VCS branch containing site-customized configuration content, which happens as part of the `update-vcs-config` stage.

The `iuf run` subcommand also has a `-bpcd` argument that allow the administrator to reference a directory containing the HPE-provided
recipe variables file and `sat bootprep` input files. This can be used instead of the `-rv` argument.

An example use case for site and recipe variables is provided in the [`update-vcs-config`](stages/update_vcs_config.md) stage documentation.

## `sat bootprep` configuration files

`sat bootprep` configuration files are used by the `update-cfs-config` and `prepare-images` IUF stages. `update-cfs-config` uses `sat bootprep`
input files to define the CFS configurations used to customize management NCN and managed node images and post-boot node environments.
`prepare-images` uses `sat bootprep` input files to create management NCN and managed node images.

HPE provides management NCN and managed node `sat bootprep` configuration files in the HPC CSM Software Recipe. The files provide default
CFS configuration, image, and BOS session template definitions. The administrator may customize the files as needed. The files include
variables, and the values used are provided by the recipe variables and/or site variables files specified when running `iuf run`.

### ARM images

`sat bootprep` files support building ARM images on an opt-in basis. A commented configuration is provided in the `compute-and-uan-bootprep.yaml` file.

```yaml
# The following images are required only on systems with aarch64 (ARM) nodes.
# Uncomment the lines below if ARM images are needed.
#- name: "{{default.note}}{{base.name}}{{default.suffix}}"
#  ref_name: base_uss_image.aarch64
#  base:
#    product:
#      name: uss
#      type: recipe
#      version: "{{uss.version}}"
#      filter:
#        arch: aarch64
#
#- name: "compute-{{base.name}}"
#  ref_name: compute_image.aarch64
#  base:
#    image_ref: base_uss_image.aarch64
#  configuration: "{{default.note}}compute-{{recipe.version}}{{default.suffix}}"
#  configuration_group_names:
#  - Compute
#
#- name: "uan-{{base.name}}"
#  ref_name: uan_image.aarch64
#  base:
#    image_ref: base_uss_image.aarch64
#  configuration: "{{default.note}}uan-{{recipe.version}}{{default.suffix}}"
#  configuration_group_names:
#  - Application
#  - Application_UAN
```

## Recovering from failures

If an error is encountered while executing `iuf run`, `iuf` will attempt to complete the current stage for the other products involved. The following are strategies to recover from failures once the underlying issue has been
resolved.

### Addressing the issue without changing products

Multiple options are available if the administrator decides to continue the install or upgrade without changing the products being installed or upgraded:

- [`iuf resume`](#resume) can be used to re-execute the most recent `iuf run` command and continue from where the failures were encountered.
- [`iuf restart`](#restart) can be used to re-execute the most recent `iuf run` command from the beginning of the earliest stage specified. Only failed or previously unexecuted Argo steps will be executed unless the `-f`
  argument is specified, which forces all Argo steps to be re-executed, regardless of whether they succeeded or failed during the previous invocation of `iuf run`.
- [`iuf run`](#run) can be used to re-execute stages of an IUF session with new `iuf` arguments. If no changes were made to the product distribution files in the media directory, `iuf run` will re-execute any Argo steps that failed
  during the previous invocation of `iuf run`. Any Argo steps that previously executed successfully will be skipped if possible. If the `-f` argument is specified, all Argo steps will be re-executed, regardless of whether they
  succeeded or failed during the previous invocation of `iuf run`.

### Addressing the issue by removing a product

If the administrator wants to remove a product from the IUF session, they must re-execute `iuf run` for the `process-media` stage with the product distribution file and uncompressed content removed from the media directory. This
removes references to that product from the existing IUF activity.

If any previously executed stages performed operations with the removed product, re-execute them. It may be necessary to perform manual operations as well, e.g. modifying the `sat bootprep` input files used to create images in
order to remove references to the product.

The administrator can then execute any remaining stages that did not complete due to the initial failure.

### Addressing the issue by adding a new version of a product

To add a new version of an existing product to the IUF session, re-execute `iuf run` for the `process-media` stage with the new product distribution file added to the media directory. This adds knowledge of that product to the
existing IUF activity. If the new product is being used in place of a different version of the product, remove the previous version of the product distribution file and uncompressed content from the media directory at the same
time the new version is added.

If any previously executed stages performed operations with the removed product, re-execute them. It may be necessary to perform manual operations as well, e.g. modifying the `sat bootprep` input files used to create images in
order to remove references to the product.

The administrator can then execute any remaining stages that did not complete due to the initial failure.

## Troubleshooting

The following actions may be useful if errors are encountered when executing `iuf`.

### 1. CLI

- Examine IUF log files as described in the [Output and log files](#output-and-log-files) section for information not provided on `iuf` standard output.

### 2. Argo UI

- Use the [Argo UI](../argo/Using_the_Argo_UI.md) to find the Argo pod that corresponds to the failed IUF operation. This can be done by finding the Argo workflow identifier displayed on [`iuf` standard output](#iuf-output) for the failed
  IUF operation and performing an Argo UI query with that value. Argo workflow identifiers can also be found by running [`iuf activity`](#activities). The Argo UI will provide additional log information that may help debug the issue.
- There are two methods for limiting the list of Argo workflows displayed by the Argo UI.
  1. Display a single workflow of an activity by specifying the Argo workflow identifier, e.g. `admin-230126-ebjx3-process-media-cq89t`, after the Argo UI "magnifying glass" icon.
  2. Display all workflows for an IUF activity by specifying the activity identifier, e.g. `activity=admin-230126`, in the Argo UI `LABELS` filter.
- If an error is associated with a script invoked by a product's [stage hook](#stages-and-hooks), the script can be found in the expanded product distribution file located in the media directory (`iuf -m MEDIA_DIR`). Examine the
  `hooks` entry in the product's `iuf-product-manifest.yaml` file in the media directory for the path to the script.
- If Argo UI log output is too verbose, filter it by specifying a value such as `^INFO|^NOTICE|^WARNING|^ERROR` in the `Filter (regexp)...` text field.
- If an Argo workflow cannot be found in the Argo UI, select `all` from the `results per page` dropdown list at the bottom of the page listing the Argo workflows.
- If the source of the error cannot be determined by the previous methods, details on the underlying commands executed by an IUF stage can be found in the IUF `workflows` directory. The [Stages and hooks](#stages-and-hooks) section
  of this document includes links to descriptions of each stage. Each of those descriptions includes an **Execution Details** section describing how to find the appropriate code in the IUF `workflows` directory to understand the
  workflow and debug the issue.
- If an Argo step fails, Argo will attempt to re-execute the step. If the retry succeeds, the failed step will still be displayed, colored red, in the Argo UI alongside the successful retry step, colored green. Although the failed
  step is still displayed, it did not affect the success of the overall workflow and can be ignored.

### 3. Log Files

- Examine IUF log files as described in the [Output and log files](#output-and-log-files) section for information not provided on `iuf` standard output.
- If an error is associated with a script invoked by a product's [stage hook](#stages-and-hooks), the script can be found in the expanded product distribution file located in the media directory (`iuf -m MEDIA_DIR`). Examine the
  `hooks` entry in the product's `iuf-product-manifest.yaml` file in the media directory for the path to the script.
- If the source of the error cannot be determined by the previous methods, details on the underlying commands executed by an IUF stage can be found in the IUF `workflows` directory. The [Stages and hooks](#stages-and-hooks) section
  of this document includes links to descriptions of each stage. Each of those descriptions includes an **Execution Details** section describing how to find the appropriate code in the IUF `workflows` directory to understand the
  workflow and debug the issue.

### 4. Specific scenarios

 1. IUF workflow may loop while rebuilding a management node.

    - IUF loops while waiting for CFS to complete configuration of a management node. This step might not be completing because the CFS error count for the node has exceeded the maximum retry count for applying the configuration.
    - Look at the Ansible logs for the CFS configuration operation for that node and attempt to rectify the problem.
    - After resolving the problem, update the default error count in CFS using the below command. Run this command form a master or worker node. Set environment variable `XNAME` to be the xname of the node where the CFS configuration has failed.

         ```bash
         cray cfs components update --enabled true --state '[]' --error-count 0 --format json $XNAME
         ```

    - Once the error count is reset, the CFS will restart configuration for the node. If it does not start within a few minutes,
   check whether CFS is unable to start the configuration again for the node due to any other issue. Rectify the problem by referring to the
   [CFS troubleshooting guide](../../operations/configuration_management/Troubleshoot_CFS_Sessions_Failing_to_Start.md)

## Install and Upgrade Observability Framework

The Install and Upgrade Observability Framework includes assertions for Goss health checks, as well as metrics and dashboards for health checks.
The framework also includes a unified consistent method to automatically track Time to Install (TTI) and Time to Upgrade (TTU), as well as error and pattern counts across all nodes and product streams.
The Install and Upgrade Observability Framework is automatically deployed and configured in the CSM environment.

For more information on the Install and Upgrade Observability Framework, refer to [Install and Upgrade Observability Framework](../observability/Observability.md).

## Deleting products installed with IUF

To help the CSM administrator in clearing the cray-product-catalog
of unused product version entries which were installed
using IUF, the `prodmgr` CLI provides a new option
`delete`. This option when used with the `product` and
`version` helps cleanup the following installed by
the product version (if they are not used by other
product versions or other products):

- Docker images
- Helm charts
- Loftsman manifests
- S3 artifacts
- IMS images
- IMS recipes
- hosted repositories

Finally, the product entry is also deleted from the `cray-product-catalog` ConfigMap.

An example of launching the `prodmgr` for cleaning a `uss` version `1.0.0` is shown below:

```bash
prodmgr delete uss 1.0.0 --container-registry-hostname arti.hpc.amslabs.hpecorp.net/csm-docker/stable --deletion-image-name product-deletion-utility --deletion-image-version 1.0.0
```

The `prodmgr` is installed as an `rpm` and has a well documented
`help`. The `product-deletion-utility` is a `container` which
interacts with various repos to complete the deletion of
artifacts and subsequent cleanup of the ConfigMap entry.

Both the `rpm` and `container` image are installed as a part of
CSM installation.

For more information about `prodmgr` and `product-deletion-utility`
refer to the following:

- [`prodmgr`](https://github.com/Cray-HPE/prodmgr/blob/main/README.md)
- [`product-deletion-utility`](https://github.com/Cray-HPE/product-deletion-utility/blob/integration/README.md)

### Cleanup of Nexus storage after deletion

Note that the `product-deletion-utility` only marks the artifacts in the blob store for deletion but is not removed from the disk.
For cleaning up the Nexus blob storage, refer to the operational procedure mentioned in [Nexus Space Cleanup](https://github.com/Cray-HPE/docs-csm/blob/release/1.6/operations/package_repository_management/Nexus_Space_Cleanup.md#cleanup-of-data-not-being-used).

### Deletion logs

The `logs` for the progress of deletion is generated in the
`/etc/cray/upgrade/csm/iuf/deletion` directory or the `$CWD` from
where the `prodmgr` is run. The filename is generated as: `delete-<product>-<version>-<timestamp>`. This can be used to analyze the components deleted as part of the deletion run.
