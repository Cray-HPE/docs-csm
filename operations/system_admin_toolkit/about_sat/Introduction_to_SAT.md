# Introduction to SAT

The System Admin Toolkit (SAT) is designed to assist administrators with common tasks, such as
troubleshooting and querying information about the HPE Cray EX System and its components, system
boot and shutdown, and replacing hardware components.

## SAT Command-Line Utility

The System Admin Toolkit (SAT) provides a command-line utility called `sat` that runs from
Kubernetes control plane nodes (NCNs). The `sat` command-line utility is organized into
multiple subcommands that perform different administrative tasks. For example, `sat status`
provides a summary of the system component statuses while `sat bootprep` provides a way to
create CFS configurations, IMS images, and session templates to prepare for booting the system. For
more information on the available SAT commands, see [SAT Command Overview](SAT_Command_Overview.md).

Most `sat` subcommands depend on services or components from other products in the HPE Cray EX
software stack. For more information, see [SAT Dependencies](SAT_Dependencies.md).

In CSM 1.3 and newer, the `sat` command is automatically available on all the Kubernetes control
plane nodes. For more information, see [SAT in CSM](SAT_in_CSM.md). Older versions of CSM do not
have the `sat` command automatically available, and SAT must be installed as a separate product.

## SAT Container Environment

On Kubernetes control plane nodes, the `sat` command-line utility runs within a container using
Podman, a daemonless container runtime. There are two options for running the `sat` command-line
utility, interactive mode and non-interactive mode. In both options, a container is launched in the
background to execute the command. It is important to note that:

- Using either the interactive mode with `sat bash` or the non-interactive mode with `sat` always
  launches a container.
- The SAT container does not have access to the NCN file system.

### SAT Interactive Mode

The SAT interactive mode involves executing `sat bash` to launch a container before executing the
`sat` command. This option launches an interactive shell in which to enter `sat` commands. The
interactive mode is useful for:

- Allowing read and write access to local files on ephemeral container storage.
- Saving time when using successive `sat` commands because a new container does not need to launch
  for each command.

To check a system's status using the interactive mode:

1. (`ncn-m001#`) Use `sat bash` to launch an interactive shell.

   ```bash
   sat bash
   ```

1. (`(CONTAINER_ID) sat-container#`) Use `sat status` to review the status of the system's components.

   ```bash
   sat status
   ```

### SAT Non-Interactive Mode

The SAT non-interactive mode involves executing the `sat` command directly on a Kubernetes control
plane node. This option launches a container, executes the `sat` command, and exits the container
once the command completes. The non-interactive mode is useful for:

- Calling `sat` with a script.
- Running a single `sat` command as part of several steps that need to be executed from a management
  NCN.

To check a system's status using the non-interactive mode:

(`ncn-m001#`) Use `sat status` to review the status of the system's components.

```bash
sat status
```

### SAT Container Environment Man Page

To view the man page describing the SAT container environment, use either `man sat` or `man sat-podman`
on the Kubernetes control plane nodes.

**NOTE:** Only the man page for the SAT container environment is available with `man sat` and
`man sat podman`. To view man pages for the actual `sat` commands used to perform system administration
tasks, see [SAT Man Pages](#sat-man-pages).

For example:

- (`ncn-m#`) View the man page for the SAT container environment using its short name.

  ```bash
  man sat
  ```

- (`ncn-m#`) View the man page for the SAT container environment using its long name.

  ```bash
  man sat-podman
  ```

## SAT Man Pages

The top-level `sat` man page describes the command-line interface, documents the global options
affecting all subcommands, documents configuration file options, and refers to the man pages for
each subcommand. Each individual `sat` subcommand also has a man page describing its options.

To view `sat` man pages when running SAT commands in interactive mode, use `man`. To view `sat`
man pages when running SAT commands in non-interactive mode, use `sat-man`. For more information
on interactive and non-interactive mode, see [SAT Container Environment](#sat-container-environment).

For example, in SAT interactive mode:

- (`(CONTAINER_ID) sat-container#`) View the top-level `sat` man page.

  ```bash
  man sat
  ```

- (`(CONTAINER_ID) sat-container#`) View the man page for the `sat status` subcommand.

  ```bash
  man sat-status
  ```

For example, in SAT non-interactive mode:

- (`ncn-m#`) View the top-level `sat` man page.

  ```bash
  sat-man sat
  ```

- (`ncn-m#`) View the man page for the `sat status` subcommand.

  ```bash
  sat-man sat-status
  ```
