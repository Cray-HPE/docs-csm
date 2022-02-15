# Stage 5 - Verification

1. Verify that the following command includes the new CSM version (1.0.11):

   ```bash
   ncn-m001# kubectl get cm cray-product-catalog -n services -o jsonpath='{.data.csm}' | yq r -j - | jq -r 'to_entries[] | .key' | sort -V
   1.0.1
   1.0.10
   1.0.11
   ```

1. TODO: Kernel/polkit/kafka verfication

[Return to main upgrade page](README.md)
