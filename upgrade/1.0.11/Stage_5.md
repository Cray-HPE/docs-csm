# Stage 5 - Verification

1. Verify that the following command includes the new CSM version (1.0.11):

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   1.0.1
   1.0.10
   1.0.11
   ```

1. Verify that fix for CVE-2022-0185 (Linux kernel buffer overflow/container escape) is in place:

    ```bash
    ncn-m001:~ # pdsh -w $(/etc/cray/upgrade/csm/csm-1.0.*/tarball/csm-1.0.*/lib/list-ncns.sh 2>/dev/null | paste -sd,) "uname -a"
    ncn-m001: Linux ncn-m002 5.3.18-24.99-default #1 SMP Sun Jan 23 19:03:51 UTC 2022 (712a8e6) x86_64 x86_64 x86_64 GNU/Linux
    ncn-m002: Linux ncn-m002 5.3.18-24.99-default #1 SMP Sun Jan 23 19:03:51 UTC 2022 (712a8e6) x86_64 x86_64 x86_64 GNU/Linux
    ncn-m003: Linux ncn-m003 5.3.18-24.99-default #1 SMP Sun Jan 23 19:03:51 UTC 2022 (712a8e6) x86_64 x86_64 x86_64 GNU/Linux
    ncn-s001: Linux ncn-s001 5.3.18-24.99-default #1 SMP Sun Jan 23 19:03:51 UTC 2022 (712a8e6) x86_64 x86_64 x86_64 GNU/Linux
    ncn-s002: Linux ncn-s002 5.3.18-24.99-default #1 SMP Sun Jan 23 19:03:51 UTC 2022 (712a8e6) x86_64 x86_64 x86_64 GNU/Linux
    ncn-s003: Linux ncn-s003 5.3.18-24.99-default #1 SMP Sun Jan 23 19:03:51 UTC 2022 (712a8e6) x86_64 x86_64 x86_64 GNU/Linux
    ncn-w001: Linux ncn-s001 5.3.18-24.99-default #1 SMP Sun Jan 23 19:03:51 UTC 2022 (712a8e6) x86_64 x86_64 x86_64 GNU/Linux
    ncn-w002: Linux ncn-s002 5.3.18-24.99-default #1 SMP Sun Jan 23 19:03:51 UTC 2022 (712a8e6) x86_64 x86_64 x86_64 GNU/Linux
    ncn-w003: Linux ncn-s003 5.3.18-24.99-default #1 SMP Sun Jan 23 19:03:51 UTC 2022 (712a8e6) x86_64 x86_64 x86_64 GNU/Linux
    ```

    Version of running kernel must be `5.3.18-24.99` on all NCN nodes. Note: previous version of kernel was `5.3.18-24.75`.

1. Verify that fix for CVE-2021-4034 (pwnkit: Local Privilege Escalation in polkit's pkexec) is in place:

    ```bash
    ncn-m001:~ # pdsh -w $(/etc/cray/upgrade/csm/csm-1.0.*/tarball/csm-1.0.*/lib/list-ncns.sh 2>/dev/null | paste -sd,) "rpm -q polkit"
    ncn-m001: polkit-0.116-3.6.1.x86_64
    ncn-m002: polkit-0.116-3.6.1.x86_64
    ncn-m003: polkit-0.116-3.6.1.x86_64
    ncn-s001: polkit-0.116-3.6.1.x86_64
    ncn-s002: polkit-0.116-3.6.1.x86_64
    ncn-s003: polkit-0.116-3.6.1.x86_64
    ncn-w001: polkit-0.116-3.6.1.x86_64
    ncn-w002: polkit-0.116-3.6.1.x86_64
    ncn-w003: polkit-0.116-3.6.1.x86_64
    ```

    Version of installed polkit package must be `0.116-3.6.1` on all NCN nodes. Note: previous version of polkit package was `0.116-3.3.1`.

1.  Verify that fix for CVE-2022-23302, CVE-2022-23305, CVE-2022-23307 and CVE-2021-4104 is in place:

    ```bash
    ncn-m001:~ # kubectl describe pods cray-shared-kafka -n services |grep Image:
    Image:         strimzi/operator:0.15.0-noJndiLookupClass
    Image:         strimzi/operator:0.15.0-noJndiLookupClass
    Image:         strimzi/kafka:0.15.0-noJSM-chainsaw-kafka-2.3.1
    Image:         strimzi/kafka:0.15.0-noJSM-chainsaw-kafka-2.2.1
    Image:         strimzi/kafka:0.15.0-noJSM-chainsaw-kafka-2.3.1
    Image:         strimzi/kafka:0.15.0-noJSM-chainsaw-kafka-2.2.1
    Image:         strimzi/kafka:0.15.0-noJSM-chainsaw-kafka-2.3.1
    Image:         strimzi/kafka:0.15.0-noJSM-chainsaw-kafka-2.2.1
    Image:         strimzi/kafka:0.15.0-noJSM-chainsaw-kafka-2.3.1
    Image:         strimzi/kafka:0.15.0-noJSM-chainsaw-kafka-2.3.1
    Image:         strimzi/kafka:0.15.0-noJSM-chainsaw-kafka-2.3.1
    Image:         strimzi/kafka:0.15.0-noJSM-chainsaw-kafka-2.3.1
    Image:         strimzi/kafka:0.15.0-noJSM-chainsaw-kafka-2.3.1
    Image:         strimzi/kafka:0.15.0-noJSM-chainsaw-kafka-2.3.1
    Image:         strimzi/kafka:0.15.0-noJSM-chainsaw-kafka-2.3.1
    ```
    
    Version tag of installed strimzi/kafka image must be `0.15.0-noJSM-chainsaw-kafka-2.2.1` and `0.15.0-noJSM-chainsaw-kafka-2.3.1`. Note: previous version tag were `0.15.0-kafka-2.2.1` and `0.15.0-kafka-2.3.1`
    
[Return to main upgrade page](README.md)
