# Documentation Conventions

This outlines conventions and standards that are used in this documentation.

- [Markdown format](#markdown-format)
- [File formats](#file-formats)
- [Typographic conventions](#typographic-conventions)
- [Command prompt conventions](#command-prompt-conventions)
    - [Host and user name in command prompts](#host-and-user-name-in-command-prompts)
    - [Node abbreviations](#node-abbreviations)
    - [Command prompt reference](#command-prompt-reference)
    - [Command prompt location](#command-prompt-location)
    - [Command prompts inside new shells](#command-prompts-inside-new-shells)
        - [`chroot` example](#chroot-example)
        - [`kubectl exec` example](#kubectl-exec-example)
        - [Combined `ssh` and `chroot` example](#combined-ssh-and-chroot-example)
        - [`sat bash` example](#sat-bash-example)
    - [Command prompts in Python virtual environments](#command-prompts-in-python-virtual-environments)
    - [Directory path in command prompt](#directory-path-in-command-prompt)
- [Ability to pause and resume procedures](#ability-to-pause-and-resume-procedures)
    - [Bad example](#bad-example)
    - [Good example](#good-example)
- [Templates](#templates)

## Markdown format

This documentation is in Markdown format. Although much of it can be viewed with any text editor,
a richer experience will come from using a tool which can render the Markdown to show different font
sizes, the use of bold and italics formatting, inclusion of diagrams and screen shots as image files,
and to follow navigational links within a topic file and to other files.

There are many tools which render the Markdown format and provide these advantages. Any Internet search
for Markdown tools will provide a long list of these tools. Some of the tools are better than others
at displaying the images and allowing you to follow the navigational links.

## File formats

Some of the installation instructions require updating files in JSON, YAML, or TOML format. These files should be updated with care because some file formats do not accept tab
characters for indentation of lines. Refer to online documentation to learn more about the syntax of JSON, YAML, and TOML files. YAML does not support tab characters. The convention
for JSON is to use four spaces rather than a tab character.

## Typographic conventions

`This style` indicates program code, reserved words, library functions, command-line prompts,
screen output, file/path names, and other software constructs.

\ (backslash) At the end of a command line, indicates the Linux shell line continuation character
(lines joined by a backslash are parsed as a single line).

## Command prompt conventions

### Host and user name in command prompts

The host name in a command prompt indicates where the command must be run. The user account that must run the command is also indicated in the prompt.

- The `root` or super-user account always has the # character at the end of the prompt.
- Any non-root account is indicated with `account@hostname`. A non-privileged account is referred to as user.

### Node abbreviations

The following list contains abbreviations for nodes used below:

- CN - Compute Node
- NCN - Non-Compute Node
    - `ncn-m` - Master NCN
    - `ncn-s` - Storage NCN
    - `ncn-w` - Worker NCN
    - These can also be used in combination. For example, `ncn-mw` in a command prompt indicates that the command may be run on a master or worker NCN.
- AN - Application Node (special type of NCN)
- UAN - User Access Node (special type of AN)
- PIT - Pre-Install Toolkit (initial node used as the inception node during software installation, booted from the LiveCD)

### Command prompt reference

This lists the common command prompts and their meanings.

| Prompt           | Description                                                                                                                                                   |
|:-----------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `ncn#`           | Run the command as `root` on any NCN, except an NCN which is functioning as an Application Node, such as a UAN.                                               |
| `ncn-m#`         | Run the command as `root` on any Kubernetes master NCN.                                                                                                       |
| `ncn-m002#`      | Run the command as `root` on the specific Kubernetes master NCN which has this hostname (`ncn-m002` in this example).                                         |
| `ncn-s#`         | Run the command as `root` on any utility storage NCN.                                                                                                         |
| `ncn-s003#`      | Run the command as `root` on the specific utility storage NCN which has this hostname (`ncn-s003` in this example).                                           |
| `ncn-w#`         | Run the command as `root` on any Kubernetes worker NCN.                                                                                                       |
| `ncn-w001#`      | Run the command as `root` on the specific Kubernetes worker NCN which has this hostname (`ncn-w001` in this example).                                         |
| `ncn-mw#`        | Run the command as `root` on any Kubernetes master or worker NCN.                                                                                             |
| `ncn-ms#`        | Run the command as `root` on any Kubernetes master or utility storage NCN.                                                                                    |
| `pit#`           | Run the command as `root` on the PIT node.                                                                                                                    |
| `external#`      | Run the command as `root` on a Linux host external to the supercomputer.                                                                                      |
| `uan#`           | Run the command as `root` on any UAN.                                                                                                                         |
| `uan01#`         | Run the command as `root` on hostname `uan01`.                                                                                                                |
| `user@uan>`      | Run the command as any non-`root` user on any UAN.                                                                                                            |
| `cn#`            | Run the command as `root` on any CN. Note that a CN will have a hostname of the form `nid124356`. That is, `nid` followed by a six digit, zero padded number. |
| `hostname#`      | Run the command as `root` on the specified hostname.                                                                                                          |
| `user@hostname>` | Run the command as any non-`root` user on the specified hostname.                                                                                             |

### Command prompt location

These prompts should be inserted into text **before** the fenced code block, rather than inside of it. This is a change from
the documentation of CSM 1.2 and earlier.

- An example of proper use of the command prompt:

    1. (`ncn#`) Lorem ipsum.

         ```bash
         yes >/dev/null
         ```

- An example of improper use of the command prompt:

    1. Lorem ipsum.

         ```bash
         ncn# yes >/dev/null
         ```

### Command prompts inside new shells

Some commands open new shells when they are executed (for example, `chroot`, `kubectl exec`, `ssh`,
and `sat bash`). When these commands are used, the command prompt changes to indicate that subsequent
commands are to be run inside the new shell.

#### `chroot` example

1. (`hostname#`) Lorem ipsum.

    ```bash
    chroot /path/to/chroot
    ```

1. (`chroot-hostname#`) Lorem ipsum.

    ```bash
    whoami
    ```

1. (`chroot-hostname#`) Lorem ipsum.

    ```bash
    exit 
    ```

1. (`hostname#`) Lorem ipsum!

#### `kubectl exec` example

If executing a shell inside a container of a Kubernetes pod where the pod name is `$podName`:

1. (`ncn#`) Enter pod `$podName`.

    ```bash
    kubectl exec -it $podName /bin/sh
    ```

1. (`pod#`) Run foo in the pod.

    ```bash
    . /srv/foo && echo $bar
    ```

#### Combined `ssh` and `chroot` example

If using SSH to access the image customization environment (a Kubernetes pod) during an image customization session, then the prompt
changes to indicate that it is inside this environment. This example uses `$PORT` and `$HOST` as environment variables with specific settings.

1. (`hostname#`) Login to the image pod.

    ```bash
    ssh -p $PORT root@$HOST
    ```

1. (`pod#`) `chroot` into the image.

    ```bash
    chroot /mnt/image/image-root
    ```

1. (`chroot-pod#`) Checkout the beard on this emoji.

    ```bash
    echo $PS1
    ```

#### `sat bash` example

The `sat bash` command opens a shell inside the `cray-sat` container image. The command prompt changes
to indicate the ID of the Podman container where the shell is executing.

1. (`ncn-m#`) Enter a SAT shell.

   ```bash
   sat bash
   ```

1. (`(CONTAINER_ID) sat-container#`) Execute the `sat status` command inside the shell in the
   `cray-sat` container started by `sat bash`.

   ```bash
   sat status
   ```

### Command prompts in Python virtual environments

Some documentation may involve running commands inside a Python virtual environment. When a Python
virtual environment is activated, the command prompt changes to reflect the active virtual
environment.

1. (`user@hostname>`) Activate the Python virtual environment.

   ```bash
   . venv/bin/activate
   ```

1. (`(venv) user@hostname>`) Open the Python 3 interpreter inside the virtual environment.

   ```bash
   python3
   ```

### Directory path in command prompt

Example prompts do not include the directory path, because long paths can reduce the clarity of examples. Most of the time, the
command can be executed from any directory. When it matters which directory the command is invoked within, the `cd` command
is used to change into the directory, and the directory is referenced with a period (.) to indicate the current directory.

## Ability to pause and resume procedures

In procedures which take a long time, which involve a large number of steps, or which span different pages, the documentation
should take care to help avoid errors caused by a user pausing the procedure and resuming it at a later time. In the intervening
time they may have opened a new shell, or run other commands in the same shell.

For commands that need specific environment variables to be set, or to be run in a specific directory, it is important to do one
of the following things:

1. Ensure that the directory change or variable assignment happens within the step itself, or in the immediately previous step.
1. Provide a ***bold warning statement*** stating the required directory or variables.

### Bad example

Here is an example that makes it easy for a user to make mistakes if they are resuming from a short or long break.
The context switches and a user cannot resume halfway without running commands in the wrong directory.

1. Change into a directory.

1. Do more things.

1. Do more things.

1. Do more things.

1. Do even more things.

1. Change into another directory.

1. Do more things.

1. Do more things.

1. Do even more things.

1. Return to the original directory.

1. Do more things.

1. Do more things.

1. Do even more things.

### Good example

Here is an example that addresses the problems in the previous example by using shorter stretches of steps that are
more easily paused and resumed. Note that every context switch is under a header, offering users a good place to pause
without losing context.

#### Do a few things

1. Change into a directory.

1. Do more things.

1. Do more things.

1. Do more things.

1. Do even more things.

#### Other cool things

1. Change into another directory.

1. Do more things.

1. Do more things.

1. Do even more things.

#### Final things

The steps in this section require that the [Other cool things](#other-cool-things) section has been completed successfully.

1. Return to the original directory.

1. Do more things.

1. Do more things.

1. Do even more things.

## Templates

The `introduction/templates` folder supplies copy-paste boilerplate markdown examples.
