# Procedure to check CHN

In order to check whether the system is using CHN run the following command on ncn:

```bash
cray sls search networks list --name BICAN --format json
```

Example output:

```text
[
  {
    "Name": "BICAN",
    "FullName": "SystemDefaultRoute points the network name of the default route",
    "IPRanges": [
      "0.0.0.0/0"
    ],
    "Type": "ethernet",
    "LastUpdated": 1746612352,
    "LastUpdatedTime": "2025-05-07 10:05:52.243636 +0000 +0000",
    "ExtraProperties": {
      "CIDR": "0.0.0.0/0",
      "MTU": 9000,
      "Subnets": [],
      "SystemDefaultRoute": "CHN",
      "VlanRange": [
        0
      ]
    }
  }
]
```
