# `Exec` Banners

Banners are custom messages displayed to users attempting to connect to the management interfaces.
MOTD banners are displayed pre-login while `exec` banners are displayed post-login.
Multiple lines of text can be stored using a custom delimiter to mark the end of message.

## Configuration commands

(`switch(config)#`) Create a banner:

```console
banner <motd|exec> DELIM
```

(`switch#`) Show commands to validate functionality:

```console
show banner <motd|exec>
```

```console
switch(config)# banner exec $
Enter a new banner, when you are done enter a new line containing only your
chosen delimiter.
(banner-motd)# This is an example of a custom banner
(banner-motd)# that spans multiple lines.
(banner-motd)# $
switch(config)# do show banner exec
```

## Expected results

* Administrators can create the `Exec` banner.
* The output of the `Exec` banner looks correct.

[Back to Index](../README.md)
