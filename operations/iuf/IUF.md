# Install and Upgrade Framework

## Overview

The Install and Upgrade Framework (IUF) provides a CLI and API which automates operations required to install, upgrade
 and deploy non-CSM product content onto an HPE Cray EX system. These products are documented in the
[HPE Cray EX System Software Getting Started Guide S-8000](https://www.hpe.com/support/ex-S-8000). Each product
distribution includes an `iuf-product-manifest.yaml` file which IUF uses to determine what operations are needed to
install, upgrade, and deploy the product. IUF operates on all of the product distribution files found in a single
media directory.

IUF groups the install, upgrade, and deploy operations into stages. The administrator can execute some or all of the stages
with one or multiple products in a single activity. `iuf` arguments for all stages can be specified prior to execution
in order to automate the operations and minimize user interaction.

In addition, IUF provides metric and annotation capabilities which can be used to view status and record historical
information associated with an install or upgrade.

IUF utilizes [Argo workflows](../argo/Using_Argo_Workflows.md) to execute and parallelize IUF operations and to provide
visibility into the status of the operations through the [Argo UI](../argo/Using_the_Argo_UI.md). The `iuf` CLI invokes an
Argo workflow based on the subcommand specified. The Argo workflow is not controlled by `iuf` once it has been created, but
`iuf` does displays status to the administrator as the Argo workflow executes.

The following IUF topics are discussed in the subsections below.

- [Limitations](#limitations)
- [Initial Install and Upgrade Workflows](#initial-install-and-upgrade-workflows)
- [Activities](#activities)
- [Sessions](#sessions)
- [Stages and Hooks](#stages-and-hooks)
- [`iuf` CLI](#iuf-cli)
- [Output and Log Files](#output-and-log-files)
- [Site and Recipe Variables](#site-and-recipe-variables)
- [Product Workflows](#product-workflows)


## Limitations

- `iuf` must be executed from the ncn-m001 node.
- While IUF enables non-interactive deployment of product software, it does not automatically configure the software beyond merging new VCS release branch content to customer working branches. For example, if a product requires manual configuration, the administrator must stop IUF execution after the `update-vcs-config` stage, perform the manual configurations steps, and then resume with the next IUF stage (`update-cfs-config`).
- IUF leverages `sat bootprep` for CFS configuration and image creation. It is intended to be used with the configuration files provided in the HPC CSM Software Recipe and requires the administrator to verify and customize those configurations to their specific needs.
- IUF will fail and provide feedback to the administrator in the event of an error, but it cannot automatically resolve issues.
- IUF does not handle many aspects of installs and upgrades of CSM itself and cannot be used until a base level of CSM functionality is present.

## Initial Install and Upgrade Workflows

The time at which IUF stages are executed in an initial install or upgrade workflow depends on whether CSM itself is also being installed or upgraded in addition to non-CSM products. This table describes the different use cases and tasks performed.

| Operation       | Content          | Tasks |
| --------------- | ---------------- | ----- |
| initial install | CSM and products | Install CSM, **ignoring** any IUF stages embedded in the CSM installation documentation <br> Execute all IUF stages to install product content after CSM is fully functional |
| initial install | products only    | Execute IUF stages to install non-CSM product content |
| upgrade         | CSM and products | Upgrade CSM, **including** any IUF stages embedded in the CSM installation documentation |
| upgrade         | products only    | Execute IUF stages to upgrade non-CSM product content |

**<< TODO: INSERT INITIAL INSTALL AND UPGRADE DIAGRAMS HERE >>**

## Activities

An activity is a user-specified unique string identifier used to group and track IUF actions, typically those needed to complete an install or upgrade using a set of product distribution files. An example of an activity identifier is `joe-install-20221219`. `iuf` subcommands accept an activity as input, and the corresponding IUF output and log files are organized by that activity. The activity can be specified via an `iuf` argument or an environment variable; for more details, see `iuf -h`.  The activity will be created automatically upon the first invocation of IUF with that given activity string.

IUF provides operational metrics associated with an activity (e.g. the time duration of each stage executed). Users can also create annotations for an activity, e.g. to note that an operation has been paused, to note that time was spent debugging an issue, etc. `iuf` subcommands can be invoked to display a summary of actions, annotations, and metrics associated with an activity.

The following example shows stage information associated with the `joe-install-20230107` activity:

(ncn-m001#) List operations for an IUF activity.

```bash
iuf -a joe-install-20230107 activity
+------------------------------------------------------------------------------------------------------------------------------------------------+
| Activity: joe-install-20230107                                                                                                                 |
+---------------------+----------------+-----------------------------------------------------+---------+-----------------+-----------------------+
| start               | activity state | IUF sessionid                                       | Status  | Duration        | Comment               |
+---------------------+----------------+-----------------------------------------------------+---------+-----------------+-----------------------+
| 2023-01-07t21:58:25 | in_progress    | joe-install-20230107u0sil-process-media-8lqms       | n/a     | 0:01:35         | Run process-media     |
| 2023-01-07t22:00:00 | waiting_admin  | None                                                | n/a     | 0:37:15         | None                  |
| 2023-01-07t22:37:15 | in_progress    | joe-install-20230107rr78c-pre-install-check-nn9hs   | n/a     | 0:00:25         | Run pre-install-check |
| 2023-01-07t22:37:40 | waiting_admin  | None                                                | n/a     | 1:02:52         | None                  |
| 2023-01-07t23:40:32 | in_progress    | joe-install-20230107kq3cr-deliver-product-qfj9s     | n/a     | 0:07:16         | Run deliver-product   |
| 2023-01-07t23:47:48 | waiting_admin  | None                                                | n/a     | 22:26:27        | None                  |
| 2023-01-08t22:14:15 | debug          | None                                                | n/a     | 0:00:40         | test 1                |
+---------------------+----------------+-----------------------------------------------------+---------+-----------------+-----------------------+
```

## Sessions

A session is a unique string identifier automatically created by IUF to track IUF activity operations on a finer granularity. An example of a session identifier is `joe-install-20230107u0sil-process-media-8lqms`. A session is generated within an IUF activity for each `iuf` operation executed. For example, if an administrator invokes IUF to execute the `process-media` and `pre-install-check` stages, two sessions will be created: one associated with the `process-media` operations and one associated with the `pre-install-check` operations. Not all operations in an activity are associated with a session, however. For example, annotation events and time spent waiting for the administrator to invoke the next operation do not result in the execution of IUF install and upgrade operations, and thus are not associated with a session.

Session identifiers are recorded in the IUF log files and are also displayed by `iuf activity`. In general, administrators do not need to be concerned with sessions. The exception is when IUF encounters an error. At that point, session identifiers can be specified via `iuf` to resume or abort the session (see `iuf resume -h` and `iuf abort -h`).

(ncn-m001#) The following example shows session information reported by the `iuf activity` command.

```bash
iuf -a joe-install-20230107 activity
+------------------------------------------------------------------------------------------------------------------------------+
| Activity: joe-install-20230107                                                                                               |
+---------------------+----------------+-----------------------------------------------+--------+----------+-------------------+
| start               | activity state | IUF sessionid                                 | Status | Duration | Comment           |
+---------------------+----------------+-----------------------------------------------+--------+----------+-------------------+
| 2023-01-07t21:58:25 | in_progress    | joe-install-20230107u0sil-process-media-8lqms | n/a    | 0:01:35  | Run process-media |
| 2023-01-07t22:00:00 | waiting_admin  | None                                          | n/a    | 0:08:49  | None              |
+---------------------+----------------+-----------------------------------------------+--------+----------+-------------------+
```

## Stages and Hooks

Install and upgrade operations performed by IUF are organized into stages. The administrator can execute one or more stages in a single invocation of `iuf run`. A single stage can execute with the content of one or more products. IUF operates on all products found in a single media directory specified by the administrator.  When possible, IUF will parallelize execution for products within a stage, e.g. the `process-media` stage will extract content for all products found in the media directory at the same time.

A stage will not complete until it has completed execution for all products specified in the activity. If an error is encountered while executing a stage for a given product, IUF will allow other products to complete the execution of the stage and will then stop execution, marking the activity as `<< TODO >>` and the stage as `<< TODO >>`.

IUF provides a hook capability for all stages. This allows a product to execute additional scripts before and/or after a given stage executes. Hooks allow products to perform special actions that IUF does not perform itself at an appropriate time in an initial install or upgrade workflow. These hook scripts are executed automatically by IUF; no input from the administrator is required. All product scripts registered via a pre-stage hooks must complete before the stage executes, and no product post-stage hook will execute until the stage itself has completed.

The administrator may execute one, multiple, or all stages in a single `iuf run` invocation depending on the task to be accomplished. If multiple stages are specified, they must be executed in the order listed below and displayed by the `iuf list-stages` subcommand. The `iuf run` subcommand provides arguments to specify which stages are to be run and if any stages should be skipped.

The following table lists all of the stages in the order they are executed when performing an initial install or upgrade of one or more products. **Click the links in the `Stage` column for additional details about the stages.**

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
| [managed-nodes-rollout](stages/managed_nodes_rollout.md)           | Rolling reboot or live update of managed nodes nodes                                     |
| [post-install-check](stages/post_install_check.md)                 | Perform post-install checks                                                              |

## `iuf` CLI

The `iuf` command line interface is used to invoke all IUF operations. The `iuf` command provides the following subcommands.

| Subcommand  | Description                                         |
| ----------- | --------------------------------------------------- |
| run         | Initiates execution of IUF operations               |
| abort       | Abort a paused IUF session                          |
| resume      | Resume a paused IUF session from where it stopped   |
| restart     | Re-run a paused IUF session from the beginning      |
| activity    | Display IUF activity details, annotate IUF activity |
| list-stages | Display stages and status for a given IUF activity  |

### Global Arguments

Global arguments may be specified when invoking `iuf`. They must be specified before any `iuf` subcommand and its subcommand-specific arguments are specified. The following global arguments are available:

```bash
usage: iuf [-h] [-i INPUT_FILE] [-w] [-a ACTIVITY_SESSION] [-b BASE_DIR]
           [-s STATE_DIR] [-m MEDIA_DIR] [-sp SITE_PARAMETERS]
           [--log-dir LOG_DIR] [-l {CRITICAL,ERROR,WARNING,INFO,DEBUG,TRACE}]
           [-v]
           {run,activity,list-stages|ls,list-products|resume|restart|abort}
           ...

The CSM Install and Upgrade Framework (IUF) Installer.

optional arguments:
  -h, --help            show this help message and exit
  -i INPUT_FILE, --input-file INPUT_FILE
                        Input file used to control the install. Command line
                        arguments will override what is in the file. Input
                        file should be YAML. Can also be set via the
                        IUF_INPUT_FILE environment variable.
  -w, --write-input-file
                        Write out a new config file to the input file
                        specified with defaults+ any command line options
                        specified and quit.
  -a ACTIVITY_SESSION, --activity-session ACTIVITY_SESSION
                        Activity session name. Must be a unique identifier.
                        Session names must only contain letters (A-Za-z),
                        numbers (0-9), periods (.), and dashes (-). Can also
                        be set via the IUF_ACTIVITY_SESSION environment
                        variable.
  -b BASE_DIR, --base-dir BASE_DIR
                        Base directory for state and log dirs. Default is
                        ${RSM_BASE_DIR}/iuf/<activity-session>
  -s STATE_DIR, --state-dir STATE_DIR
                        A directory used to store the current state of stages.
                        Defaults to [base-dir]/state.
  -m MEDIA_DIR, --media-dir MEDIA_DIR
                        Location of installation media you would like to
                        install. Defaults to $RBD_BASE_DIR/{activity_session}
  -sp SITE_PARAMETERS, --site-parameters SITE_PARAMETERS
                        Path to site parameters file. Default is ${RSM_BASE_DI
                        R}/$IUF_ACTIVITY_SESSION}/site_parameters.yaml
  --log-dir LOG_DIR     Location used to store log files. Defaults to [base-
                        dir]/log
  -l {CRITICAL,ERROR,WARNING,INFO,DEBUG,TRACE}, --level {CRITICAL,ERROR,WARNING,INFO,DEBUG,TRACE}
                        Set the debug level to the console
  -v, --verbose         Generates more verbose messages

subcommands:
  {run,activity,list-stages|ls,list-products|resume|restart|abort}
```

### Input File

As described in the [Output and Log Files](#output-and-log-files) section, the `-i INPUT_FILE` argument can be used to read `iuf` arguments and values from a YAML input file. Both global and subcommand-specific arguments can be specified in the input file. If an input file is used in addition to `iuf` arguments, the `iuf` arguments take precedence. The name of an entries in the input file corresponds to the long form name of the `iuf` argument with hyphens replaced by underscores.

The following in an example of an `iuf` input file:

```yaml
global:
    activity_session: joe-install-20230107
    base_dir: /home/admin1/hpc-csm-software-recipe-22.11.7
    state_dir: /home/admin1/hpc-csm-software-recipe-22.11.7/state
    media_dir: /home/admin1/hpc-csm-software-recipe-22.11.7/media
list-stages:
    format: null
run:
    begin_stage: process-media
    end_stage: update-vcs-config
```

### Subcommands

#### `run`

The `run` subcommand is used to execute one or more IUF stages. The `-b`, `-e`, `-r` and `-s` arguments can be specified to limit the stages executed. If none of those arguments are specified, `iuf run` will execute all stages in order. If an activity identifier is not provided via `-a`, a new activity will be created automatically.

The following arguments may be specified when invoking `iuf run`:

```bash
usage: iuf run [-h] [-b BEGIN_STAGE] [-e END_STAGE]
               [-r RUN_STAGES [RUN_STAGES ...]]
               [-s SKIP_STAGES [SKIP_STAGES ...]] [-F FORCE]
               [-bc BOOTPREP_CONFIG_MANAGED [BOOTPREP_CONFIG_MANAGED ...]]
               [-bm BOOTPREP_CONFIG_MANAGEMENT] [-bpcd BOOTPREP_CONFIG_DIR]
               [-rv RECIPE_VARS] [-um UPDATE_METHOD_MANAGEMENT]
               [-uc UPDATE_METHOD_MANAGED] [-ln LIMIT_NODES [LIMIT_NODES ...]]

optional arguments:
  -h, --help            show this help message and exit
  -b BEGIN_STAGE, --begin-stage BEGIN_STAGE
                        The first stage to execute
  -e END_STAGE, --end-stage END_STAGE
                        The last stage to execute
  -r RUN_STAGES [RUN_STAGES ...], --run-stages RUN_STAGES [RUN_STAGES ...]
                        Run only the specified stages
  -s SKIP_STAGES [SKIP_STAGES ...], --skip-stages SKIP_STAGES [SKIP_STAGES ...]
                        Skip the execution of the specified stages
  -F FORCE, --force FORCE
                        Force re-execution of stage operations.
  -bc BOOTPREP_CONFIG_MANAGED [BOOTPREP_CONFIG_MANAGED ...], --bootprep-config-managed BOOTPREP_CONFIG_MANAGED [BOOTPREP_CONFIG_MANAGED ...]
                        List of `sat bootprep` config files for non-mgmt nodes (compute, UAN).
  -bm BOOTPREP_CONFIG_MANAGEMENT, --bootprep-config-management BOOTPREP_CONFIG_MANAGEMENT
                        List of `sat bootprep` config files for management NCN nodes.
  -bpcd BOOTPREP_CONFIG_DIR, --bootprep-config-dir BOOTPREP_CONFIG_DIR
                        directory containing bootprep configuration files.  The expected layout would be:
                                $(BOOTPREP_CONFIG_DIR)/product_vars.yaml
                                $(BOOTPREP_CONFIG_DIR)/bootprep/compute-and-uan-bootprep.yaml
                                $(BOOTPREP_CONFIG_DIR)/bootprep/management-bootprep.yaml
  -rv RECIPE_VARS, --recipe-vars RECIPE_VARS
                        location of the recipe_vars.yaml file (aka product_vars.yaml), used by `sat bootprep`
  -um UPDATE_METHOD_MANAGEMENT, --update-method-management UPDATE_METHOD_MANAGEMENT
                        Method to update the management nodes.  (rolling) 'reboot' or (rolling) 'in_place' (update running nodes).  Defaults to 'reboot'
  -uc UPDATE_METHOD_MANAGED, --update-method-managed UPDATE_METHOD_MANAGED
                        Method to update the managed nodes.  (rolling) 'reboot' or (rolling) 'in_place' (update running nodes).  Defaults to 'reboot'
  -ln LIMIT_NODES [LIMIT_NODES ...], --limit-nodes LIMIT_NODES [LIMIT_NODES ...]
                        Override list used in rolling stage to assist with repairing broken nodes.
                        For example, --limit-nodes ncn-w003 would cause the rollout stage to only
                        reload ncn-w003;  --limit-nodes x3000c0s37b0n0 would also work.
```

These [examples](examples/iuf_run.md) highlight common use cases of `iuf run`.

#### `abort`

The `abort` subcommand is specified by the administrator to end a paused IUF session instead of attempting to resume or restart it.

The following arguments may be specified when invoking `iuf abort`:

```bash
usage: << TODO >>
```

These [examples](examples/iuf_abort.md) highlight common use cases of `iuf abort`.

#### `resume`

The `resume` subcommand is specified by the administrator to resume a paused IUF session.

The following arguments may be specified when invoking `iuf resume`:

```bash
usage: << TODO >>
```

These [examples](examples/iuf_resume.md) highlight common use cases of `iuf resume`.

#### `restart`

The `restart` subcommand is specified by the administrator to restart a paused IUF session from the beginning of the session. This allows the administrator to make changes to the environment and re-execute the IUF session.

The following arguments may be specified when invoking `iuf restart`:

```bash
usage: << TODO >>
```

These [examples](examples/iuf_restart.md) highlight common use cases of `iuf restart`.

#### `activity`

The `activity` subcommand allows the administrator to create a new activity, display details for an activity, and create, update, and annotate activity states. These operations allow the administrator to easily determine the status of IUF activity operations and associate time-based metrics and user-specified comments with them. 

The activity details displayed are:

| Column         | Description                                                      |
| -------------- | ---------------------------------------------------------------- |
| start          | The time that this operation began execution                     |
| activity state | << TODO >>                                                       |
| IUF sessionid  | The IUF session ID associated with the operation                 |
| Status         | The status of the operation                                      |
| Duration       | How long the operation has been in this state (if not completed) |
| Comment        | User-specified comments associated with the operation            |

The following arguments may be specified when invoking `iuf activity`:

```bash
usage: iuf activity [-h] [--comment COMMENT] [--time TIME] [--create]
                    [--status {Succeeded,Failed,Running,n/a}]
                    [--sessionid SESSIONID]
                    [{in_progress,waiting_admin,paused,debug,blocked,finished}]

positional arguments:
  {in_progress,waiting_admin,paused,debug,blocked,finished}
                        State name

optional arguments:
  -h, --help            show this help message and exit
  --comment COMMENT     Comment for the activitiy state
  --time TIME           Add or edit state at a specific timestamp, defaults to now.
  --create              Create a new activity state
  --status {Succeeded,Failed,Running,n/a}
                        Current status of the state
  --sessionid SESSIONID
                        Argo sessionid.
```

These [examples](examples/iuf_activity.md) highlight common use cases of `iuf activity`.

#### `list-stages`

The `list-stages` subcommand displays the stages for a given activity, the status of each stage, and the time spent in each stage.

The following arguments may be specified when invoking `iuf list-stages`:

```bash
usage: iuf list-stages [-h] [-f FORMAT]

optional arguments:
  -h, --help            show this help message and exit
  -f FORMAT, --format FORMAT
```

These [examples](examples/iuf_list_stages.md) highlight common use cases of `iuf list-stages`.

## Output and Log Files

`iuf` subcommands display status information to standard output as the operations execute. IUF stores more detailed information in log files which are stored on a Ceph Block Device typically mounted at `/etc/cray/upgrade/`. The default log file directory can be overridden with the `iuf -b` and `iuf --log-dir` options (see `iuf -h` for details).

Log files are organized by activity identifiers. The following example shows the log files that exist for the `joe-install-20230107` activity and the session information recorded in an IUF state log file.

(ncn-m001#) Display log files and examine a specific state log file.

```bash
find /opt/cray/iuf/joe-install-20230107/ -type f
/opt/cray/iuf/joe-install-20230107/state/activity_dict.yaml
/opt/cray/iuf/joe-install-20230107/state/stage_hist.yaml
/opt/cray/iuf/joe-install-20230107/log/20230107215823/install.log
/opt/cray/iuf/joe-install-20230107/log/20230107220849/install.log

cat /opt/cray/iuf/joe-install-20230107/state/activity_dict.yaml
joe-install-20230107:
  start: '2023-01-07t21:58:23'
  states:
    '2023-01-07t21:58:25':
      comment: Run process-media
      sessionid: joe-install-20230107u0sil-process-media-8lqms
      state: in_progress
      status: n/a
    '2023-01-07t22:00:00':
      comment: null
      sessionid: null
      state: waiting_admin
      status: n/a
```

## Site and Recipe Variables

IUF site and recipe variables allow the administrator to customize product, product version, and branch values used by IUF
when executing IUF stages. They ensure automated VCS branch merging, CFS configuration creation, and IMS image creation
operations are performed with values adhering to site preferences.

Site variables are typically defined in a `site_vars.yaml` file created by the site administrator. The HPC CSM Software Recipe
provides a default recipe variables file named `product_vars.yaml`. The recipe variable file allows HPE to provide default
variables and values while the recipe variable file allows the administrator to extend or override the variables and values.
If both files are used and specific variables are defined in both files, the values specified in the site variable file takes
precedence.

The `iuf run` subcommand has arguments that allow the administrator to reference the site and/or recipe variable files. The
variables specified in the files are used by IUF when executing the `update-vcs-config`, `update-cfs-config`, and `prepare-images`
stages. For example, the `working_branch` variable defines the naming convention used by IUF to find or create a product's VCS branch
containing site-customized configuration content, which happens as part of the `update-vcs-config` stage.
 
## Product Workflows

<< TODO >>
