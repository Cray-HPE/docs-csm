# Configure Log Rotation

In order to prevent the console logs from filling the PVC volume they are stored on
they are periodically rotated. This can keep a number of older sections of the log
file as well as the current log file on the volume. Different size systems have
different requirements based on the number of nodes, the amount of text being written
to the individual log files, the size of the PVC they are being stored on, and the
history that needs to be kept in the form of the log files.

All of the console log information is kept in the System Monitoring Framework so these
log files are not required for a permanent record of the console activity. See
[Access Console Log Data Via the System Monitoring Framework](./Access_Console_Log_Data_Via_the_System_Monitoring_Framework_SMF.md)
for more information on this topic.

> **`NOTE`** Log rotation will move the current log file and create a new one with the original
    location and name. If you are using a `tail` operation to watch the console log output,
    make sure to use the `tail -F` option to automatically switch the `tail` to the new
    file through a log rotation. Otherwise the `tail` will follow the old file which has
    moved and is no longer being appended to with new console log information.

## How log rotation works

On a regular schedule, the log rotation will execute the following steps:

1. Check the size of all the current console log files.

    If the size of the file is larger than a specified size, it will be
    moved to the `/var/log/conman.old` directory with the name
    `console.XNAME.1` and a new file will be created for the current logs
    `/var/log/conman/console.XNAME`.

1. Manage the current backup files.

    If a file already exists in the `/var/log/conman.old` directory for
    a particular console log that is being rotated, the existing files
    will be renamed `/var/log/conman.old/console.XNAME.N+1`.

    There is a configuration setting for how many rotations to keep, once
    that limit is reached, the oldest version of the console log file will
    be deleted.

## Modify the settings for the log rotation

1. Edit the `cray-console-node` stateful set:

    ```bash
    kubectl -n services edit statefulset cray-console-node
    ```

1. Look for the section that contains log rotation settings:

    ```text
        - env:
        - name: LOG_ROTATE_ENABLE
            value: "True"
        - name: LOG_ROTATE_FILE_SIZE
            value: 5M
        - name: LOG_ROTATE_SEC_FREQ
            value: "600"
        - name: LOG_ROTATE_NUM_KEEP
            value: "2"
    ```

    1. `LOG_ROTATE_ENABLE`

        This enables or disables the log rotation feature overall. If you wish to
        not have any log rotation happen at all, then set the value to 'False' but
        you must keep a close eye on the capacity of the PVC.

    1. `LOG_ROTATE_SEC_FREQ`

        This sets how often the log rotation will happen in seconds. The default is
        every 600 seconds (10 minutes). If you want rotation to happen more often
        decrease this setting, if you want it to happen more often increase it. This
        is the interval between when log rotation completes and when it starts again
        so if the rotation takes a bit of time you may see the actual time between
        to subsequent log rotations end up longer than this interval.

    1. `LOG_ROTATE_FILE_SIZE`

        This is the size of a file to rotate. When the log rotation happens, if an
        individual log file is larger than this size, it will be rotated.

        Depending on how often the log rotation is executed and how quickly the file
        is growing you may see the files get quite a bit larger than this size when
        the rotation actually happens. If files are growing significantly larger than
        this setting increase the frequency of log rotations.

    1. `LOG_ROTATE_NUM_KEEP`

        This is the number of log rotations it will keep in the `/var/log/conman.old`
        directory. For example if this value is 2, there will be a
        `/var/log/conman.old/console.XNAME.1` and `/var/log/conman.old/console.XNAME.2`
        file for each console that has logging active (after sufficient time has passed
        for the file to be rotated twice). Setting this value to 0 will prevent any
        older files to be kept.

## Scenarios that may be encountered and possible solutions

1. The log files are getting too large before they are being rotated.

    Decrease the value of `LOG_ROTATE_FILE_SIZE` to make smaller files
    subject to rotation.

    If the files are larger than the `LOG_ROTATE_FILE_SIZE`, decrease the
    value of `LOG_ROTATE_SEC_FREQ` so the rotation happens too often.

1. Log files are being rotated before a complete boot.

    If the boot operation outputs a lot of information, increase the value of
    `LOG_ROTATE_FILE_SIZE` to keep the file larger before a rotation will
    happen.

1. The PVC is being filled up.

    This means there is too much data being retained for the current size of the PVC.
    The following may be done to decrease the amount of data:

    1. Decrease the value of `LOG_ROTATE_FILE_SIZE` to keep the file size down.

    1. Decrease the value of `LOG_ROTATE_SEC_FREQ` to rotate the log files more frequently.

    1. Decrease the value of `LOG_ROTATE_NUM_KEEP` to keep fewer old copies of the log files.

    If none of these steps are appropriate for the requirements of the system, the size of the
    PVC may be increased by following the directions here:
    [Console Services Troubleshooting Guide](./Console_Services_Troubleshooting_Guide.md#check-the-capacity-of-the-pvc)
