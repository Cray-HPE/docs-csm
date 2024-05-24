# Introduction to SAT

## About System Admin Toolkit (SAT)

The System Admin Toolkit (SAT) is designed to assist administrators with common tasks, such as
troubleshooting and querying information about the HPE Cray EX System and its components, system
boot and shutdown, and replacing hardware components.

### SAT Command Line Utility

The System Admin Toolkit (SAT) provides a command-line utility called `sat` that can be run from
Kubernetes control plane nodes (`ncn-m` nodes). The `sat` command-line utility is organized into
multiple subcommands that perform different administrative tasks. For example, `sat status` provides
a summary of the status of the components in the system while `sat bootprep` provides a way to
create CFS configurations, IMS images, and session templates to prepare for booting the system. For
more information on the available SAT commands, see [SAT Command Overview](SAT_Command_Overview.md).
Most `sat` subcommands depend on services or components from other products in the HPE Cray EX software stack.
For more details, refer to the [SAT Dependencies](SAT_Dependencies.md).

In CSM 1.3 and newer, the `sat` command is automatically available on all the Kubernetes control
plane nodes. For more information, see [SAT in CSM](SAT_in_CSM.md). Older versions of CSM do not
have the `sat` command automatically available, and SAT must be installed as a separate product.

### SAT Container Environment

The `sat` command-line utility runs in a container using Podman, a daemonless container runtime. SAT
runs on Kubernetes control plane nodes. A few important points about the SAT container environment
include the following:

- Using either `sat` or `sat bash` always launches a container.
- The SAT container does not have access to the NCN file system.

There are two ways to run `sat`.

- **Interactive**: Launching a container using `sat bash`, followed by a `sat` command.
- **Non-interactive**: Running a `sat` command directly on a Kubernetes control plane node.

In both of these cases, a container is launched in the background to execute the command. The first
option, running `sat bash` first, gives an interactive shell, at which point `sat` commands can be
run. In the second option, the container is launched, executes the command, and upon the command's
completion the container exits. The following two examples show the same action, checking the system
status, using both modes.

(`ncn-m001#`) Here is an example using interactive mode:

```bash
sat bash
```

(`(CONTAINER_ID) sat-container#`) Example `sat` command after a container is launched:

```bash
sat status
```

(`ncn-m001#`) Here is an example using non-interactive mode:

```bash
sat status
```

#### Interactive Advantages

Running `sat` using the interactive command prompt gives the ability to read and write local files
on ephemeral container storage. If multiple `sat` commands are being run in succession, use `sat
bash` to launch the container beforehand. This will save time because the container does not need to
be launched for each `sat` command.

#### Non-interactive Advantages

The non-interactive mode is useful if calling `sat` with a script, or when running a single `sat`
command as a part of several steps that need to be executed from a management NCN.

#### SAT Container Environment Man Page

A man page describing the SAT container environment is available on the Kubernetes control plane
nodes, which can be viewed either with `man sat` or man `sat-podman` from the manager node.

Note that this is only the man page for the SAT container environment, not for the actual `sat`
commands which can be used to perform system administration tasks. See
[SAT Man Pages](#sat-man-pages) for instructions on accessing those man pages.

Either of the following options work to view the man page for the SAT container environment.

- (`ncn-m#`) View the man page for the SAT container environment:

  ```bash
  man sat
  ```

- (`ncn-m#`) View the man page for the SAT container environment using its long name:

  ```bash
  man sat-podman
  ```

### SAT Man Pages

To view a `sat` man page from a Kubernetes control plane node, use `sat-man` on the manager node or
use `man` within a shell in the SAT container started by `sat bash`.

The top-level `sat` man page describes the command-line interface, documents the global options
affecting all subcommands, documents configuration file options, and refers to the man pages for
each subcommand. Each of these subcommands have their own options documented in their individual man
pages.

See the following examples showing how to view `sat` man pages directly on a manager node using
`sat-man`.

- (`ncn-m#`) View the top-level `sat` man page:

  ```bash
  sat-man sat
  ```

- (`ncn-m#`) View the man page for the `sat status` subcommand:

  ```bash
  sat-man sat-status
  ```

See the following examples showing how to view `sat` man pages within the shell in the SAT container
started by `sat bash`.

- (`(CONTAINER_ID) sat-container#`) View the top-level `sat` man page:

  ```bash
  man sat
  ```

- (`(CONTAINER_ID) sat-container#`) View the man page for the `sat status` subcommand:

  ```bash
  man sat-status
  ```
