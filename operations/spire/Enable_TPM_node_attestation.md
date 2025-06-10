# Enable TPM node attestation with Spire

Spire supports node attestation with Trusted Platform Modules installed on CSM
nodes. Currently there is support for all x86 based nodes. This support changes
the way nodes are attested with spire to use the certificates that are created
in the TPM. The Spire agent uses the TPM to join the Spire server instead of a
join token.

## Enable TPM node attestation

To enable TPM node attestation on the management nodes, there is a simple script
that can enable it for all nodes that have a TPM. To reverse enabling TPM attestation
for management nodes, there is a manual process that needs to be run.

To enable TPM node attestation on managed nodes, there is a multi-step process requiring
the node to be rebooted multiple times. During the attestation process on a managed
node, the node will not be accessible until it has finished joining spire. Reversing
the process requires another set of node reboots where the node is not accessible.

### Enable TPM node attestation for Management nodes

```bash
/opt/cray/platform-utils/spire/spire-enable-tpm.sh
```

Example Output

```bash
ncn-m001:~ # /opt/cray/platform-utils/spire/spire-enable-tpm.sh
Warning: Permanently added 'ncn-m002' (ED25519) to the list of known hosts.
Warning: Permanently added 'ncn-m002' (ED25519) to the list of known hosts.
{"success":true}
Warning: Permanently added 'ncn-m002' (ED25519) to the list of known hosts.
2025/04/02 20:10:03 url: https://api-gw-service-nmn.local/apis/tpm-provisioner
2025/04/02 20:10:03 xname: x3000c0s2b0n0
2025/04/02 20:10:03 type: ncn
2025/04/02 20:10:03 req: &{Method:GET URL:https://api-gw-service-nmn.local/apis/tpm-provisioner/authorize?xname=x3000c0s2b0n0&type=ncn Proto:HTTP/1.1 ProtoMajor:1 ProtoMinor:1 Header:map[] Body:<nil> GetBody:<nil> ContentLength:0 TransferEncoding:[] Close:false Host:api-gw-service-nmn.local Form:map[] PostForm:map[] MultipartForm:<nil> Trailer:map[] RemoteAddr: RequestURI: TLS:<nil> Cancel:<nil> Response:<nil> ctx:{emptyCtx:{}}}
time="2025-04-02T20:10:03Z" level=info msg="Reading EK certificate from NV index 01c00002"
time="2025-04-02T20:10:04Z" level=info msg="Get Endorsement Key (RSA)"
time="2025-04-02T20:10:04Z" level=info msg="Get Attestation Key (RSA)"
time="2025-04-02T20:10:06Z" level=info msg="Get DevID (RSA)"
time="2025-04-02T20:10:07Z" level=info msg="Certifying TPM-residency of keys"
time="2025-04-02T20:10:07Z" level=info msg="CSR creation complete! [3]"
Warning: Permanently added 'ncn-m002' (ED25519) to the list of known hosts.
ncn-m002 is being joined to spire.
Warning: Permanently added 'ncn-m002' (ED25519) to the list of known hosts.
spire-tpm-conf.conf                                                                                                                                                                                                                                                                        100%  726     1.1MB/s   00:00
Warning: Permanently added 'ncn-m002' (ED25519) to the list of known hosts.
Warning: Permanently added 'ncn-w001' (ED25519) to the list of known hosts.
Warning: Permanently added 'ncn-w001' (ED25519) to the list of known hosts.
{"success":true}
Warning: Permanently added 'ncn-w001' (ED25519) to the list of known hosts.
2025/04/02 20:10:15 url: https://api-gw-service-nmn.local/apis/tpm-provisioner
2025/04/02 20:10:15 xname: x3000c0s7b0n0
2025/04/02 20:10:15 type: ncn
2025/04/02 20:10:15 req: &{Method:GET URL:https://api-gw-service-nmn.local/apis/tpm-provisioner/authorize?xname=x3000c0s7b0n0&type=ncn Proto:HTTP/1.1 ProtoMajor:1 ProtoMinor:1 Header:map[] Body:<nil> GetBody:<nil> ContentLength:0 TransferEncoding:[] Close:false Host:api-gw-service-nmn.local Form:map[] PostForm:map[] MultipartForm:<nil> Trailer:map[] RemoteAddr: RequestURI: TLS:<nil> Cancel:<nil> Response:<nil> ctx:{emptyCtx:{}}}
time="2025-04-02T20:10:15Z" level=info msg="Reading EK certificate from NV index 01c00002"
time="2025-04-02T20:10:15Z" level=info msg="Get Endorsement Key (RSA)"
time="2025-04-02T20:10:15Z" level=info msg="Get Attestation Key (RSA)"
time="2025-04-02T20:10:23Z" level=info msg="Get DevID (RSA)"
time="2025-04-02T20:10:23Z" level=info msg="Certifying TPM-residency of keys"
time="2025-04-02T20:10:24Z" level=info msg="CSR creation complete! [3]"
Warning: Permanently added 'ncn-w001' (ED25519) to the list of known hosts.
ncn-w001 is being joined to spire.
Warning: Permanently added 'ncn-w001' (ED25519) to the list of known hosts.
spire-tpm-conf.conf                                                                                                                                                                                                                                                                        100%  726     1.3MB/s   00:00
Warning: Permanently added 'ncn-w001' (ED25519) to the list of known hosts.
Warning: Permanently added 'ncn-w002' (ED25519) to the list of known hosts.
Warning: Permanently added 'ncn-w002' (ED25519) to the list of known hosts.
{"success":true}
Warning: Permanently added 'ncn-w002' (ED25519) to the list of known hosts.
2025/04/02 20:10:31 url: https://api-gw-service-nmn.local/apis/tpm-provisioner
2025/04/02 20:10:31 xname: x3000c0s8b0n0
2025/04/02 20:10:31 type: ncn
2025/04/02 20:10:31 req: &{Method:GET URL:https://api-gw-service-nmn.local/apis/tpm-provisioner/authorize?xname=x3000c0s8b0n0&type=ncn Proto:HTTP/1.1 ProtoMajor:1 ProtoMinor:1 Header:map[] Body:<nil> GetBody:<nil> ContentLength:0 TransferEncoding:[] Close:false Host:api-gw-service-nmn.local Form:map[] PostForm:map[] MultipartForm:<nil> Trailer:map[] RemoteAddr: RequestURI: TLS:<nil> Cancel:<nil> Response:<nil> ctx:{emptyCtx:{}}}
time="2025-04-02T20:10:31Z" level=info msg="Reading EK certificate from NV index 01c00002"
time="2025-04-02T20:10:31Z" level=info msg="Get Endorsement Key (RSA)"
time="2025-04-02T20:10:31Z" level=info msg="Get Attestation Key (RSA)"
time="2025-04-02T20:11:02Z" level=info msg="Get DevID (RSA)"
time="2025-04-02T20:11:03Z" level=info msg="Certifying TPM-residency of keys"
time="2025-04-02T20:11:03Z" level=info msg="CSR creation complete! [3]"
Warning: Permanently added 'ncn-w002' (ED25519) to the list of known hosts.
ncn-w002 is being joined to spire.
Warning: Permanently added 'ncn-w002' (ED25519) to the list of known hosts.
spire-tpm-conf.conf                                                                                                                                                                                                                                                                        100%  726     1.8MB/s   00:00
Warning: Permanently added 'ncn-w002' (ED25519) to the list of known hosts.
Warning: Permanently added 'ncn-w003' (ED25519) to the list of known hosts.
Warning: Permanently added 'ncn-w003' (ED25519) to the list of known hosts.
{"success":true}
Warning: Permanently added 'ncn-w003' (ED25519) to the list of known hosts.
2025/04/02 20:11:11 url: https://api-gw-service-nmn.local/apis/tpm-provisioner
2025/04/02 20:11:11 xname: x3000c0s9b0n0
2025/04/02 20:11:11 type: ncn
2025/04/02 20:11:11 req: &{Method:GET URL:https://api-gw-service-nmn.local/apis/tpm-provisioner/authorize?xname=x3000c0s9b0n0&type=ncn Proto:HTTP/1.1 ProtoMajor:1 ProtoMinor:1 Header:map[] Body:<nil> GetBody:<nil> ContentLength:0 TransferEncoding:[] Close:false Host:api-gw-service-nmn.local Form:map[] PostForm:map[] MultipartForm:<nil> Trailer:map[] RemoteAddr: RequestURI: TLS:<nil> Cancel:<nil> Response:<nil> ctx:{emptyCtx:{}}}
time="2025-04-02T20:11:11Z" level=info msg="Reading EK certificate from NV index 01c00002"
time="2025-04-02T20:11:11Z" level=info msg="Get Endorsement Key (RSA)"
time="2025-04-02T20:11:11Z" level=info msg="Get Attestation Key (RSA)"
time="2025-04-02T20:11:20Z" level=info msg="Get DevID (RSA)"
time="2025-04-02T20:11:20Z" level=info msg="Certifying TPM-residency of keys"
time="2025-04-02T20:11:21Z" level=info msg="CSR creation complete! [3]"
Warning: Permanently added 'ncn-w003' (ED25519) to the list of known hosts.
ncn-w003 is being joined to spire.
Warning: Permanently added 'ncn-w003' (ED25519) to the list of known hosts.
spire-tpm-conf.conf                                                                                                                                                                                                                                                                        100%  726     1.3MB/s   00:00
Warning: Permanently added 'ncn-w003' (ED25519) to the list of known hosts.
Warning: Permanently added 'ncn-w004' (ED25519) to the list of known hosts.
Warning: Permanently added 'ncn-w004' (ED25519) to the list of known hosts.
{"success":true}
Warning: Permanently added 'ncn-w004' (ED25519) to the list of known hosts.
2025/04/02 20:11:26 url: https://api-gw-service-nmn.local/apis/tpm-provisioner
2025/04/02 20:11:26 xname: x3000c0s10b0n0
2025/04/02 20:11:26 type: ncn
2025/04/02 20:11:26 req: &{Method:GET URL:https://api-gw-service-nmn.local/apis/tpm-provisioner/authorize?xname=x3000c0s10b0n0&type=ncn Proto:HTTP/1.1 ProtoMajor:1 ProtoMinor:1 Header:map[] Body:<nil> GetBody:<nil> ContentLength:0 TransferEncoding:[] Close:false Host:api-gw-service-nmn.local Form:map[] PostForm:map[] MultipartForm:<nil> Trailer:map[] RemoteAddr: RequestURI: TLS:<nil> Cancel:<nil> Response:<nil> ctx:{emptyCtx:{}}}
time="2025-04-02T20:11:26Z" level=info msg="Reading EK certificate from NV index 01c00002"
time="2025-04-02T20:11:26Z" level=info msg="Get Endorsement Key (RSA)"
time="2025-04-02T20:11:27Z" level=info msg="Get Attestation Key (RSA)"
time="2025-04-02T20:11:32Z" level=info msg="Get DevID (RSA)"
time="2025-04-02T20:11:33Z" level=info msg="Certifying TPM-residency of keys"
time="2025-04-02T20:11:33Z" level=info msg="CSR creation complete! [3]"
Warning: Permanently added 'ncn-w004' (ED25519) to the list of known hosts.
ncn-w004 is being joined to spire.
Warning: Permanently added 'ncn-w004' (ED25519) to the list of known hosts.
spire-tpm-conf.conf                                                                                                                                                                                                                                                                        100%  726     1.7MB/s   00:00
Warning: Permanently added 'ncn-w004' (ED25519) to the list of known hosts.
```

### Disable TPM attestation on management nodes

To disable the TPM attestation on management nodes, the `spire-agent.conf`
file must be returned to its original configuration on each node where TPM attestation
is turned on. Then a new join token must be created and the node then needs
to be joined to Spire.

Disabling TPM attestation on all management nodes at the same time can be done with a
script that is installed on the master nodes. If only one node is required to be changed
back to standard attestation then it can be manually changed with a few steps.

To disable TPM node attestation on all nodes and return it to standard:

```bash
/opt/cray/platform-utils/spire/spire-disable-tpm.sh
```

Or on each node that you want to disable TPM attestation on:

1. (`ncn-mw#`) Stop the `spire-agent` service

   ```bash
   systemctl stop spire-agent
   ```

1. (`ncn-mw#`) Remove old Spire data

   ```bash
   rm /var/lib/spire/conf/spire-agent.conf /var/lib/spire/data/keys.json /var/lib/spire/data/svid.key /var/lib/spire/bundle.der /var/lib/spire/agent_svid.der
   ```

1. (`ncn-mw#`) Restart the `request-ncn-join-token` Daemon Set

   ```bash
   kubectl rollout restart -n spire DaemonSet/request-ncn-join-token
   ```

1. (`ncn-mw#`) Restart the `spire-agent` service

   ```bash
   systemctl start spire-agent
   ```

### Enable TPM node attestation on managed nodes

To enable TPM node attestation on managed nodes the node
needs to be rebooted at least 2 times. This also requires making
multiple BOS session templates and changing the session template
during each reboot so the node can attest with Spire properly.

For each node that needs TPM node attestation:

1. (`ncn-mw#`) Whitelist the nodes xname

   ```bash
   XNAME=x3000c0s19b1n0
   KC_TOKEN=$(jq -r '.access_token' /root/.config/cray/tokens/api_gw_service_nmn_local.* | head -1)
   curl -H "Authorization: Bearer $KC_TOKEN" -d "xname=$XNAME" https://api-gw-service-nmn.local/apis/tpm-provisioner/whitelist/add
   ```

1. (`ncn-mw#`) Create the BOS templates with different kernel parameters
   1. The enrollment parameters:

      ```text
      kernel_parameters = "ip=dhcp quiet spire_join_token=${SPIRE_JOIN_TOKEN} tpm=enroll"
      ```

   1. The enable parameters:

      ```text
      kernel_parameters = "ip=dhcp quiet tpm=enable"
      ```

   1. Example SAT Bootprep templates

      ```yaml
      session_templates:
      - name: tpm-2.6.102-sles15sp5.x86_64
        image: tpm-2.6.102-sles15sp5.x86_64
        configuration: tpm-config
        bos_parameters:
          boot_sets:
            compute:
              kernel_parameters: ip=dhcp quiet spire_join_token=${SPIRE_JOIN_TOKEN}
              node_roles_groups:
              - Compute
      - name: tpm-2.6.102-sles15sp5.x86_64-enroll
        image: tpm-2.6.102-sles15sp5.x86_64
        configuration: tpm-config
        bos_parameters:
          boot_sets:
            compute:
              kernel_parameters: ip=dhcp quiet spire_join_token=${SPIRE_JOIN_TOKEN} tpm=enroll
              node_roles_groups:
              - Compute
      - name: tpm-2.6.102-sles15sp5.x86_64-enable
        image: tpm-2.6.102-sles15sp5.x86_64
        configuration: tpm-config
        bos_parameters:
          boot_sets:
            compute:
              kernel_parameters: ip=dhcp quiet tpm=enable
              node_roles_groups:
              - Compute
        ```

1. Reboot the node with the enrollment parameters then wait for it to finish booting.

   ```bash
   cray bos v2 sessions create --template-name tpm-2.6.102-sles15sp5.x86_64-enroll --operation reboot --limit $XNAME
   ```

1. Reboot the node with TPM enabled.

   ```bash
   cray bos v2 sessions create --template-name tpm-2.6.102-sles15sp5.x86_64-enable --operation reboot --limit $XNAME
   ```

1. Ensure the node has booted and is ready.

### Disable TPM node attestation on managed nodes

1. Reboot the node with the standard kernel parameters

   ```bash
   cray bos v2 sessions create --template-name tpm-2.6.102-sles15sp5.x86_64 --operation reboot --limit $XNAME
   ```
