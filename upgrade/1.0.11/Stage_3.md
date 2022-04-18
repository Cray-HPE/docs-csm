# Stage 3 - CSM Service Upgrades

>**`IMPORTANT:`**
>
> Reminder: Before running any upgrade scripts, be sure the Cray CLI output format is reset to default by running the following command:
>
>```bash
> ncn# unset CRAY_FORMAT
>```

Update Loftsman to version 1.2 if not present:

```bash
ncn-m# [[ $(loftsman --version | grep 1.2) ]] && zypper refresh && zypper in loftsman
```

Run `csm-service-upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m# /usr/share/doc/csm/upgrade/1.0.11/scripts/upgrade/csm-service-upgrade.sh
```

Once `Stage 3` is completed, proceed to [Stage 4](Stage_4.md)
