# Start a Broker UAI

Create a broker UAI after a broker UAI class has been created.

### Prerequisites

A broker UAI class has been set up. See [Configure a Broker UAI Class](Configure_a_Broker_UAI_Class.md).

### Procedure

Use the following command to create a broker UAI:

```
ncn-m001-pit# cray uas admin uais create --class-id <class-id> [--owner <name>]
```

To make the broker obvious in the list of UAIs, giving it an owner name of `broker` is handy. The owner name on a broker is used for naming and listing, but nothing else, so this is a convenient convention.

The following is an example using the class created above:

```
ncn-m001-pit# cray uas admin uais create --class-id 74970cdc-9f94-4d51-8f20-96326212b468 --owner broker
uai_connect_string = "ssh broker@10.103.13.162"
uai_img = "dtr.dev.cray.com/cray/cray-uai-broker:latest"
uai_ip = "10.103.13.162"
uai_msg = ""
uai_name = "uai-broker-11f36815"
uai_status = "Pending"
username = "broker"

[uai_portmap]
```

