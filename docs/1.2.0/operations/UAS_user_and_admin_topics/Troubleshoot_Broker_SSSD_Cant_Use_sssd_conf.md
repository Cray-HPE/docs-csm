# Troubleshoot Broker UAI SSSD Cannot Use `/etc/sssd/sssd.conf`

## Symptom

A Broker UAI has been created using an SSSD configuration in a secret and volume as described in [Configure a Broker UAI Class](Configure_a_Broker_UAI_Class.md), but logging into the Broker UAI does not work.

Diagnose the problem as follows:

1. Find the UAI name of the Broker UAI in a list of existing UAIs:

   ```bash
   ncn-m001# cray uas admin uais list --format yaml
   ```

2. Find the Broker UAI pod name by looking for a pod with the UAI name as the first part of its name in the list of Broker UAI pods:

   ```bash
   ncn-m001# kubectl get po -n uas
   ```

3. Obtain logs from the Broker UAI:

   ```bash
   ncn-m001# kubectl logs -n uas <pod-name> -c <uai-name>
   ```

4. See if the the following errors appear in the log output:

   ```bash
   (2022-01-28 17:46:44:642510): [sssd] [confdb_ldif_from_ini_file] (0x0020): Permission check on config file failed.
   (2022-01-28 17:46:44:642549): [sssd] [confdb_init_db] (0x0020): Cannot convert INI to LDIF [1]: [Operation not permitted]
   (2022-01-28 17:46:44:642568): [sssd] [confdb_setup] (0x0010): ConfDB initialization has failed [1]: Operation not permitted
   (2022-01-28 17:46:44:642644): [sssd] [load_configuration] (0x0010): Unable to setup ConfDB [1]: Operation not permitted
   (2022-01-28 17:46:44:642764): [sssd] [main] (0x0020): Cannot read config file /etc/sssd/sssd.conf. Please check that the file is accessible only by the owner and owned by root.root.
   ```

## Problem Explanation

In the current release of UAS, the `default` Service Account on the `uas` namespace in Kubernetes is bound to a Cluster Role that uses a Pod Security Policy that defines a
specific `fsGroup` range and a `MustRunAs` rule instead of simply using the `RunAsAny` rule.
Because of the way Kubernetes handles volumes, when a volume containing a Secret or a ConfigMap is mounted on a Kubernetes pod with an `fsGroup` rule that is not `RunAsAny` in the Pod Security Policy,
the requested mode of the volume is adjusted to something Kubernetes deems more appropriate.
In this case, the requested mode (decimal 384 or octal 600) becomes octal 640 instead in the mounted volume. Unfortunately, SSSD requires that this mode be octal 600 or it will refuse to use the configuration file.

## Workaround

While this problem will be resolved in an upcoming release of UAS, if this behavior occurs, it is necessary to create a new Pod Security Policy and a Cluster Role using that Pod Security Policy,
then change the existing Cluster Role Binding to bind the new Cluster Role instead of the one it currently uses. The following procedure does that.

1. Verify that the system is set up the same way as the system on which this workaround was prepared. To do that, list the Cluster Role Binding named `uas-default-psp` and determine what Cluster Role it is bound to:

   ```bash
   ncn-m001# kubectl get clusterrolebindings uas-default-psp -o yaml
   ```

   Example output:

   ```bash
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:

   [...]

   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: restricted-transition-net-raw-psp
   subjects:
   - kind: ServiceAccount
     name: default
     namespace: uas
   ```

   Notice the `roleRef` setting binds the `restricted-transition-net-raw-psp` Cluster Role. That Cluster Role uses the `restricted-transition-net-raw-psp` Pod Security Policy, which is used by several CSM services, but does not work for Broker UAIs.

   Assuming the system is configured as shown above, the following steps will

   * Remove the existing incorrect `ClusterRoleBinding` so that it can be replaced later
   * Create a new Pod Security Policy called `uas-default-psp`.
   * Create a Cluster Role called `uas-default-psp` that uses the new Pod Security Policy
   * Replace the Cluster Role Binding called `uas-default-psp` with a new one that binds the new Cluster Role to the `default` Service Account in the `uas` namespace

   If the system is configured differently, it may be necessary to investigate further, which is largely beyond the scope of this section.
   The important thing here is that the `default` Service Account in the `uas` namespace must not be bound to a Pod Security Policy with an `fsGroup` or `supplementalGroups` configured with anything but the `RunAsAny` rule.

2. Remove the existing Cluster Role Binding:

   ```bash
   ncn-m001# kubectl delete clusterrolebindings uas-default-psp
   ```

3. Prepare a YAML file containing the new Kubernetes objects:

   ```bash
   ncn-m001# cat << EOF > /tmp/uas-default-psp.yaml
   apiVersion: policy/v1beta1
   kind: PodSecurityPolicy
   metadata:
     name: uas-default-psp
   spec:
     allowPrivilegeEscalation: true
     allowedCapabilities:
     - NET_ADMIN
     - NET_RAW
     allowedHostPaths:
     - pathPrefix: /lustre
     - pathPrefix: /root/registry
     - pathPrefix: /lib/modules
     - pathPrefix: /
     - pathPrefix: /var/lib/nfsroot/nmd
     - pathPrefix: /lus
     - pathPrefix: /var/tmp/cps-local
     fsGroup:
       rule: RunAsAny
     hostNetwork: true
     privileged: true
     runAsUser:
       rule: RunAsAny
     seLinux:
       rule: RunAsAny
     supplementalGroups:
       rule: RunAsAny
     volumes:
     - configMap
     - emptyDir
     - projected
     - secret
     - downwardAPI
     - persistentVolumeClaim
     - hostPath
     - flexVolume
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: uas-default-psp
   rules:
   - apiGroups:
     - policy
     resourceNames:
     - uas-default-psp
     resources:
     - podsecuritypolicies
     verbs:
     - use
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
     name: uas-default-psp
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: uas-default-psp
   subjects:
   - kind: ServiceAccount
     name: default
     namespace: uas
   EOF
   ```

4. Apply this new configuration to Kubernetes:

   ```bash
   ncn-m001# kubectl apply -f /tmp/uas-default-psp.yaml
   ```

5. Delete and re-create the offending Broker UAI(s) and they should come up and SSSD should run properly.

   ```bash
   ncn-m001# cray uas admin uais delete OPTIONS
   ```

   ```bash
   ncn-m001# cray uas admin uais create OPTIONS
   ```

[Top: User Access Service (UAS)](index.md)

[Next Topic: Clear UAS Configuration](Reset_the_UAS_Configuration_to_Original_Installed_Settings.md)
