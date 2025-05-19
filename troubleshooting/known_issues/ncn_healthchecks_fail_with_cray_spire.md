# NCN Health Checks Fail With `cray-spire`

In CSM 1.6.1 and 1.6.2, there is a known issue where the `/opt/cray/tests/install/ncn/scripts/check_key_id_in_jwks.sh`, which runs during NCN health checks, can fail.  Run this command on each NCN to fix the problematic script:

```shell
sed -i -E 's#\.\[\]\?\.svids\[\]\?\.svid#\.\[0\]\?\.svids\[0\]\?\.svid#g' /opt/cray/tests/install/ncn/scripts/check_key_id_in_jwks.sh
```
