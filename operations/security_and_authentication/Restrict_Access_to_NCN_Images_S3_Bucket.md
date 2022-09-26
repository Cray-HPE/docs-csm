# Restrict Network Access to the `ncn-images` S3 Bucket

The configuration documented in this procedure is intended to prevent user-facing dedicated nodes (UANs, Compute Nodes) from retrieving NCN image content from Ceph S3 services, as running on storage nodes.

Specifically, the controls enacted via this procedure should do the following:

1. Block HAProxy access to the `ncn-images` bucket if the client is not an NCN (NMN) or PXE booting from the MTL network. This via a HAProxy ACL on the storage servers.
2. Enable access logging for HAProxy.
3. Block Rados GW network access (port 8080) if the client is not an NCN (NMN) or originating from the HMN network. This via `iptables` rules on the storage servers.

## Limitations

This is not designed to prevent UAIs (if in use) from retrieving NCN image content.

If a storage node is rebuilt, this procedure (for the rebuilt node) will need to be applied after the rebuild. The same is true if NCNs are added or removed from the system as it will change source IP ranges for clients.

## Prerequisites and scope

Procedure should be executed after install or upgrade is otherwise complete, but prior to opening the system for user access.

Unless otherwise noted, the procedure should be run from `ncn-m001` (not PIT).  

This procedure was back-ported from CSM 1.0 and was tested on a CSM 0.9.5 system.

## Procedure

1. Test connectivity before applying the ACL.

   Save the following script to a file (for example, `con_test.sh`).

    ```bash
    #!/bin/bash


    SNCNS="$(grep 'ncn-s.*\.nmn' /etc/hosts | awk '{print $NF;}' | xargs)"
    SCSNS_NMN="$(echo $SNCNS | xargs -n 1 | sed -e 's/$/.nmn/g')"
    SCSNS_HMN="$(echo $SNCNS | xargs -n 1 | sed -e 's/$/.hmn/g')"
    SCSNS_CAN="$(echo $SNCNS | xargs -n 1 | sed -e 's/$/.can/g')"

    RADOS_HTTP_PORT="8080"
    HAPROXY_HTTP_PORT="80"
    HAPROXY_HTTPSPORT="443"

    PASS="PASS"
    FAIL="FAIL"

    function rados_test
    {
    NODES="$1"
    MSG="$2"
    TTYPE="$3"

    echo "[i] $MSG"
    for n in $NODES
    do
        echo -n "  RADOS $n: "
        if [ "$TTYPE" == "CONN_FAIL" ]
        then
            curl -sI --connect-timeout 2 http://${n}:${RADOS_HTTP_PORT}/ &> /dev/null
            rc=$?
            rc_pass=28
        else
            curl -I --connect-timeout 2 http://${n}:${RADOS_HTTP_PORT}/ 2>/dev/null | grep -q "200 OK"
            rc=$?
            rc_pass=0
        fi

        if [ $rc -eq $rc_pass ]
        then
            echo $PASS
        else
            echo $FAIL
        fi
    done
    }

    function haproxy_test
    {
    NODES="$1"
    MSG="$2"

    echo "[i] $MSG"
    for n in $NODES
    do
        echo -n "  HAPROXY (CEPH) HTTP $n: "
        curl -I --connect-timeout 2 http://${n}:${HAPROXY_HTTP_PORT}/ncn-images/ 2>/dev/null | grep -q "x-amz-request-id"
        if [ $? -eq 0 ]
        then
            echo $PASS
        else
            echo $FAIL
        fi

        echo -n "  HAPROXY (CEPH) HTTPS $n: "
        curl -kI --connect-timeout 2 https://${n}:${HAPROXY_HTTPS_PORT}/ncn-images/ 2>/dev/null | grep -q "x-amz-request-id"
        if [ $? -eq 0 ]
        then
            echo $PASS
        else
            echo $FAIL
        fi

    done
    }

    rados_test "$SCSNS_NMN" "MGMT RADOS over NMN"
    rados_test "$SCSNS_HMN" "MGMT RADOS over HMN"
    rados_test "$SCSNS_CAN" "MGMT RADOS over CAN" "CONN_FAIL"
    haproxy_test "$SCSNS_NMN" "MGMT HAProxy over NMN"
    ```

   Execute the script, if the ACLs have not been applied, results similar to the following will be returned (failures are expected):

    ```bash
    [i] MGMT RADOS over NMN
    RADOS ncn-s003.nmn: PASS
    RADOS ncn-s002.nmn: PASS
    RADOS ncn-s001.nmn: PASS
    [i] MGMT RADOS over HMN
    RADOS ncn-s003.hmn: PASS
    RADOS ncn-s002.hmn: PASS
    RADOS ncn-s001.hmn: PASS
    [i] MGMT RADOS over CAN
    RADOS ncn-s003.can: FAIL
    RADOS ncn-s002.can: FAIL
    RADOS ncn-s001.can: FAIL
    [i] MGMT HAProxy over NMN
    HAPROXY (CEPH) HTTP ncn-s003.nmn: PASS
    HAPROXY (CEPH) HTTPS ncn-s003.nmn: PASS
    HAPROXY (CEPH) HTTP ncn-s002.nmn: PASS
    HAPROXY (CEPH) HTTPS ncn-s002.nmn: PASS
    HAPROXY (CEPH) HTTP ncn-s001.nmn: PASS
    HAPROXY (CEPH) HTTPS ncn-s001.nmn: PASS
    ```

2. Build an IP address list of NCNs on the NMN.

   Cross-check to verify the count seems appropriate for the system in use.

   ```bash
   ncn-m001# grep 'ncn-[mws].*.nmn' /etc/hosts | awk '{print $1;}' | sed -e 's/\./ /g' | sort -nk 4 | sed -e 's/ /\./g' | tee allowed_ncns.lst
   10.252.1.4
   10.252.1.5
   10.252.1.6
   10.252.1.7
   10.252.1.8
   10.252.1.9
   10.252.1.10
   10.252.1.11
   10.252.1.12
   10.252.1.13
   10.252.1.14
   ```

3. Add the MTL subnet (needed for network boots of NCNs).

   ```bash
   ncn-m001# echo '10.1.0.0/16' >> allowed_ncns.lst
   ```

4. Verify the `allowed_ncns.lst` contains contain NMN addresses for all management NCNs nodes and the MTL subnet (10.1.0.0/16).

   ```bash
   ncn-m001# cat allowed_ncns.lst 
   10.252.1.4
   10.252.1.5
   10.252.1.6
   10.252.1.7
   10.252.1.8
   10.252.1.9
   10.252.1.10
   10.252.1.11
   10.252.1.12
   10.252.1.13
   10.252.1.14
   10.1.0.0/16
   ```

5. Confirm HAProxy configurations are identical across storage nodes.

   Adjust the `-w` predicate to represent the full set of storage nodes for the system. Applies to this step and subsequent steps.

   ```bash
   ncn-m001# pdsh -w ncn-s00[1-4] "cat /etc/haproxy/haproxy.cfg" | dshbak -c
   ----------------
   ncn-s[001-004]
   ----------------
   # Please do not change this file directly since it is managed by Ansible and will be overwritten
   global
      log         127.0.0.1 local2

      chroot      /var/lib/haproxy
      pidfile     /var/run/haproxy.pid
      maxconn     8000
      user        haproxy
      group       haproxy
      daemon
      stats socket /var/lib/haproxy/stats
      tune.ssl.default-dh-param 4096
      ssl-default-bind-ciphers EECDH+AESGCM:EDH+AESGCM
      ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets
   defaults
      mode                    http
      log                     global
      option                  httplog
      option                  dontlognull
      option http-server-close
      option forwardfor       except 127.0.0.0/8
      option                  redispatch
      retries                 3
      timeout http-request    10s
      timeout queue           1m
      timeout connect         10s
      timeout client          1m
      timeout server          1m
      timeout http-keep-alive 10s
      timeout check           10s
      maxconn                 8000

   frontend http-rgw-frontend
      bind *:80
      default_backend rgw-backend

   frontend https-rgw-frontend
      bind *:443 ssl crt /etc/ceph/rgw.pem
      default_backend rgw-backend

   backend rgw-backend
      option forwardfor
      balance static-rr
      option httpchk GET /
         server server-ncn-s001-rgw0 10.252.1.7:8080 check weight 100
         server server-ncn-s002-rgw0 10.252.1.6:8080 check weight 100
         server server-ncn-s003-rgw0 10.252.1.5:8080 check weight 100
         server server-ncn-s004-rgw0 10.252.1.4:8080 check weight 100
   ```

6. Create a backup of `haproxy.cfg` files on storage nodes.

   ```bash
   ncn-m001# pdsh -w ncn-s00[1-4] "cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg-dist"
   ```

7. Grab a copy of `haproxy.cfg` to modify from a storage node, preserving permissions.

   ```bash
   ncn-m001# scp -p ncn-s001:/etc/haproxy/haproxy.cfg . 
   haproxy.cfg
   ```

8. Edit the `haproxy.cfg`, adding in the following ACLs and log directives to each front-end (a diff shown to illustrate changes necessary).

   ```bash
   ncn-m001# diff -Naur haproxy.cfg-dist haproxy.cfg
   --- haproxy.cfg-dist 2022-06-30 18:20:55.000000000 +0000
   +++ haproxy.cfg   2022-07-07 16:56:40.000000000 +0000
   @@ -1,6 +1,6 @@
   # Please do not change this file directly since it is managed by Ansible and will be overwritten
   global
   -    log         127.0.0.1 local2
   +    log         127.0.0.1:514 local0 info
   
      chroot      /var/lib/haproxy
      pidfile     /var/run/haproxy.pid
   @@ -31,12 +31,22 @@
      maxconn                 8000
   
   frontend http-rgw-frontend
   +    log global
   +    option httplog
      bind *:80
      default_backend rgw-backend
   +    acl allow_ncns src -n -f /etc/haproxy/allowed_ncns.lst
   +    acl restrict_ncn_images path_beg /ncn-images
   +    http-request deny if restrict_ncn_images !allow_ncns 
   
   frontend https-rgw-frontend
   +    log global
   +    option httplog
      bind *:443 ssl crt /etc/ceph/rgw.pem
      default_backend rgw-backend
   +    acl allow_ncns src -n -f /etc/haproxy/allowed_ncns.lst
   +    acl restrict_ncn_images path_beg /ncn-images
   +    http-request deny if restrict_ncn_images !allow_ncns 
   
   backend rgw-backend
      option forwardfor
   ```

9. Create a new `rsyslog` configuration for HAProxy to have it listen to UDP 514 on the local host.

    With the log directive additions to HAProxy, and allowing a local host UDP 514 socket, access logging should work properly. Set permissions to 640 on the file.

    ```bash
    ncn-m001# cat haproxy.conf 
    # Collect log with UDP
    $ModLoad imudp
    $UDPServerAddress 127.0.0.1
    $UDPServerRun 514

    ncn-m001# chmod 0640 haproxy.conf 
    ```

10. Make sure HAProxy is running on storage nodes.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "systemctl status haproxy" | grep "Active"
      ncn-s001:      Active: active (running) since Thu 2022-07-07 17:38:49 UTC; 54min ago
      ncn-s003:      Active: active (running) since Thu 2022-07-07 17:38:49 UTC; 54min ago
      ncn-s002:      Active: active (running) since Thu 2022-07-07 17:38:49 UTC; 54min ago
      ncn-s004:      Active: active (running) since Thu 2022-07-07 17:38:49 UTC; 54min ago
      ```

11. Determine where the HAProxy VIP currently resides (for awareness in the event debug is necessary).

      ```bash
      ncn-m001# host rgw-vip
      rgw-vip.nmn has address 10.252.1.3

      ncn-m001# host rgw-vip.nmn
      rgw-vip.nmn has address 10.252.1.3

      ncn-m001# host 10.252.1.3
      3.1.252.10.in-addr.arpa domain name pointer rgw-vip.
      3.1.252.10.in-addr.arpa domain name pointer rgw-vip.local.
      3.1.252.10.in-addr.arpa domain name pointer rgw-vip.local.local.
      3.1.252.10.in-addr.arpa domain name pointer rgw-vip.nmn.
      3.1.252.10.in-addr.arpa domain name pointer rgw-vip.nmn.local.

      ncn-m001# ssh rgw-vip 'hostname'
      ncn-s001
      ```

12. Propagate the `rsyslog` configuration out to all storage nodes.

      ```bash
      ncn-m001# pdcp -w ncn-s00[1-4] haproxy.conf /etc/rsyslog.d/
      ```

13. Propagate the HAProxy configuration out to all storage nodes.

      ```bash
      ncn-m001# pdcp -w ncn-s00[1-4] haproxy.cfg allowed_ncns.lst /etc/haproxy/
      ```

14. Verify the configurations are identical across storage nodes.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "cat /etc/haproxy/haproxy.cfg" | dshbak -c
      ----------------
      ncn-s[001-004]
      ----------------
      # Please do not change this file directly since it is managed by Ansible and will be overwritten
      global
         log         127.0.0.1 local2

         chroot      /var/lib/haproxy
         pidfile     /var/run/haproxy.pid
         maxconn     8000
         user        haproxy
         group       haproxy
         daemon
         stats socket /var/lib/haproxy/stats
         tune.ssl.default-dh-param 4096
         ssl-default-bind-ciphers EECDH+AESGCM:EDH+AESGCM
         ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets
      defaults
         mode                    http
         log                     global
         option                  httplog
         option                  dontlognull
         option http-server-close
         option forwardfor       except 127.0.0.0/8
         option                  redispatch
         retries                 3
         timeout http-request    10s
         timeout queue           1m
         timeout connect         10s
         timeout client          1m
         timeout server          1m
         timeout http-keep-alive 10s
         timeout check           10s
         maxconn                 8000

      frontend http-rgw-frontend
         bind *:80
         default_backend rgw-backend
         acl allow_ncns src -n -f /etc/haproxy/allowed_ncns.lst
         acl restrict_ncn_images path_beg /ncn-images
         http-request deny if restrict_ncn_images !allow_ncns 

      frontend https-rgw-frontend
         bind *:443 ssl crt /etc/ceph/rgw.pem
         default_backend rgw-backend
         acl allow_ncns src -n -f /etc/haproxy/allowed_ncns.lst
         acl restrict_ncn_images path_beg /ncn-images
         http-request deny if restrict_ncn_images !allow_ncns 

      backend rgw-backend
         option forwardfor
         balance static-rr
         option httpchk GET /
            server server-ncn-s001-rgw0 10.252.1.7:8080 check weight 100
            server server-ncn-s002-rgw0 10.252.1.6:8080 check weight 100
            server server-ncn-s003-rgw0 10.252.1.5:8080 check weight 100
            server server-ncn-s004-rgw0 10.252.1.4:8080 check weight 100
      ```

15. Restart `rsyslog` across all storage nodes.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "systemctl restart rsyslog"
      ncn-m001# pdsh -w ncn-s00[1-4] "systemctl status rsyslog" | grep Active
      ncn-s001:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ncn-s002:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ncn-s003:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ncn-s004:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ```

16. Restart HAProxy across all storage nodes.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "systemctl restart haproxy"
      ncn-m001# pdsh -w ncn-s00[1-4] "systemctl status haproxy" | grep Active
      ncn-s001:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ncn-s002:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ncn-s003:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ncn-s004:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ```

17. Apply server-side `iptables` rules to storage nodes.

      This is needed to prevent direct access to the Ceph Rados GW Service (not through HAProxy).

      The process is written to support change on individual nodes, but could be scripted after analysis of the running firewall rule set (notably with respect to local modifications, if they exist).

      This process must be completed on each storage node (steps 18 - 21).

18. Document where Rados GW is running (port wise). It should be the same across all storage nodes.

      ```bash
      ncn-s001# ss -tnpl | grep rados
      LISTEN    0         128                0.0.0.0:8080             0.0.0.0:*        users:(("radosgw",pid=25018,fd=77))                                            
      LISTEN    0         128                   [::]:8080                [::]:*        users:(("radosgw",pid=25018,fd=78))  
      ```

19. List existing `iptables` rules.

      ```bash
      ncn-s001# iptables -L -nx -v
      Chain INPUT (policy ACCEPT 399480930 packets, 1051007801113 bytes)
         pkts      bytes target     prot opt in     out     source               destination         
            0        0 DROP       tcp  --  *      *       0.0.0.0/0            10.102.4.135         tcp dpt:22

      Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
         pkts      bytes target     prot opt in     out     source               destination         

      Chain OUTPUT (policy ACCEPT 400599807 packets, 1035420933926 bytes)
         pkts      bytes target     prot opt in     out     source               destination    

      ```

20. Run the following to add `iptables` rules for control.

      The range should include all NMN NCN IP addresses generated for the HAProxy ACL step.

      ```bash
      iptables -A INPUT -i vlan004 -p tcp --dport 8080 -j ACCEPT
      iptables -A INPUT -i lo -p tcp --dport 8080 -j ACCEPT
      iptables -A INPUT -p tcp --dport 8080 -m iprange --src-range 10.252.1.4-10.252.1.12 -j ACCEPT
      iptables -A INPUT -p tcp --dport 8080 -j LOG --log-prefix "RADOSGW-DROP"
      iptables -A INPUT -p tcp --dport 8080 -j DROP
      ```

21. List `iptables` rules again, verify rules are in place.

      ```bash
      ncn-s001# iptables -L -nx -v
      Chain INPUT (policy ACCEPT 22144 packets, 28721015 bytes)
         pkts      bytes target     prot opt in     out     source               destination         
            0        0 DROP       tcp  --  *      *       0.0.0.0/0            10.102.4.135         tcp dpt:22
            0        0 ACCEPT     tcp  --  vlan004 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080
            85     4862 ACCEPT     tcp  --  lo     *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080
         276    15438 ACCEPT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 source IP range 10.252.1.4-10.252.1.12
            0        0 LOG        tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 LOG flags 0 level 4 prefix "RADOSGW-DROP"
            0        0 DROP       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080

      Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
         pkts      bytes target     prot opt in     out     source               destination         

      Chain OUTPUT (policy ACCEPT 22099 packets, 30141111 bytes)
         pkts      bytes target     prot opt in     out     source               destination   
      ```

22. Test connectivity after applying the ACL.

      Re-run the connectivity test. While the results will be similar, they should all now be passing:

      ```bash
      ncn-m001# bash ./con_test.sh 
      [i] MGMT RADOS over NMN
      RADOS ncn-s001.nmn: PASS
      RADOS ncn-s002.nmn: PASS
      RADOS ncn-s003.nmn: PASS
      [i] MGMT RADOS over HMN
      RADOS ncn-s001.hmn: PASS
      RADOS ncn-s002.hmn: PASS
      RADOS ncn-s003.hmn: PASS
      [i] MGMT RADOS over CAN
      RADOS ncn-s001.can: PASS
      RADOS ncn-s002.can: PASS
      RADOS ncn-s003.can: PASS
      [i] MGMT HAProxy over NMN
      HAPROXY (CEPH) HTTP ncn-s001.nmn: PASS
      HAPROXY (CEPH) HTTPS ncn-s001.nmn: PASS
      HAPROXY (CEPH) HTTP ncn-s002.nmn: PASS
      HAPROXY (CEPH) HTTPS ncn-s002.nmn: PASS
      HAPROXY (CEPH) HTTP ncn-s003.nmn: PASS
      HAPROXY (CEPH) HTTPS ncn-s003.nmn: PASS
      ```

23. Validate no connection can be made to HAProxy for `ncn-images` or Ceph RADOS GW (at all) from compute nodes and UANs.

      Use `rgw-vip` as it will resolve to one of the storage nodes.

      ```bash
      nid000002# host rgw-vip
      rgw-vip has address 10.252.1.3

      nid000002# curl http://rgw-vip/ncn-images/
      <html><body><h1>403 Forbidden</h1>
      Request forbidden by administrative rules.
      </body></html>

      nid000002# curl -k https://rgw-vip/ncn-images/
      <html><body><h1>403 Forbidden</h1>
      Request forbidden by administrative rules.
      </body></html>

      nid000002# curl --connect-timeout 2 rgw-vip:8080
      curl: (28) Connection timed out after 2001 milliseconds
      ```

      Look for a 403 response in the HAProxy logs:

      ```bash
      ncn-m001# pdsh -N -w ncn-s00[1-4] "cd /var/log && zgrep -h -i -E 'haproxy.*frontend' messages || exit 0" | grep "ncn-images"
      2022-07-13T13:57:08+00:00 xxx-ncn-s001.local haproxy[43591]: 10.252.1.13:50238 [13/Jul/2022:13:57:08.363] http-rgw-frontend http-rgw-frontend/<NOSRV> 0/-1/-1/-1/0 403 212 - - PR-- 1/1/0/0/0 0/0 "GET /ncn-images/ HTTP/1.1"
      2022-07-13T14:01:11+00:00 xxx-ncn-s001.local haproxy[43591]: 10.252.1.13:50240 [13/Jul/2022:14:01:11.038] http-rgw-frontend http-rgw-frontend/<NOSRV> 0/-1/-1/-1/0 403 212 - - PR-- 1/1/0/0/0 0/0 "GET /ncn-images/ HTTP/1.1"
      ...
      ```

      In the firewall logs, the Ceph RADOS GW traffic will be dropped on the storage node. For example:

      ```bash
      ncn-m001# pdsh -N -w ncn-s00[1-4] "grep RADOSGW /var/log/firewall"
      2022-07-13T14:02:03.418750+00:00 xxx-ncn-s001 kernel: [4397628.546654] RADOSGW-DROPIN=vlan002 OUT= MAC=b8:59:9f:f9:1d:22:a4:bf:01:3f:6f:91:08:00 SRC=10.252.1.13 DST=10.252.1.3 LEN=52 TOS=0x00 PREC=0x00 TTL=64 ID=9727 DF PROTO=TCP SPT=59278 DPT=8080 WINDOW=42340 RES=0x00 SYN URGP=0 
      ...
      ```

      For further validation, the following script can be saved to a UAN or compute node with a storage node count as an input.

      This will test cross-network select access that should not be possible based on a correctly configured switch ACL posture, as well.

      ```bash
      nid000002# cat user_con_test.sh 
      CURL_O="--connect-timeout 2 -f"
      NODE_COUNT="$1"

      function curl_rept
      {
         echo -n "[i] $1 -> "
         $1 &> /dev/null
         if [ $? -ne 0 ]
         then
            echo "PASS"
         else
            echo "FAIL"
         fi
         return
      } 

      for n in `seq 1 $NODE_COUNT`
      do
         for t in nmn can hmn
         do
            curl_rept "curl $CURL_O ncn-s00${n}.${t}:8080" # ceph rados
            curl_rept "curl $CURL_O http://ncn-s00${n}.${t}/ncn-images/" # ncn images, http
            curl_rept "curl $CURL_O -k  https://ncn-s00${n}.${t}/ncn-images/" # ncn images, https
         done
      done

      nid000002# bash ./user_con_test.sh 4
      [i] curl --connect-timeout 2 -f ncn-s001.nmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s001.nmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s001.nmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s001.can:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s001.can/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s001.can/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s001.hmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s001.hmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s001.hmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s002.nmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s002.nmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s002.nmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s002.can:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s002.can/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s002.can/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s002.hmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s002.hmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s002.hmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s003.nmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s003.nmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s003.nmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s003.can:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s003.can/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s003.can/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s003.hmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s003.hmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s003.hmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s004.nmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s004.nmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s004.nmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s004.can:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s004.can/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s004.can/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s004.hmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s004.hmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s004.hmn/ncn-images/ -> PASS
      ```

24. Save the `iptables` rule set on all storage nodes and make it persistent across reboots.

      Create a directory to hold the `iptables` configuration.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "mkdir --mode=750 /etc/iptables"
      ```

      Create a one-shot systemd service to load iptables on system boot.

      ```bash
      ncn-m001# cat << EOF > metal-iptables.service
      [Unit]
      Description=Loads Metal iptables config
      After=local-fs.target network.service

      [Service]
      Type=oneshot
      ExecStart=/usr/sbin/iptables-restore /etc/iptables/metal.conf
      Restart=no
      RemainAfterExit=no

      [Install]
      WantedBy=multi-user.target
      EOF

      ncn-m001# chmod 640 metal-iptables.service
      ```

      Distribute the one-shot systemd service to the storage nodes.

      ```bash
      ncn-m001# pdcp -w ncn-s00[1-4] metal-iptables.service /usr/lib/systemd/system
      ```

      Enable the service.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "systemctl enable metal-iptables.service"
      ```

      Use `iptables-save` to commit running rules to the persistent configuration.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "iptables-save -f /etc/iptables/metal.conf"
      ```

      Execute the one-shot systemd service.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "systemctl start metal-iptables.service"
      ```

      Verify the rule set is consistent across nodes.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "cat /etc/iptables/metal.conf" | grep "8080" | dshbak -c
      ----------------
      ncn-s[001-004]
      ----------------
      -A INPUT -i vlan004 -p tcp -m tcp --dport 8080 -j ACCEPT
      -A INPUT -i lo -p tcp -m tcp --dport 8080 -j ACCEPT
      -A INPUT -p tcp -m tcp --dport 8080 -m iprange --src-range 10.252.1.4-10.252.1.14 -j ACCEPT
      -A INPUT -p tcp -m tcp --dport 8080 -j LOG --log-prefix RADOSGW-DROP
      -A INPUT -p tcp -m tcp --dport 8080 -j DROP
      ```

## Troubleshooting

**NOTE**: If SMA log forwarders are not yet running, then it might be necessary to temporarily disable the `/etc/rsyslog.d/01-cray-rsyslog.conf` rule (for logs to flow to the local nodes without delay).
Restart `rsyslog` if this action is required.

Look for RADOSGW drops in `/var/log/firewall` on storage nodes, note that the connectivity test will attempt access on the CAN.

```bash
ncn-m001# pdsh -N -w ncn-s00[1-4] "grep RADOSGW /var/log/firewall" | grep vlan007 | head -3
2022-08-01T21:22:01.049443+00:00 ncn-s003 kernel: [13242021.397679] RADOSGW-DROPIN=vlan007 OUT= MAC=14:02:ec:d9:79:d0:94:40:c9:5f:9a:84:08:00 SRC=10.103.13.13 DST=10.103.13.5 LEN=60 TOS=0x00 PREC=0x00 TTL=64 ID=35159 DF PROTO=TCP SPT=60482 DPT=8080 WINDOW=42340 RES=0x00 SYN URGP=0 
2022-08-01T21:22:05.061945+00:00 ncn-s001 kernel: [13248180.144514] RADOSGW-DROPIN=vlan007 OUT= MAC=14:02:ec:da:bc:68:94:40:c9:5f:9a:84:08:00 SRC=10.103.13.13 DST=10.103.13.7 LEN=60 TOS=0x00 PREC=0x00 TTL=64 ID=10604 DF PROTO=TCP SPT=43034 DPT=8080 WINDOW=42340 RES=0x00 SYN URGP=0 
2022-08-01T21:22:02.047541+00:00 ncn-s003 kernel: [13242022.399499] RADOSGW-DROPIN=vlan007 OUT= MAC=14:02:ec:d9:79:d0:94:40:c9:5f:9a:84:08:00 SRC=10.103.13.13 DST=10.103.13.5 LEN=60 TOS=0x00 PREC=0x00 TTL=64 ID=35160 DF PROTO=TCP SPT=60482 DPT=8080 WINDOW=42340 RES=0x00 SYN URGP=0 
...
```

Look for HAProxy access logs in `/var/log/messages` on storage nodes that have HTTP 403 responses (or other responses depending upon context).

```bash
ncn-m001# pdsh -N -w ncn-s00[1-3] "cd /var/log && zgrep -h 'haproxy.*frontend' messages || exit 0" | grep " 403 " | sort -k 1
2022-08-01T21:36:28+00:00 localhost haproxy[20903]: 10.252.1.20:37248 [01/Aug/2022:21:36:28.679] http-rgw-frontend http-rgw-frontend/<NOSRV> 0/-1/-1/-1/0 403 212 - - PR-- 1/1/0/0/0 0/0 "GET /ncn-images/ HTTP/1.1"
2022-08-01T21:36:57+00:00 localhost haproxy[20903]: 10.252.1.20:53358 [01/Aug/2022:21:36:57.898] https-rgw-frontend~ https-rgw-frontend/<NOSRV> 0/-1/-1/-1/0 403 212 - - PR-- 1/1/0/0/0 0/0 "GET /ncn-images/ HTTP/1.1"
2022-08-01T21:39:35+00:00 localhost haproxy[20903]: 10.252.1.20:40400 [01/Aug/2022:21:39:35.141] https-rgw-frontend~ https-rgw-frontend/<NOSRV> 1/-1/-1/-1/1 403 212 - - PR-- 1/1/0/0/0 0/0 "GET /ncn-images/ HTTP/1.1"
2022-08-01T21:39:35+00:00 localhost haproxy[20903]: 10.252.1.20:57530 [01/Aug/2022:21:39:35.134] http-rgw-frontend http-rgw-frontend/<NOSRV> 0/-1/-1/-1/0 403 212 - - PR-- 1/1/0/0/0 0/0 "GET /ncn-images/ HTTP/1.1"
2022-08-01T21:39:37+00:00 localhost haproxy[20903]: 10.252.1.20:34828 [01/Aug/2022:21:39:37.152] http-rgw-frontend http-rgw-frontend/<NOSRV> 0/-1/-1/-1/0 403 212 - - PR-- 1/1/0/0/0 0/0 "GET /ncn-images/ HTTP/1.1"
2022-08-01T21:39:37+00:00 localhost haproxy[20903]: 10.252.1.20:57896 [01/Aug/2022:21:39:37.159] https-rgw-frontend~ https-rgw-frontend/<NOSRV> 0/-1/-1/-1/0 403 212 - - PR-- 1/1/0/0/0 0/0 "GET /ncn-images/ HTTP/1.1"
```