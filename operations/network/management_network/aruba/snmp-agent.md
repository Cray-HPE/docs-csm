
# Simple Network Management Protocol (SNMP) Agent 

Simple Network Management Protocol (SNMP) minimizes the number and complexity of management functions. For monitoring and control, it is extensible to accommodate additional, possibly unanticipated aspects of network operation and management. SNMP is universal and independent of the architecture and mechanisms of particular hosts or particular gateways. SNMP server is supported either on the default or mgmt VRF. 

## Configuration Commands

Enable SNMP agent: 

```bash
switch(config)# snmp-server vrf VRF
```

Configure the port to which the SNMP agent is bound: 

```bash
switch(config)# snmp-server agent-port PORT
```

Configure an SNMPv2c community name: 

```bash
switch(config)# snmp-server community NAME
```

Configure a SNMPv2c trap receiver host: 

```bash
switch(config)# snmp-server host IP-ADDR <trap|inform> version v2c [community NAME]
```

Show commands to validate functionality:  

```bash
switch# show snmp [agent-port|community|trap|vrf] [vsx-peer]
```

## Example Output 

```bash
switch(config)# snmp-server vrf default
switch(config)# snmp-server agent-port 10601
switch(config)# snmp-server community public
switch(config)# snmp-server host 1.2.3.4 trap version v2c community public
switch(config)# snmp-server host 1.2.3.4 inform version v2c community public
switch(config)# end
switch# show snmp community
---------------------
SNMP communities
---------------------
Public

switch# show snmp vrf
SNMP enabled VRF
----------------------------
Default

switch# show snmp agent-port
SNMP agent port : 10601
switch# show snmp trap
------------------------------------------------------------------------------------------
Host                     Port  Type      Version SecName                         vrf
------------------------------------------------------------------------------------------
1.2.3.4                  162   trap      v2c     public                        default
1.2.3.4                  162   inform    v2c     public                        default
```

## Expected Results 

1. You can configure the port number
2. The output of all `show` commands is correct
3. You can connect to the switch from the workstation 

[Back to Index](index_aruba.md)