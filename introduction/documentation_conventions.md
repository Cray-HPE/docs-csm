# Documentation Conventions

Several conventions have been used in the preparation of this documentation.

- [Markdown Format](#markdown-format)
- [File Formats](#file-formats)
- [Typographic Conventions](#typographic-conventions)
- [Command Prompt Conventions](#command-prompt-conventions)
    - [Host Name and Account in Command Prompts](#host-name-and-account-in-command-prompts)
    - [Node Abbreviations](#node-abbreviations)
    - [Using Prompts](#using-prompts-inside-of-directions)
    - [Context Badges](#context-badges-table-reference)
    - [Step Examples](#step-examples)

## Markdown Format

This documentation is in Markdown format. Although much of it can be viewed with any text editor,
a richer experience will come from using a tool which can render the Markdown to show different font
sizes, the use of bold and italics formatting, inclusion of diagrams and screen shots as image files,
and to follow navigational links within a topic file and to other files.

There are many tools which render the Markdown format and provide these advantages. Any Internet search
for Markdown tools will provide a long list of these tools. Some of the tools are better than others
at displaying the images and allowing you to follow the navigational links.

## File Formats

Some of the installation instructions require updating files in JSON, YAML, or TOML format. These files should be updated with care because some file formats do not accept tab characters for indentation of lines. Only space characters are supported. Refer to online documentation to learn more about the syntax of JSON, YAML, and TOML files. YAML does not support tab characters. The JSON *convention* is to use four spaces rather than a tab character.

## Typographic Conventions

`This style` indicates program code, reserved words, library functions, command-line prompts,
screen output, file/path names, and other software constructs.

\ (backslash) At the end of a command line, indicates the Linux shell line continuation character
(lines joined by a backslash are parsed as a single line).

## Command Prompt Conventions

### Host name and account in command prompts

The host name in a command prompt indicates where the command must be run. The account that must run the command is also indicated in the prompt.
- The root or super-user account always has the # character at the end of the prompt
- Any non-root account is indicated with `account@hostname`. A non-privileged account is referred to as user.

### Node abbreviations

The following list contains abbreviations for nodes used below

* CN - compute Node
* NCN - Non-Compute Node
* AN - Application Node (special type of NCN)
* UAN - User Access Node (special type of AN)
* PIT - Pre-Install Toolkit (initial node used as the inception node during software installation booted from the LiveCD)

### Using Prompts inside of Directions

These prompts should be inserted _into_ the step as such:

> 1. (`ncn#`) Lorem ipsom
> 
>     ```bash
>     yes >/dev/null
>     ```
> 
> 2. (`ncn#`) Lorem ipsom

##### Context Badges Table Reference

This list of tags denote the common, accepted tags to denote context.

| Prompt | Description |
|:------|:------------|
| (` ncn# `) | Run the command as root on any NCN, except an NCN which is functioning as an Application Node (AN), such as a UAN. |
| (` ncn-m# `) | Run the command as root on any NCN-M (NCN which is a Kubernetes master node).|
| (` ncn-m002# `) | Run the command as root on the specific NCN-M (NCN which is a Kubernetes master node) which has this hostname (ncn-m002). |
| (` ncn-w# `) | Run the command as root on any NCN-W (NCN which is a Kubernetes worker node).|
| (` ncn-w001# `) | Run the command as root on the specific NCN-W (NCN which is a Kubernetes master node) which has this hostname (ncn-w001). |
| (` ncn-s# `) | Run the command as root on any NCN-S (NCN which is a Utility Storage node).|
| (` ncn-s003# `) | Run the command as root on the specific NCN-S (NCN which is a Utility Storage node) which has this hostname (ncn-s003).  |
| (` pit# `) | Run the command as root on the PIT node. |
| (` external# `) | Run the command as root on a Linux host external to the supercomputer. |
| (` uan# `) | Run the command as root on any UAN. |
| (` uan01# `) | Run the command as root on hostname uan01. |
| (`user@uan>`) | Run the command as any non-root user on any UAN. |
| (` cn# `) | Run the command as root on any CN. Note that a CN will have a hostname of the form nid124356, that is "nid" and a six digit, zero padded number. |
| (` hostname# `) | Run the command as root on the specified hostname. |
| (`user@hostname>`) | Run the command as any non-root user on the specified hostname. |

### Step Examples

#### Command prompt inside chroot

If the chroot command is used, the prompt changes to indicate
that it is inside a chroot environment on the system.

1. (`hostname#`) Lorem ipsom

    ```bash
    chroot /path/to/chroot
    ```

1. (`chroot-hostname#`) Lorem ipsom 

    ```bash
    whoami
    ```

1. (`chroot-hostname#`) Lorem ipsom

    ```bash
    exit 
    ```

1. (`hostname#`) Lorem ipsom!

#### Command prompt inside Kubernetes pod

If executing a shell inside a container of a Kubernetes pod where
the pod name is $podName, the prompt changes to indicate that it
is inside the pod. Not all shells are available within every pod, this
is an example using a commonly available shell.


1. (`ncn#`) Enter pod `$podName`

    ```bash
    kubectl exec -it $podName /bin/sh
    ```

1. (`pod#`) Run foo in the pod

    ```bash
    . /srv/foo && echo $bar
    ```

#### Command prompt inside image customization session

If using SSH to access the image customization environment (pod)
during an image customization session, the prompt
changes to indicate that it is inside this environment.
This example uses $PORT and $HOST as
environment variables with specific settings. When using chroot in
this context, the prompt will be different than the above chroot
example.


1. (`hostname#`) Login to the image pod ...

    ```bash
    ssh -p $PORT root@$HOST
    ```

1. (`root@POD#`) Chroot into the image ...

    ```bash
    chroot /mnt/image/image-root
    ```

1. (`:/#`) Checkout the beard on this emoji ...

    ```bash
    echo $PS1
    ```

#### Directory path in command prompt

Example prompts do not include the directory path, because long
paths can reduce the clarity of examples. Most of the time, the
command can be executed from any directory. When it matters
which directory the command is invoked within, the **cd** command
is used to change into the directory, and the directory is referenced
with a period (.) to indicate the current directory. **It is important** 
to format steps in a manner such that one always changes into the right
directory. This means, for example, if a user is resuming a procedure 
on a page that page should have resume/pickup spots that ensure a user
changes directory.


Here is an example that lends a user to make mistakes if they are resuming from a short or long break.

```markdown
# Bad Example

This is a bad example where the context switches and a user can't resume half-way without running
commands in the wrong directory.

1. Change into a directory

1. Do more things

1. Do more things

1. Do more things

1. Do even more things

1. Change into another directory

1. Do more things

1. Do more things

1. Do even more things

1. Return to the original directory

1. Do more things

1. Do more things

1. Do even more things
```

Here is an example that combats the above example's problems by offering shorter, resumable stretches of steps.

```markdown
# Good Example

This is a good example where every context switch is under a header, allowing users to resume via a 
URL without loosing context for their step's code-snippets.

### Do A Few Things

1. Change into a directory

1. Do more things

1. Do more things

1. Do more things

1. Do even more things

### Do Some Other Cool Things

1. Change into another directory

1. Do more things

1. Do more things

1. Do even more things

### After Doing a Few Things and Other Cool Things Then Start The Final Things

If the user has not completed some other cool things, they should see 
[do some other cool things](#do-some-other-cool-things) before proceeding with these steps.

1. Return to the original directory

1. Do more things

1. Do more things

1. Do even more things
```

The "good" example not only breaks the numerous steps into smaller sections, but a user may return
or start at any subsection without running commands in the wrong directory. Additionally one may
add notices if a section depends on another (e.g. steps 9-12 are in directory Y but require a user
to at least have completed steps 5-8 in directory X).

> **`NOTE`** Shorter headers are recommended than the long ones in the examples.

