
# Message-Of-The-Day (MOTD)

Banners are custom messages displayed to users attempting to connect to the management interfaces. MOTD banners are displayed pre-login while exec banners are displayed post-login. Multiple lines of text can be stored using 
a custom delimiter to mark the end of message. 

## Configuration Commands

Create a banner:

```bash
switch(config)# banner <motd|exec> DELIM
```

Show commands to validate functionality: 

```bash
switch# show banner <motd|exec>
```

## Example Output 

```bash
switch(config)# banner motd $
Enter a new banner, when you are done enter a new line containing only your
chosen delimeter.
(banner-motd)# This is an example of a custom pre-login banner
(banner-motd)# that spans multiple lines.
(banner-motd)# $
switch(config)# do show banner motd
```

This is an example of a custom pre-login banner
that spans multiple lines.


## Expected Results

1. You can create the MOTD banner
2. The output of the MOTD banner looks correct 


[Back to Index](../index_aruba.md)
