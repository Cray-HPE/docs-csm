# Stage 3 - CSM Service Upgrades

>**`IMPORTANT:`**
> 
> Reminder: Before running any upgrade scripts, be sure the Cray CLI output format is reset to default by running the following command:
>
>```bash
> ncn# unset CRAY_FORMAT
>```

Run `csm-service-upgrade.sh` to deploy upgraded CSM applications and services:

```bash
ncn-m002# /usr/share/doc/csm/upgrade/1.0.11/scripts/upgrade/csm-service-upgrade.sh
```

Once `Stage 3` is completed, proceed to [Stage 4](Stage_4.md)
