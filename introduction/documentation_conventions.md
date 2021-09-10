# Documentation Conventions

Several conventions have been used in the preparation of this documentation.

   * [Markdown Format](#markdown-format)
   * [File Formats](#file-formats)
   * [Typographic Conventions](#typographic-conventions)
   * [Command Prompt Conventions](#command-prompt-conventions) which describe the context for user, host, directory, chroot environment, or container environment

<a name="markdown-format"></a>
## Markdown Format

This documentation is in Markdown format. Although much of it can be viewed with any text editor,
a richer experience will come from using a tool which can render the Markdown to show different font
sizes, the use of bold and italics formatting, inclusion of diagrams and screen shots as image files,
and to follow navigational links within a topic file and to other files.

There are many tools which render the Markdown format and provide these advantages. Any Internet search
for Markdown tools will provide a long list of these tools. Some of the tools are better than others
at displaying the images and allowing you to follow the navigational links.

<a name="file-formats"></a>
## File Formats

Some of the installation instructions require updating files in JSON, YAML, or TOML format. These files should be updated with care because some file formats do not accept tab characters for indentation of lines. Only space characters are supported. Refer to online documentation to learn more about the syntax of JSON, YAML, and TOML files. YAML does not support tab characters. The JSON *convention* is to use four spaces rather than a tab character.

<a name="typographic-conventions"></a>
## Typographic Conventions

`This style` indicates program code, reserved words, library functions, command-line prompts,
screen output, file/path names, and other software constructs.

\ (backslash) At the end of a command line, indicates the Linux shell line continuation character
(lines joined by a backslash are parsed as a single line).

<a name="command-prompt-conventions"></a>
## Command Prompt Conventions

#### Host name and account in command prompts

The host name in a command prompt indicates where the command must be run. The account that must run the command is also indicated in the prompt.
- The root or super-user account always has the # character at the end of the prompt
- Any non-root account is indicated with account@hostname>. A non-privileged account is referred to as user.

#### Node abbreviations
The following list contains abbreviations for nodes used below

* CN - compute Node
* NCN - Non-Compute Node
* AN - Application Node (special type of NCN)
* UAN - User Access Node (special type of AN)
* PIT - Pre-Install Toolkit (initial node used as the inception node during software installation booted from the LiveCD)

| Prompt | Description |
| ------ | ----------- |
| ncn# | Run the command as root on any NCN, except an NCN which is functioning as an Application Node (AN), such as a UAN. |
| ncn-m# | Run the command as root on any NCN-M (NCN which is a Kubernetes master node).|
| ncn-m002# | Run the command as root on the specific NCN-M (NCN which is a Kubernetes master node) which has this hostname (ncn-m002). |
| ncn-w# | Run the command as root on any NCN-W (NCN which is a Kubernetes worker node).|
| ncn-w001# | Run the command as root on the specific NCN-W (NCN which is a Kubernetes master node) which has this hostname (ncn-w001). |
| ncn-s# | Run the command as root on any NCN-S (NCN which is a Utility Storage node).|
| ncn-s003# | Run the command as root on the specific NCN-S (NCN which is a Utility Storage node) which has this hostname (ncn-s003). |
| pit# | Run the command as root on the PIT node. |
| linux# | Run the command as root on a Linux host. |
| uan# | Run the command as root on any UAN. |
| uan01# | Run the command as root on hostname uan01. |
| user@uan> | Run the command as any non-root user on any UAN. |
| cn# | Run the command as root on any CN. Note that a CN will have a hostname of the form nid124356, that is "nid" and a six digit, zero padded number. |
| hostname# | Run the command as root on the specified hostname. |
| user@hostname> | Run the command as any non-root user on the specified hostname. |

#### Command prompt inside chroot

If the chroot command is used, the prompt changes to indicate
that it is inside a chroot environment on the system.

```bash
hostname# chroot /path/to/chroot
chroot-hostname#

```

#### Command prompt inside Kubernetes pod

If executing a shell inside a container of a Kubernetes pod where
the pod name is $podName, the prompt changes to indicate that it
is inside the pod. Not all shells are available within every pod, this
is an example using a commonly available shell.

```bash
ncn# kubectl exec -it $podName /bin/sh
pod#
```

#### Command prompt inside image customization session

If using SSH to access the image customization environment (pod)
during an image customization session, the prompt
changes to indicate that it is inside this environment.
This example uses $PORT and $HOST as
environment variables with specific settings. When using chroot in
this context, the prompt will be different than the above chroot
example.

```bash
hostname# ssh -p $PORT root@$HOST
root@POD# chroot /mnt/image/image-root
:/#
```

#### Directory path in command prompt

Example prompts do not include the directory path, because long
paths can reduce the clarity of examples. Most of the time, the
command can be executed from any directory. When it matters
which directory the command is invoked within, the **cd** command
is used to change into the directory, and the directory is referenced
with a period (.) to indicate the current directory

Examples of prompts as they appear on the system:

```bash
hostname:~ # cd /etc
hostname:/etc# cd /var/tmp
hostname:/var/tmp# ls ./file
hostname:/var/tmp# su - user
user@hostname:~> cd /usr/bin
user hostname:/usr/bin> ./command
```

Examples of prompts as they appear in this publication:

```bash
hostname # cd /etc
hostname # cd /var/tmp
hostname # ls ./file
hostname # su - user
user@hostname > cd /usr/bin
user@hostname > ./command
```

#### Command prompts for network switch configuration

The prompts when doing network switch configuration can vary widely
depending on which vendor switch is being configured and the context
of the item being configured on that switch. There may be two levels
of user privilege which have different commands available and a
special command to enter configuration mode.

Example of prompts as they appear in this publication:

Enter "setup" mode for the switch make and model, for example:
```bash
remote# ssh admin@sw-leaf-001
sw-leaf-001>  enable
sw-leaf-001#  configure terminal
sw-leaf-001(conf)#
```

Refer to the switch vendor OEM documentation for more information about configuring a specific switch.

