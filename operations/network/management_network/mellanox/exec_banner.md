# `Exec` Banners

Banners are custom messages displayed to users attempting to connect to the management interfaces.
MOTD banners are displayed pre-login while `exec` banners are displayed post-login.
Multiple lines of text can be stored using a custom delimiter to mark the end of message.

## Configuration commands

(`switch(config)#`) Create a banner.

```console
banner motd Testing
```

## Show commands to validate functionality

```console
show banner
```

Example output

```text
Banners:
    MOTD:
Mellanox UFM Appliance

    Login:
Mellanox MLNX-OS UFM Appliance Management
```

## Expected results

* The banner can be created.
* The output of the banner looks correct.

[Back to Index](../README.md)
