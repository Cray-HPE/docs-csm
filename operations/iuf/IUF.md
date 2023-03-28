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
- [Output and log files](#output-and-log-files)
  - [`iuf` output](#iuf-output)
  - [Log files](#log-files)
- [Site and recipe variables](#site-and-recipe-variables)
- [`sat bootprep` configuration files](#sat-bootprep-configuration-files)
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
  those configurations to their specific needs. Note that `sat` capabilities used by IUF rely on BOS V2.
- IUF will fail and provide feedback to the administrator in the event of an error, but it cannot automatically resolve issues.
- IUF does not handle many aspects of installs and upgrades of CSM itself and cannot be used until a base level of CSM functionality is present.
- The `management-nodes-rollout` stage currently does not automatically upgrade management storage nodes or `ncn-m001`. These nodes must be upgraded using non-IUF methods described in the IUF documentation.
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
variable; for more details, see `iuf -h`.  The activity will be created automatically upon the first invocation of `iuf` with that given activity string.

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
+-------------------------------------------------------------------------------------------------------------------------------+
| Activity: admin-230127                                                                                                        |
+---------------------+-------------+--------------------------------------------+-----------+----------+-----------------------+
| Start               | Category    | Argo Workflow                              | Status    | Duration | Comment               |
+---------------------+-------------+--------------------------------------------+-----------+----------+-----------------------+
| 2023-01-27t20:37:42 | in_progress | admin-230127-zb268-process-media-v5dsw     | Succeeded | 0:01:54  | Run process-media     |
| 2023-01-27t20:39:36 | in_progress | admin-230127-f1w34-pre-install-check-ztsrg | Failed    | 0:01:16  | Run pre-install-check |
| 2023-01-27t20:40:52 | debug       | None                                       | n/a       | 0:31:11  | None                  |
| 2023-01-27t21:12:03 | in_progress | admin-230127-7jtws-process-media-29hzl     | Succeeded | 0:02:00  | Run process-media     |
| 2023-01-27t21:14:03 | in_progress | admin-230127-o7sp4-pre-install-check-phm2w | Failed    | 0:26:09  | Run pre-install-check |
| 2023-01-27t21:40:12 | debug       | None                                       | n/a       | 0:57:40  | None                  |
| 2023-01-27t22:37:52 | in_progress | admin-230127-zgd6o-process-media-zvnqk     | Succeeded | 0:02:06  | Run process-media     |
| 2023-01-27t22:39:58 | in_progress | admin-230127-svs41-pre-install-check-89gjf | Failed    | 0:01:31  | Run pre-install-check |
| 2023-01-27t22:41:29 | debug       | None                                       | n/a       | 0:52:26  | None                  |
| 2023-01-27t23:33:55 | in_progress | admin-230127-0f2xe-update-vcs-config-trpjw | Failed    | 0:00:53  | Run update-vcs-config |
| 2023-01-27t23:34:48 | debug       | None                                       | n/a       | 0:00:00  | None                  |
+---------------------+-------------+--------------------------------------------+-----------+----------+-----------------------+

Summary:
  Start time: 2023-01-27t20:37:40
    End time: 2023-01-27t23:34:48

   in_progress: 0:35:49
         debug: 2:21:17
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
| ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| [process-media](stages/process_media.md)                           | Inventory and extract products in the media directory for use in subsequent stages       |
| [pre-install-check](stages/pre_install_check.md)                   | Perform pre-install readiness checks                                                     |
| [deliver-product](stages/deliver_product.md)                       | Upload product content onto the system                                                   |
| [update-vcs-config](stages/update_vcs_config.md)                   | Merge working branches and perform automated VCS configuration                           |
| [update-cfs-config](stages/update_cfs_config.md)                   | Update CFS configuration (executes `sat bootprep`)                                       |
| [prepare-images](stages/prepare_images.md)                         | Build and configure management node and/or managed node images (executes `sat bootprep`) |
| [management-nodes-rollout](stages/management_nodes_rollout.md)     | Rolling reboot or live update of management nodes                                        |
| [deploy-product](stages/deploy_product.md)                         | Deploy services to system                                                                |
| [post-install-service-check](stages/post_install_service_check.md) | Perform post-install checks of processed services                                        |
| [managed-nodes-rollout](stages/managed_nodes_rollout.md)           | Rolling reboot or live update of managed nodes                                     |
| [post-install-check](stages/post_install_check.md)                 | Perform post-install checks                                                              |

The `process-media` stage must be run at least once for a given activity before any of the other stages can be run. This is required because `process-media` associates the product content being installed or upgraded with an
activity identifier and that information is used for all other stages.

## `iuf` CLI

The `iuf` command-line interface is used to invoke all IUF operations. The `iuf` command provides the following subcommands.

| Subcommand      | Description                                              |
| --------------- | -------------------------------------------------------- |
| run             | Initiates execution of IUF operations                    |
| abort           | Abort an IUF session                                     |
| resume          | Resume a previously aborted or failed IUF session        |
| restart         | Restart the most recently aborted or failed IUF session  |
| activity        | Display IUF activity details, annotate IUF activity      |
| list-activities | List all activities present on the system                |
| list-stages     | Display stages and status for a given IUF activity       |

### Global arguments

Global arguments may be specified when invoking `iuf`. They must be specified before any `iuf` subcommand and its subcommand-specific arguments are specified.

The following shows the global arguments available.

```text
usage: iuf [-h] [-i INPUT_FILE] [-w] [-a ACTIVITY] [-c CONCURRENCY] [-b BASE_DIR] [-s STATE_DIR] [-m MEDIA_DIR]
           [--log-dir LOG_DIR] [-l {CRITICAL,ERROR,WARNING,INFO,DEBUG,TRACE}] [-v]
           {run,activity,list-stages|ls,resume,restart,abort,list-activities|la} ...

The CSM Install and Upgrade Framework (IUF) CLI.

options:
  -h, --help            show this help message and exit
  -i INPUT_FILE, --input-file INPUT_FILE
                        YAML input file used to provide arguments to `iuf`. Command line arguments will override
                        entries in the input file. Can also be set via the IUF_INPUT_FILE environment variable.
  -w, --write-input-file
                        Create a new input file populated with default values overridden by any other command line
                        options also specified. The file is named via the `-i` argument. The command exits once the
                        file has been created.
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
  {run,activity,list-stages|ls,resume,restart,abort,list-activities|la}
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
    NOTE: The IUF CLI will remain connected until Argo completes the abort process.  Use the disconnect option to exit the IUF CLI immediately.
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
                        The last stage to execute.  Defaults to post-install-check
  -r RUN_STAGES [RUN_STAGES ...], --run-stages RUN_STAGES [RUN_STAGES ...]
                        Run the specified stages only. This argument is not compatible with `-b`, `-e`, or `-s`.
  -s SKIP_STAGES [SKIP_STAGES ...], --skip-stages SKIP_STAGES [SKIP_STAGES ...]
                        Skip the execution of the specified stages.
  -f, --force           Force re-execution of stage operations.
  -bc BOOTPREP_CONFIG_MANAGED, --bootprep-config-managed BOOTPREP_CONFIG_MANAGED
                        `sat bootprep` config file for managed (compute and
                        application) nodes.  Note the path is relative to $PWD, unless an
                        absolute path is specified.
  -bm BOOTPREP_CONFIG_MANAGEMENT, --bootprep-config-management BOOTPREP_CONFIG_MANAGEMENT
                        `sat bootprep` config file for management NCNs.  Note the
                        path is relative to $PWD, unless an absolute path is specified.
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
                        Override list used to target specific nodes only when rolling out managed nodes.  Arguments
                        should be xnames or HSM node groups. Defaults to the Compute role.
  --limit-management-rollout LIMIT_MANAGEMENT_ROLLOUT [LIMIT_MANAGEMENT_ROLLOUT ...]
                        Override list used to target specific role_subrole(s) only when rolling out management nodes.
                        Defaults to the Management_Worker role.
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
usage: iuf abort [-h] [-f]

Abort an IUF session for a given activity after the current stage completes.

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
usage: iuf resume [-h]

Resume a previously aborted or failed IUF session for a given activity.

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

options:
  -h, --help  show this help message and exit
  -f, --force  Force all operations to be re-executed irrespective if they have been successful in the past.
```

These [examples](examples/iuf_restart.md) highlight common use cases of `iuf restart`.

#### `activity`

The `activity` subcommand allows the administrator to create a new activity, display details for an activity, and create, update, and annotate activity states. These operations allow the administrator to easily determine the status
of IUF activity operations and associate time-based metrics and user-specified comments with them.

The activity details displayed are:

| Column         | Description                                                      |
| -------------- | ---------------------------------------------------------------- |
| Start          | The time that this operation began execution                     |
| Category       | The state of the activity when the operation was created         |
| Argo Workflow  | The Argo workflow associated with the operation                  |
| Status         | The status of the operation                                      |
| Duration       | How long the operation has been in this state (if not completed) |
| Comment        | User-specified comments associated with the operation            |

Values for `Category` are:

| Category Value | Description                                                                          |
| -------------- | ------------------------------------------------------------------------------------ |
| in_progress    | An Argo workflow was initiated at the time recorded in `Start`                       |
| waiting_admin  | No activity operations were in progress beginning at time recorded in `Start`        |
| paused         | The administrator paused activity operations at the time recorded in `Start`         |
| debug          | The administrator started debugging an issue at the time recorded in `Start`         |
| blocked        | The administrator reported being blocked by an issue at the time recorded in `Start` |

Values for `Status` are:

| Status Value | Description                                                                    |
| ------------ | ------------------------------------------------------------------------------ |
| Succeeded    | The `Argo Workflow` completed successfully                                     |
| Failed       | The `Argo Workflow` failed                                                     |
| Running      | The `Argo Workflow` is currently executing                                     |
| n/a          | The activity entry is not associated with an `Argo Workflow` and has no status |

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

The Argo workflow identifiers displayed, like `admin-230127-zb268-process-media-v5dsw` in the example below, can be queried in the [Argo UI](../argo/Using_the_Argo_UI.md) to provide access to more detailed log
information and monitoring capabilities. The lines prefixed with `BEGIN:` and `FINISHED:` primarily map to Argo steps and pods that are linked to the corresponding Argo workflow in the Argo UI.

(`ncn-m001#`) Example of `iuf` command and output.

```bash
iuf -a admin-230127 run --site-vars /etc/cray/upgrade/csm/admin/site_vars.yaml --bootprep-config-dir /etc/cray/upgrade/csm/admin -e update-vcs-config
```

Example output:

```text
INFO   ARGO WORKFLOW: admin-230127-zb268-process-media-v5dsw
INFO              BEGIN: extract-release-distributions
INFO              BEGIN: start-operation
INFO           FINISHED: start-operation [Succeeded]
INFO              BEGIN: list-tar-files
INFO           FINISHED: list-tar-files [Succeeded]
INFO              BEGIN: extract-tar-files
INFO              BEGIN: extract-tar-files(0:cpe-slurm-23.02-sles15-1.2.9-20230123212534_30822fc.tar.gz)
INFO           FINISHED: extract-tar-files [Succeeded]
INFO           FINISHED: extract-tar-files(0:cpe-slurm-23.02-sles15-1.2.9-20230123212534_30822fc.tar.gz) [Succeeded]
INFO              BEGIN: end-operation
INFO           FINISHED: end-operation [Succeeded]
INFO              BEGIN: prom-metrics
INFO           FINISHED: extract-release-distributions [Succeeded]
INFO           FINISHED: prom-metrics [Succeeded]
INFO          RESULT: Succeeded
INFO        DURATION: 0:01:51
INFO Dumping rendered site variables to /etc/cray/upgrade/csm/iuf/admin-230127/state/session_vars.yaml
INFO IUF SESSION: admin-230127-f1w34
INFO       IUF STAGE: pre-install-check
INFO   ARGO WORKFLOW: admin-230127-f1w34-pre-install-check-ztsrg
INFO              BEGIN: preflight-checks-for-services
INFO              BEGIN: start-operation
INFO           FINISHED: start-operation [Succeeded]
INFO              BEGIN: preflight-checks
INFO              BEGIN: preflight-checks(0)
[...]
```

### Log files

IUF stores detailed information in log files which are stored on a Ceph Block Device typically mounted at `/etc/cray/upgrade/`. The default log file directory location can be overridden with the `iuf -b` and `iuf --log-dir`
options (see `iuf -h` for details).

Log files are organized by activity identifiers, for example `admin-230127`. The top-level `state` directory contains information internal to the implementation of IUF and is most often uninteresting to the administrator.
The content in the top-level `log` directory contains information about the operations executed while installing, upgrading and deploying product software and will likely be useful if a problem occurs. The following
describes the contents of the files in the `log` directory for an activity:

| Path                               | Description                                                                |
| ---------------------------------- | -------------------------------------------------------------------------- |
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
values can be specified in `site_vars.yaml`.

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

- Examine IUF log files as described in the [Output and log files](#output-and-log-files) section for information not provided on `iuf` standard output.
- Use the [Argo UI](../argo/Using_the_Argo_UI.md) to find the Argo pod that corresponds to the failed IUF operation. This can be done by finding the Argo workflow identifier displayed on [`iuf` standard output](#iuf-output) for the failed
  IUF operation and performing an Argo UI query with that value. Argo workflow identifiers can also be found by running [`iuf activity`](#activities). The Argo UI will provide additional log information that may help debug the issue.
- There are two methods for limiting the list of Argo workflows displayed by the Argo UI.
  1. Display a single workflow of an activity by specifying the Argo workflow identifier, e.g. `admin-230126-ebjx3-process-media-cq89t`, after the Argo UI "magnifying glass" icon.
  1. Display all workflows for an IUF activity by specifying the activity identifier, e.g. `activity=admin-230126`, in the Argo UI `LABELS` filter.
- If an error is associated with a script invoked by a product's [stage hook](#stages-and-hooks), the script can be found in the expanded product distribution file located in the media directory (`iuf -m MEDIA_DIR`). Examine the
  `hooks` entry in the product's `iuf-product-manifest.yaml` file in the media directory for the path to the script.
- If Argo UI log output is too verbose, filter it by specifying a value such as `^INFO|^NOTICE|^WARNING|^ERROR` in the `Filter (regexp)...` text field.
- If an Argo workflow cannot be found in the Argo UI, select `all` from the `results per page` dropdown list at the bottom of the page listing the Argo workflows.
- If the source of the error cannot be determined by the previous methods, details on the underlying commands executed by an IUF stage can be found in the IUF `workflows` directory. The [Stages and hooks](#stages-and-hooks) section
  of this document includes links to descriptions of each stage. Each of those descriptions includes an **Execution Details** section describing how to find the appropriate code in the IUF `workflows` directory to understand the
  workflow and debug the issue.
- If an Argo step fails, Argo will attempt to re-execute the step. If the retry succeeds, the failed step will still be displayed, colored red, in the Argo UI alongside the successful retry step, colored green. Although the failed
  step is still displayed, it did not affect the success of the overall workflow and can be ignored.

## Install and Upgrade Observability Framework

The Install and Upgrade Observability Framework includes assertions for Goss health checks, as well as metrics and dashboards for health checks.
The framework also includes a unified consistent method to automatically track Time to Install (TTI) and Time to Upgrade (TTU), as well as error and pattern counts across all nodes and product streams.
The Install and Upgrade Observability Framework is automatically deployed and configured in the CSM environment.

For more information on the Install and Upgrade Observability Framework, refer to [Install and Upgrade Observability Framework](../observability/Observability.md).
