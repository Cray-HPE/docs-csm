# Flags Set For Nodes In HSM

## Table of contents

- [Introduction](#introduction)
- [Warning Flags](#warning-flags)
- [Alert Flags](#alert-flags)

## Introduction

This document describes how to identify and troubleshoot issues with nodes in HSM that have flags other than "OK" set.

## Warning Flags

Warning flags are set for nodes in HSM when BMCs report an unhealthy status in Redfish for some component associated with the node.

1. (`ncn-mw#`) Check for nodes with "Warning" flags set in HSM.

    ```bash
    cray hsm state components list --type Node --flag Warning --format json | jq '.Components[] | { ID: .ID, Flag: .Flag }' -c | sort -V | jq -c
    ```

    Example output:

    ```text
    {"ID":"x3000c0s19b1n0","Flag":"Warning"}
    {"ID":"x3000c0s19b2n0","Flag":"Warning"}
    {"ID":"x3000c0s19b3n0","Flag":"Warning"}
    {"ID":"x3000c0s19b4n0","Flag":"Warning"}
    ```

1. (`ncn-mw#`) Check the BMCs of the "Warning" flag nodes for endpoints with unhealthy statuses in Redfish.

    Example command:

    ```bash
    curl -s -k -u root:<password> https://<bmc_xname>/redfish/v1/Systems/1/Memory/proc1dimm1 | jq
    ```

    Example output for unhealthy DIMM:

    ```text
    {
        ...
        "@odata.id": "/redfish/v1/Systems/1/Memory/proc1dimm1",
        "@odata.type": "#Memory.v1_7_1.Memory",
        "Id": "proc1dimm1",
        ...
        "Oem": {
            "Hpe": {
            ...
            "DIMMStatus": "Degraded",
            }
        },
        ...
        "Status": {
            "Health": "Warning",
            "State": "Enabled"
        },
        ...
    } 
    ```

    Example command:

    ```bash
    curl -s -k -u root:<password> https://<bmc_xname>/redfish/v1/Chassis/Enclosure | jq
    ```

    Example output for unhealthy Chassis Enclosure:

    ```text
    {
        ...
        "@odata.id": "/redfish/v1/Chassis/Enclosure",
        "@odata.type": "#Chassis.v1_5_1.Chassis",
        "ChassisType": "Enclosure",
        ...
        "Status": {
            "Health": "Critical",
            "State": "Enabled"
        },
        ...
    }
    ```

The Redfish event logs may also help determine the cause of unhealthy statuses.

1. (`ncn-mw#`) Check the log entries for components with unhealthy statuses.

    ```bash
    curl -s -k -u root:<password> https://<bmc_xname>/redfish/v1/Chassis/Self/LogServices/Logs/Entries/<num> | jq
    ```

    Example of log entry for unhealthy Power Supply:

    ```text
    {
        ...
        "@odata.id": "/redfish/v1/Chassis/Self/LogServices/Logs/Entries/113",
        "@odata.type": "#LogEntry.v1_4_2.LogEntry",
        ...
        "EventTimestamp": "2022-07-27T06:18:55+00:00",
        ...
        "Links": {
            "OriginOfCondition": {
            "@odata.id": "/redfish/v1/Chassis/Self/Power"
            }
        },
        "Message": "0x00FFFF",
        "MessageId": "AmiIpmiOem.1.0.GeneralEventData",
        "Name": "LOG 113",
        "SensorNumber": 230,
        "SensorType": "Power Supply / Converter",
        "Severity": "Critical"
    }
    ```

## Alert Flags

Nodes with "Alert" flags set that are also in "Standby" state in HSM indicate that heartbeats have been lost for the node.

1. (`ncn-mw#`) Check for nodes with "Alert" flags set and "Standby" state in HSM.

    ```bash
    cray hsm state components list --type Node --flag Alert --state Standby --format json | jq '.Components[] | { ID: .ID, Flag: .Flag, State: .State }' -c | sort -V | jq -c
    ```

    Example output:

    ```text
    {"ID":"x3000c0s19b1n0","Flag":"Alert","State":"Standby"}
    {"ID":"x3000c0s19b2n0","Flag":"Alert","State":"Standby"}
    {"ID":"x3000c0s19b3n0","Flag":"Alert","State":"Standby"}
    {"ID":"x3000c0s19b4n0","Flag":"Alert","State":"Standby"}
    ```

Alert flags will be cleared when heartbeats resume for the node. If the node is accessible, check to see if it can communicate.

1. (`ncn-mw#`) Check the heartbeat status on the node.

    ```bash
    ssh root@<node_xname> systemctl status cray-heartbeat
    ```
