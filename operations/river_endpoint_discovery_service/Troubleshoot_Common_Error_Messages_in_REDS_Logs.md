## Troubleshoot Common Error Messages in REDS Logs

Examine logs for error messages that indicate common errors in the setup or running of the River Endpoint Discovery Service \(REDS\).

### Limitations

This procedure does not cover all possible error messages. For help interpreting error messages not included here, contact the Cray customer account representative for this site.

### Examine REDS Logs

Before viewing the REDS logs, set the following environment variable:

```bash
ncn-m001# REDSPOD=$(kubectl -n services get pods -l app.kubernetes.io/name=cray-reds \
-o=custom-columns=:.metadata.name --no-headers)
ncn-m001# echo $REDSPOD
cray-reds-5854fdcd9d-ffgms
```

-   To view the logs and continue to monitor new messages as they are added:

    ```bash
    ncn-m001# kubectl -n services logs --follow $REDSPOD cray-reds
    ```

    Press **Ctrl-c** to exit.

-   To view the logs but not continue to monitor:

    ```bash
    ncn-m001# kubectl -n services logs $REDSPOD cray-reds
    ```

When examining the log for errors, begin at the beginning of the log and work downwards. In many cases, an error early on can cause other errors later, so it is important to correct the error first. The following table lists the most common error messages in REDS logs.

#### The Credentials in the Mapping do not Match the Credentials Configured on the Switch

The following error message will be shown:

```
WARNING: ${XNAME}:Getting Mac address table failed (VLANs): Received a report from the agent - UsmStatsDecryptionErrors(1.3.6.1.6.3.15.1.1.6.0)
```

**Solution:**

1. Verify that the credentials configured in the mapping file match those configured on the switch. Pay special attention to the protocols in use.
2. After the credentials issue is corrected, [Clear State and Restart REDS](Clear_State_and_Restart_REDS.md).

#### REDS did not Verify the HTTPS Certificate of the Datastore Service

The following error message will be shown:

```
WARNING: insecure https connection to datastore service
```

**Solution:** Do nothing. This message is expected.

#### The Mapping File was not Uploaded

The following error message will be shown:

```
SNMP: Ignoring string on ignore list: NET-SNMP version ${VERSION}
```

**Solution:** See [System Layout Service (SLS)](../system_layout_service/System_Layout_Service_SLS.md).

