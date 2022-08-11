# Restrict Network Access to the `ncn-images` S3 Bucket

The configuration documented in this procedure is intended to prevent user-facing dedicated nodes (UANs, Compute Nodes) from retrieving NCN image content from Ceph S3 services, as running on storage nodes.

Specifically, the controls enacted via this procedure should do the following:

1. Block HAProxy access to the `ncn-images` bucket if the client is not an NCN (NMN) or PXE booting from the MTL network. This via a HAProxy ACL on the storage servers.
2. Enable access logging for HAProxy.
3. Block Rados GW network access (port 8080) to if the client is not an NCN (NMN) or originating from the HMN network. This via `iptables` rules on the storage servers.

## Limitations

This is not designed to prevent UAIs (if in use) from retrieving NCN image content.

If a storage node is rebuilt, this procedure (for the rebuilt node) will need to be applied after the rebuild. The same is true if NCNs are added or removed from the system.

## Prerequisites and scope

Procedure should be executed after install or upgrade is otherwise complete, but prior to opening the system for user access.

Unless otherwise noted, the procedure should be run from `ncn-m001` (not PIT).  

The configuration applied in this procedure was tested against barebones images boot, FAS firmware upgrade and downgrade, and NCN rebuilds. The version tested was CSM 1.2.0.

## Procedure

1. Test connectivity before applying the ACL.

   Save the following script to a file (for example, `con_test.sh`).

   ```bash
   #!/bin/bash


   SNCNS="$(grep 'ncn-s.*\.nmn' /etc/hosts | awk '{print $NF;}' | xargs)"
   SCSNS_NMN="$(echo $SNCNS | xargs -n 1 | sed -e 's/$/.nmn/g')"
   SCSNS_HMN="$(echo $SNCNS | xargs -n 1 | sed -e 's/$/.hmn/g')"
   SCSNS_CMN="$(echo $SNCNS | xargs -n 1 | sed -e 's/$/.cmn/g')"

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
   rados_test "$SCSNS_CMN" "MGMT RADOS over CMN" "CONN_FAIL"
   haproxy_test "$SCSNS_NMN" "MGMT HAProxy over NMN"
   ```

   Execute the script, if the ACLs have not been applied, results similar to the following will be returned:

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
   [i] MGMT RADOS over CMN
   RADOS ncn-s001.cmn: FAIL
   RADOS ncn-s002.cmn: FAIL
   RADOS ncn-s003.cmn: FAIL
   [i] MGMT HAProxy over NMN
   HAPROXY (CEPH) HTTP ncn-s001.nmn: PASS
   HAPROXY (CEPH) HTTPS ncn-s001.nmn: PASS
   HAPROXY (CEPH) HTTP ncn-s002.nmn: PASS
   HAPROXY (CEPH) HTTPS ncn-s002.nmn: PASS
   HAPROXY (CEPH) HTTP ncn-s003.nmn: PASS
   HAPROXY (CEPH) HTTPS ncn-s003.nmn: PASS
   ```

2. Configure HAProxy ACLs and logging.

   Required to limit RGW VIP access for the `ncn-images` bucket to only management NCNs.

3. Build an IP address list of NCNs on the NMN.

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

4. Add the MTL subnet (needed for network boots of NCNs).

   ```bash
   ncn-m001# echo '10.1.0.0/16' >> allowed_ncns.lst
   ```

5. Verify the `allowed_ncns.lst` contains contain NMN addresses for all management NCNs nodes and the MTL subnet (10.1.0.0/16).

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

6. Confirm HAProxy configurations are identical across storage nodes.

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

7. Create a backup of `haproxy.cfg` files on storage nodes.

   ```bash
   ncn-m001# pdsh -w ncn-s00[1-4] "cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg-dist"
   ```

8. Grab a copy of `haproxy.cfg` to modify from a storage node, preserving permissions.

   ```bash
   ncn-m001# scp -p ncn-s001:/etc/haproxy/haproxy.cfg . 
   haproxy.cfg            
   ```

9. Edit the `haproxy.cfg`, adding in the following ACLs and log directives to each front-end.

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

10. Create a new `rsyslog` configuration for HAProxy to have it listen to UDP 514 on the local host.

    With the log directive additions to HAProxy, and allowing a local host UDP 514 socket, access logging should work properly. Set permissions to 640 on the file.

    ```bash
    ncn-m001# cat haproxy.conf 
    # Collect log with UDP
    $ModLoad imudp
    $UDPServerAddress 127.0.0.1
    $UDPServerRun 514

    ncn-m001# chmod 0640 haproxy.conf 
    ```

11. Make sure HAProxy is running on storage nodes.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "systemctl status haproxy" | grep "Active"
      ncn-s001:      Active: active (running) since Thu 2022-07-07 17:38:49 UTC; 54min ago
      ncn-s003:      Active: active (running) since Thu 2022-07-07 17:38:49 UTC; 54min ago
      ncn-s002:      Active: active (running) since Thu 2022-07-07 17:38:49 UTC; 54min ago
      ncn-s004:      Active: active (running) since Thu 2022-07-07 17:38:49 UTC; 54min ago
      ```

12. Determine where the HAProxy VIP currently resides (for awareness in the event debug is necessary).

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

13. Propagate the `rsyslog` configuration out to all storage nodes.

      ```bash
      ncn-m001# pdcp -w ncn-s00[1-4] haproxy.conf /etc/rsyslog.d/
      ```

14. Propagate the HAProxy configuration out to all storage nodes.

      ```bash
      ncn-m001# pdcp -w ncn-s00[1-4] haproxy.cfg allowed_ncns.lst /etc/haproxy/
      ```

15. Verify the configurations are identical across storage nodes.

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

16. Restart `rsyslog` across all storage nodes.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "systemctl restart rsyslog"
      ncn-m001# pdsh -w ncn-s00[1-4] "systemctl status rsyslog" | grep Active
      ncn-s001:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ncn-s002:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ncn-s003:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ncn-s004:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ```

17. Restart HAProxy across all storage nodes.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "systemctl restart haproxy"
      ncn-m001# pdsh -w ncn-s00[1-4] "systemctl status haproxy" | grep Active
      ncn-s001:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ncn-s002:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ncn-s003:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ncn-s004:      Active: active (running) since Thu 2022-07-07 13:50:39 UTC; 7s ago
      ```

18. Apply server-side `iptables` rules to storage nodes.

      This is needed to prevent direct access to the Ceph Rados GW Service (not through HAProxy).

      The process is written to support change on individual nodes, but could be scripted after analysis of the running firewall rule set (notably with respect to local modifications, if they exist).

      This process must be completed on each storage node (steps 19 - 22) before continuing to subsequent steps.

19. Document where Rados GW is running (port wise).

      ```bash
      ncn-s001# ss -tnpl | grep rados
      LISTEN    0         128                0.0.0.0:8080             0.0.0.0:*        users:(("radosgw",pid=25018,fd=77))                                            
      LISTEN    0         128                   [::]:8080                [::]:*        users:(("radosgw",pid=25018,fd=78))  
      ```

20. List existing `iptables` rules.

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

21. Run the following to add `iptables` rules for control.

      The range should include all NMN NCN IP addresses generated for the HAProxy ACL step.

      ```bash
      iptables -A INPUT -i bond0.hmn0 -p tcp --dport 8080 -j ACCEPT
      iptables -A INPUT -i lo -p tcp --dport 8080 -j ACCEPT
      iptables -A INPUT -p tcp --dport 8080 -m iprange --src-range 10.252.1.4-10.252.1.14 -j ACCEPT
      iptables -A INPUT -p tcp --dport 8080 -j LOG --log-prefix "RADOSGW-DROP"
      iptables -A INPUT -p tcp --dport 8080 -j DROP
      ```

22. List `iptables` rules again, verify rules are in place.

      ```bash
      ncn-s001# iptables -L -nx -v
      Chain INPUT (policy ACCEPT 22144 packets, 28721015 bytes)
         pkts      bytes target     prot opt in     out     source               destination         
            0        0 DROP       tcp  --  *      *       0.0.0.0/0            10.102.4.135         tcp dpt:22
            0        0 ACCEPT     tcp  --  bond0.hmn0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080
            85     4862 ACCEPT     tcp  --  lo     *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080
         276    15438 ACCEPT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 source IP range 10.252.1.4-10.252.1.14
            0        0 LOG        tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 LOG flags 0 level 4 prefix "RADOSGW-DROP"
            0        0 DROP       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080

      Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
         pkts      bytes target     prot opt in     out     source               destination         

      Chain OUTPUT (policy ACCEPT 22099 packets, 30141111 bytes)
         pkts      bytes target     prot opt in     out     source               destination   
      ```

23. Test connectivity after applying the ACL.

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
      [i] MGMT RADOS over CMN
      RADOS ncn-s001.cmn: PASS
      RADOS ncn-s002.cmn: PASS
      RADOS ncn-s003.cmn: PASS
      [i] MGMT HAProxy over NMN
      HAPROXY (CEPH) HTTP ncn-s001.nmn: PASS
      HAPROXY (CEPH) HTTPS ncn-s001.nmn: PASS
      HAPROXY (CEPH) HTTP ncn-s002.nmn: PASS
      HAPROXY (CEPH) HTTPS ncn-s002.nmn: PASS
      HAPROXY (CEPH) HTTP ncn-s003.nmn: PASS
      HAPROXY (CEPH) HTTPS ncn-s003.nmn: PASS
      ```

24. Validate no connection can be made to HAProxy for `ncn-images` or Ceph RADOS GW (at all) from compute nodes and UANs.

      Use `rgw-vip` as it will resolve to one of the storage nodes.

      ```bash
      nid000002# host rgw-vip
      rgw-vip has address 10.252.1.3

      nid000002# curl http://rgw-vip/ncn-images/
      <html><body><h1>403 Forbidden</h1>
      Request forbidden by administrative rules.
      </body></html>

      nid000002# curl --connect-timeout 2 rgw-vip:8080
      curl: (28) Connection timed out after 2001 milliseconds
      ```

      Look for a 403 response in the HAProxy logs:

      ```bash
      ncn-m001# pdsh -N -w ncn-s00[1-4] "cd /var/log && zgrep -h -i -E 'haproxy.*frontend' messages || exit 0" | grep "ncn-images" | grep "10.252.1.13"
      2022-07-13T13:57:08+00:00 xxx-ncn-s001.local haproxy[43591]: 10.252.1.13:50238 [13/Jul/2022:13:57:08.363] http-rgw-frontend http-rgw-frontend/<NOSRV> 0/-1/-1/-1/0 403 212 - - PR-- 1/1/0/0/0 0/0 "GET /ncn-images/ HTTP/1.1"
      2022-07-13T14:01:11+00:00 xxx-ncn-s001.local haproxy[43591]: 10.252.1.13:50240 [13/Jul/2022:14:01:11.038] http-rgw-frontend http-rgw-frontend/<NOSRV> 0/-1/-1/-1/0 403 212 - - PR-- 1/1/0/0/0 0/0 "GET /ncn-images/ HTTP/1.1"
      ```

      In the firewall logs, the Ceph RADOS GW traffic will be dropped on the storage node. For example:

      ```bash
      ncn-m001# pdsh -N -w ncn-s00[1-4] "grep RADOSGW /var/log/firewall" | grep "10.252.1.13" | head -1
      2022-07-13T14:02:03.418750+00:00 xxx-ncn-s001 kernel: [4397628.546654] RADOSGW-DROPIN=bond0.nmn0 OUT= MAC=b8:59:9f:f9:1d:22:a4:bf:01:3f:6f:91:08:00 SRC=10.252.1.13 DST=10.252.1.3 LEN=52 TOS=0x00 PREC=0x00 TTL=64 ID=9727 DF PROTO=TCP SPT=59278 DPT=8080 WINDOW=42340 RES=0x00 SYN URGP=0 
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
         for t in nmn cmn hmn
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
      [i] curl --connect-timeout 2 -f ncn-s001.cmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s001.cmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s001.cmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s001.hmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s001.hmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s001.hmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s002.nmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s002.nmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s002.nmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s002.cmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s002.cmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s002.cmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s002.hmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s002.hmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s002.hmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s003.nmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s003.nmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s003.nmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s003.cmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s003.cmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s003.cmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s003.hmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s003.hmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s003.hmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s004.nmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s004.nmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s004.nmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s004.cmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s004.cmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s004.cmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f ncn-s004.hmn:8080 -> PASS
      [i] curl --connect-timeout 2 -f http://ncn-s004.hmn/ncn-images/ -> PASS
      [i] curl --connect-timeout 2 -f -k https://ncn-s004.hmn/ncn-images/ -> PASS
      ```

25. Save the `iptables` rule set on all storage nodes.

      `iptables` is currently reloaded via a one shot `systemd` service.

      ```bash
      ncn-s001:/usr/lib/systemd # cat ./system/metal-iptables.service 
      [Unit]
      Description=Loads Metal iptables config
      After=local-fs.target network.service

      [Service]
      Type=oneshot
      ExecStart=iptables-restore /etc/iptables/metal.conf
      Restart=no
      RemainAfterExit=no

      [Install]
      WantedBy=multi-user.target
      ```

      Make a backup of the firewall rules.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "cp -a /etc/iptables/metal.conf /etc/iptables/metal.conf-dist"
      ```

      Use `iptables-save` to commit running rules to the persistent configuration.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "iptables-save -f /etc/iptables/metal.conf"
      ```

      Verify the rule set is consistent across nodes.

      ```bash
      ncn-m001# pdsh -w ncn-s00[1-4] "cat /etc/iptables/metal.conf" | grep "8080" | dshbak -c
      ----------------
      ncn-s[001-004]
      ----------------
      -A INPUT -i bond0.hmn0 -p tcp -m tcp --dport 8080 -j ACCEPT
      -A INPUT -i lo -p tcp -m tcp --dport 8080 -j ACCEPT
      -A INPUT -p tcp -m tcp --dport 8080 -m iprange --src-range 10.252.1.4-10.252.1.14 -j ACCEPT
      -A INPUT -p tcp -m tcp --dport 8080 -j LOG --log-prefix RADOSGW-DROP
      -A INPUT -p tcp -m tcp --dport 8080 -j DROP
      ```

## Troubleshooting

**NOTE**: If SMA log forwarders are not yet running, then it might be necessary to temporarily disable the `/etc/rsyslog.d/01-cray-rsyslog.conf` rule (for logs to flow to the local nodes without delay).
Restart `rsyslog` if this action is required.

Look for RADOSGW drops in `/var/log/firewall` on storage nodes, not that the connectivity test will attempt access on the CMN.

```bash
ncn-m001# pdsh -N -w ncn-s00[1-3] "grep RADOSGW /var/log/firewall"
2022-07-11T19:26:22.655077+00:00 xxx-ncn-s003 kernel: [265870.330981] RADOSGW-DROPIN=bond0.cmn0 OUT= MAC=b8:59:9f:f9:1b:fa:b8:59:9f:f9:1b:fe:08:00 SRC=10.101.8.35 DST=10.101.8.43 LEN=60 TOS=0x00 PREC=0x00 TTL=64 ID=1170 DF PROTO=TCP SPT=52462 DPT=8080 WINDOW=35840 RES=0x00 SYN URGP=0 
2022-07-11T19:26:23.690023+00:00 xxx-ncn-s003 kernel: [265871.365959] RADOSGW-DROPIN=bond0.cmn0 OUT= MAC=b8:59:9f:f9:1b:fa:b8:59:9f:f9:1b:fe:08:00 SRC=10.101.8.35 DST=10.101.8.43 LEN=60 TOS=0x00 PREC=0x00 TTL=64 ID=1171 DF PROTO=TCP SPT=52462 DPT=8080 WINDOW=35840 RES=0x00 SYN URGP=0 
...
```

Look for HAProxy access logs in `/var/log/messages` on storage nodes that have HTTP 403 responses (or other responses depending upon context).

```bash
ncn-m001# pdsh -N -w ncn-s00[1-3] "cd /var/log && zgrep -h 'haproxy.*frontend' messages || exit 0" | grep " 403 " | sort -k 1
```
