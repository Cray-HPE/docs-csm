# CRAY Guide Contribution

The documentation included here describes how to install the CSM software and various supporting administrative procedures.
See [Guides](001-GUIDES.md) for the different scenarios to which this documentation can apply for installation.

The rest of this page describes the conventions used in the documentation:
* [Page naming or indexing] (#page-indexing) conventions 
* [Annotations] (#annotations) for how we identify sections of the documention that do not apply to all systems 
* [Command Prompt Conventions] (#command-prompt-conventions) which describe the context for user, host, directory, chroot environment, or container environment

<a name="page-indexing"></a>
# Page Indexing / Naming

The page name can be anything. This repo has a loose pattern to assist tab-completion and contextual
heuristics:

    [XYZ]-[context]-[memo].md

Examples:
* `006-CSM-PLATFORM-INSTALL.md`
* `250-FIRMWARE-NODE.md`
* `407-MGMT-NET-SNMP-CONFIG.md`

<a name="annotations"></a>
# Annotations

This repository may change annotations, for now under the MarkDown governance these are the available annotations.

**You must use these to denote the right steps to the right audience.**

These are context clues for steps, if they contain these, and you are not in that context you ought to skip them.

> **`AIRGAP/OFFLINE USE`**

This tag should preface any block that is for offline install steps or procedures, where there is 
no online/internet connection.

> **`EXTERNAL USE`** 

This tag should be used to highlight anything that an internal user should ignore or skip.

> **`INTERNAL USE`** 

This tag should be used before any block of instruction or text that is only usable or recommended for 
internal HPE CRAY systems.

External (GitHub or customer) should disregard these annotated blocks - they maybe contain useful
information as an example but are not intended for their use.

> **`PREFERRED`** 

This is the preferred path, but if not possible, there will be a MANUAL section which can be done instead

> **`MANUAL`** 

This is a manual path that can be taken if the PREFERRED section is not possible in the given context.

<a name="command-prompt-conventions"></a>
# Command Prompt Conventions

## Host name and account in command prompts

The host name in a command prompt indicates where the command must be run.  The account that must run the command is also indicated in the prompt.
- The root or super-user account always has the # character at the end of the prompt
- Any non-root account is indicated with account@hostname>.  A non-privileged account is referred to as user.

## Node abbreviations
The following list conatins abbrev iations for nodes used below

* CN - compute Node
* NCN - Non Compute Node
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
| linux# | Run the command as root on a linux host. |
| uan# | Run the command as root on any UAN. |
| uan01# | Run the command as root on any UAN. |
| user@uan> | Run the command as any non-root user on any UAN. |
| cn# | Run the command as root on any CN.  Note that a CN will have a hostname of the form nid124356, that is "nid" and a six digit, zero padded number. |
| hostname# | Run the command as root on the specified hostname. |
| user@hostname> | Run the command as any non-root user son the specified hostname. |

## Command prompt inside chroot

If the chroot command is used, the prompt changes to indicate
that it is inside a chroot environment on the system.

```bash
hostname# chroot /path/to/chroot
chroot-hostname#

```

## Command prompt inside Kubernetes pod

If executing a shell inside a container of a Kubernetes pod where
the pod name is $podName, the prompt changes to indicate that it
is inside the pod. Not all shells are available within every pod, this
is an example using a commonly available shell.

```bash
ncn# kubectl exec -it $podName /bin/sh
pod#
```

## Command prompt inside image customization session

If using ssh during an image customization session, the prompt
changes to indicate that it is inside the image customization
environment (pod). This example uses $PORT and $HOST as
environment variables with specific settings. When using chroot in
this context the prompt will be different than the above chroot
example.

```bash
hostname# ssh -p $PORT root@$HOST
root@POD# chroot /mnt/image/image-root
:/#
```

## Directory path in command prompt

Example prompts do not include the directory path, because long
paths can reduce the clarity of examples. Most of the time, the
command can be executed from any directory. When it matters
which directory the command is invoked within, the cd command
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

## Commmand prompts for network switch configuration

The prompts when doing network swtich configuration can vary widely
depending on which vendor switch is being configured and the context
of the item being configured on that switch.  There may be two levels
of user privilege which have different commands available and a
special command to enter configuration mode.

Example of prompts as they appear in this publication:

Enter "setup" mode for the switch make and model, for example:
```bash
remote# ssh sw-leaf-001
sw-leaf-001>  enable
sw-leaf-001#  configure terminal
sw-leaf-001(conf)# 
```

Refer to the switch vendor OEM documentation for more information about configuring a specific switch. 

