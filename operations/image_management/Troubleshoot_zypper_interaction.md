# Troubleshoot Interactions with zypper

There are some common problems while interacting with the zypper install utility that can be easily resolved.

## Prerequisites

This page requires interactive access to the image being worked with.

## Error: "Cannot read input: bad stream or EOF"

If the image being customized was not saved out correctly, `/dev/tty1` may not have been set up
correctly. That will result in an error similar to the following when attempting to install
packages using zypper:

```text
warning: Found NDB Packages.db database while attempting bdb backend: using ndb backend.
warning: Found NDB Packages.db database while attempting bdb backend: using ndb backend.
warning: Found NDB Packages.db database while attempting bdb backend: using ndb backend.
Loading repository data...
Reading installed packages...
warning: Found NDB Packages.db database while attempting bdb backend: using ndb backend.
Resolving package dependencies...

The following 8 NEW packages are going to be installed:
emacs emacs-info emacs-nox etags libgpm2 libjansson4 liblcms2-2 system-user-games

8 new packages to install.
Overall download size: 23.2 MiB. Already cached: 0 B. After the operation, additional 91.9 MiB will be used.
Continue? [y/n/v/...? shows all options] (y): Cannot read input: bad stream or EOF.
If you run zypper without a terminal, use '--non-interactive' global
option to make zypper use default answers to prompts.
```

There are two possible workarounds for this situation:

* Use the `--non-interactive` option with zypper and it will proceed without error.

    ```bash
    zypper --non-interactive in emacs
    ```

* Fix `/dev/tty` in the image.

    ```bash
    mknod /dev/tty c 5 0
    ```
