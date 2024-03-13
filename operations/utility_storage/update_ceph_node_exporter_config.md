# Update ceph node-exporter config to monitor SNMP counters

This procedure updates the ceph node-exporter configuration and enables the monitoring of all SNMP counters in `/proc/net/snmp` with the `netstat` collector.
The SNMP counters for e.g are `Udp MemError`, `Udp IgnoredMulti`, `Tcp ActiveOpens`, `Tcp AttemptFails`, `Icmp InRedirects`, `Icmp OutEchos`, `IpInReceives`, `Ip InUnknownProtos`, etc.

## Steps

1. (`ncn-m001#`) Create a template file.

   ```bash
   cat>>node-exporter-config.yml<<'EOF'
   service_type: node-exporter
   service_name: node-exporter
   placement:
     host_pattern: '*'
   extra_container_args:
   - -v /var/lib/node_exporter:/host/node_exporter:ro
   extra_entrypoint_args:
   - --collector.textfile.directory=/host/node_exporter
   - --collector.netstat.fields=^(.*_(InErrors|InErrs)|Ip_(Forwarding|DefaultTTL|InReceives|InHdrErrors|InAddrErrors|ForwDatagrams|InUnknownProtos|InDiscards|InDelivers|OutRequests|OutDiscards|OutNoRoutes|ReasmTimeout|ReasmReqds|ReasmOKs|ReasmFails|FragOKs|FragFails|FragCreates)|Ip(6|Ext)_(InOctets|OutOctets)|Icmp6?_(InMsgs|OutMsgs|InMsgs|InCsumErrors|InDestUnreachs|InTimeExcds|InParmProbs|InSrcQuenchs|InRedirects|InEchos|InEchoReps|InTimestamps|InTimestampReps|InAddrMasks|InAddrMaskReps|OutErrors|OutDestUnreachs|OutTimeExcds|OutParmProbs|OutSrcQuenchs|OutRedirects|OutEchos|OutEchoReps|OutTimestamps|OutTimestampReps|OutAddrMasks|OutAddrMaskReps)|IcmpMsg_(InType0|InType3|InType8|OutType0|OutType3|OutType8)|TcpExt_(Listen.*|Syncookies.*|TCPSynRetrans|TCPTimeouts)|Tcp_(ActiveOpens|InSegs|OutSegs|OutRsts|PassiveOpens|RetransSegs|CurrEstab|RtoAlgorithm|RtoMin|RtoMax|MaxConn|AttemptFails|EstabResets|InCsumErrors)|Udp(6|Lite)?_(InDatagrams|OutDatagrams|NoPorts|RcvbufEr|SndbufErrors|InCsumErrors|IgnoredMulti|MemErrors))$
   EOF
   ```

1. (`ncn-m001#`) Apply `node-exporter-config.yml` file.
  
   ```bash
   ceph orch apply -i node-exporter-config.yml
   ```

1. (`ncn-m001#`) Reconfigure node-exporter.

   ```bash
   ceph orch reconfig node-exporter
   ```

1. (`ncn-m001#`) Redeploy node-exporter.
  
   ```bash
   ceph orch redeploy node-exporter
   ```

1. (`ncn-m001#`) Verify the changes.
  
   ```bash
   ceph orch ls --service_name node-exporter --export
   ```
  
   Example Output:
  
   ```text
   service_type: node-exporter
   service_name: node-exporter
   placement:
     host_pattern: '*'
   extra_container_args:
   - -v /var/lib/node_exporter:/host/node_exporter:ro
   extra_entrypoint_args:
   - --collector.textfile.directory=/host/node_exporter
   - --collector.netstat.fields=^(.*_(InErrors|InErrs)|Ip_(Forwarding|DefaultTTL|InReceives|InHdrErrors|InAddrErrors|ForwDatagrams|InUnknownProtos|InDiscards|InDelivers|OutRequests|OutDiscards|OutNoRoutes|ReasmTimeout|ReasmReqds|ReasmOKs|ReasmFails|FragOKs|FragFails|FragCreates)|Ip(6|Ext)_(InOctets|OutOctets)|Icmp6?_(InMsgs|OutMsgs|InMsgs|InCsumErrors|InDestUnreachs|InTimeExcds|InParmProbs|InSrcQuenchs|InRedirects|InEchos|InEchoReps|InTimestamps|InTimestampReps|InAddrMasks|InAddrMaskReps|OutErrors|OutDestUnreachs|OutTimeExcds|OutParmProbs|OutSrcQuenchs|OutRedirects|OutEchos|OutEchoReps|OutTimestamps|OutTimestampReps|OutAddrMasks|OutAddrMaskReps)|IcmpMsg_(InType0|InType3|InType8|OutType0|OutType3|OutType8)|TcpExt_(Listen.*|Syncookies.*|TCPSynRetrans|TCPTimeouts)|Tcp_(ActiveOpens|InSegs|OutSegs|OutRsts|PassiveOpens|RetransSegs|CurrEstab|RtoAlgorithm|RtoMin|RtoMax|MaxConn|AttemptFails|EstabResets|InCsumErrors)|Udp(6|Lite)?_(InDatagrams|OutDatagrams|NoPorts|RcvbufEr|SndbufErrors|InCsumErrors|IgnoredMulti|MemErrors))$
   ```

1. (`ncn-m001#`) Verify whether node-exporter is redeployed or not.

   ```bash
   ceph orch ps | grep node
   ```

   Example Output:

   ```text
   node-exporter.ncn-s001           ncn-s001  *:9100       running (4m)     4m ago   8w    24.5M        -  1.5.0    adb3cf430d1a  1b339a84138e
   node-exporter.ncn-s002           ncn-s002  *:9100       running (4m)     4m ago   8w    17.6M        -  1.5.0    adb3cf430d1a  cdd75aca87fd
   node-exporter.ncn-s003           ncn-s003  *:9100       running (4m)     4m ago   8w    23.4M        -  1.5.0    adb3cf430d1a  08eb951296dc
   node-exporter.ncn-s004           ncn-s004  *:9100       running (4m)     4m ago   8w    23.3M        -  1.5.0    adb3cf430d1a  eb9e85bb2414
   node-exporter.ncn-s005           ncn-s005  *:9100       running (4m)     4m ago   8w    23.3M        -  1.5.0    adb3cf430d1a  75b7bdd64c45
   ```
  
   NOTE: The node-exporter containers are restarted on all the storage nodes.
