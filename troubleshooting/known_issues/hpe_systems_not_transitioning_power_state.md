# HPE iLO dropping event subscriptions and not properly transitioning power state in CSM software

HPE Systems impacted:

* DL325
* DL385
* Apollo 6500

When HPE iLO systems are not properly transitioning power state in HMS/SAT this
could indicate that Redfish events are not being received by the HMS
HM-Collector. When this occurs, the HPE iLO receives an error back from its
attempt to send events and will delete the subscription if there are enough
failures. To detect this state, look at the subscription numbers under
`/redfish/v1/EventService/Subscriptions`. If subscriptions are missing or are
extremely large and increasing, this would indicate the iLO is receiving an
error when trying to send Redfish events.

(`ncn-m#`) Check subscriptions on affected BMC

```bash
curl -sk -u root:$PASSWD https://${BMC}/redfish/v1/EventService/Subscriptions | jq -c '.Members[]'
```

* If there is at least one subscription and it is a low number, everything is OK. No action is needed.
* If there is at least one subscription and it is large number, verify it is not increasing by executing the above command several times over ~10 minutes.
* If the subscription number is not increasing, everything is OK. No action is needed.
* If the subscription number is increasing, the BMC will need to be reset.
* If there are no subscriptions, the BMC will need to be reset.

(`ncn-m#`) Reset BMC with `ipmitool`

```bash
ipmitool -H $BMC -U root -P $PASSWD -I lanplus mc reset cold
```
