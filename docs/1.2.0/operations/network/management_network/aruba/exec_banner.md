# Configure Exec Banners

Exec banners are custom messages displayed to users attempting to connect to the management interfaces. Multiple lines of text can be stored using a custom delimiter to mark the end of message.

## Configuration Commands

Create a banner:

```
switch(config)# banner <motd|exec> DELIM
```

Show commands to validate functionality:

```
switch# show banner <motd|exec>
```

## Example Output

```
switch(config)# banner exec $
Enter a new banner, when you are done enter a new line containing only your
chosen delimiter.
(banner-motd)# This is an example of a custom banner
(banner-motd)# that spans multiple lines.
(banner-motd)# $
switch(config)# do show banner exec
```

## Expected Results

1. Administrators can create the Exec banner
2. The output of the Exec banner looks correct

[Back to Index](../index.md)