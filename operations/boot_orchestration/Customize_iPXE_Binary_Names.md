# Customize iPXE Binary Names

The default behavior for the cray-ipxe service is the build iPXE binaries with a well known name. However, to help
prevent untrusted access to the iPXE binaries, sites may manually customize the iPXE binary names to a site specific
value. The site may further change the iPXE binary names periodically to further obfuscate and prevent access.

## Prerequisites

This procedure requires administrative privileges.

## Procedure

1. Edit the `cray-ipxe-settings` ConfigMap using one of the following options.

   > **NOTE:** Save a backup of the ConfigMap before making any changes.

   The following is an example of creating a backup:

    ```bash
    ncn-m001# kubectl get configmap -n services cray-ipxe-settings \
    -o yaml > /root/k8s/cray-ipxe-settings-backup.yaml
    ```

   Within the ConfigMap, edit the following keys to set the desired iPXE binary names.

   | iPXE binary | ConfigMap Key Name          | Default Value |
   | --- | --- | --- |
   | Regular iPXE | `cray_ipxe_binary_name` | ipxe.efi |
   | Debug iPXE | `cray_ipxe_debug_binary_name` | `debug-ipxe.efi` |

   > **NOTE:** Do not change the `cray_ipxe_binary_name_active` or
   `cray_ipxe_debug_binary_name_active` keys in the
   `cray-ipxe-settings` ConfigMap. The cray-ipxe builder will automatically update these keys with the name of the currently built iPXE images once they are available.

    - **Option 1:** Edit the `cray-ipxe-settings` ConfigMap directly.

      ```bash
      ncn-m001#  kubectl edit configmap -n services cray-ipxe-settings
      ```

    - **Option 2:** Edit the ConfigMap by saving the file, editing it, and reloading the ConfigMap.
        1. Save the file.

           ```bash
           ncn-m001# kubectl get configmap -n services cray-ipxe-settings \
           -o yaml > /root/k8s/cray-ipxe-settings.yaml
           ```

        2. Edit the cray-ipxe-settings.yaml file.

           ```bash
           ncn-m001# vi /root/k8s/cray-ipxe-bss-ipxe.yaml
           ```

        3. Reload the ConfigMap.

           Deleting and recreating the ConfigMap will reload it.

           ```bash
           ncn-m001# kubectl delete configmap -n services cray-ipxe-settings
           ncn-m001# kubectl create -f /root/k8s/cray-ipxe-settings.yaml
           ```

The cray-ipxe builder will detect the configuration change and rebuild the iPXE binaries within 30 to 90 seconds. Upon
successfully building the newly named binaries, the cray-ipxe builder will delete the old binaries from the shared files
system.
