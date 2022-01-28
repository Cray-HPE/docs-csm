[Top: User Access Service (UAS)](User_Access_Service_UAS.md)

[Next Topic: Clear UAS Configuration](Reset_the_UAS_Configuration_to_Original_Installed_Settings.md)

## Troubleshoot Broker UAI SSSD Can't Use `/etc/sssd/sssd.conf`

### Symptom

A Broker UAI has been created using an SSSD configuration in a secret and volume as described in [Configure a Broker UAI Class](Configure_a_Broker_UAI_Class.md) but logging into the broker does not work.  Upon investigation using

```
ncn-m001:~ # cray uas admin uais list --format yaml
```

to get the UAI name of the Broker UAI,

```
ncn-m001:~ # kubectl get po -n uas
```

to find the broker pod name, and

```
ncn-m001:~ # kubectl logs -n uas <pod-name> -c <uai-name>
```

The following errors appear in the log output:

```
(2022-01-28 17:46:44:642510): [sssd] [confdb_ldif_from_ini_file] (0x0020): Permission check on config file failed.
(2022-01-28 17:46:44:642549): [sssd] [confdb_init_db] (0x0020): Cannot convert INI to LDIF [1]: [Operation not permitted]
(2022-01-28 17:46:44:642568): [sssd] [confdb_setup] (0x0010): ConfDB initialization has failed [1]: Operation not permitted
(2022-01-28 17:46:44:642644): [sssd] [load_configuration] (0x0010): Unable to setup ConfDB [1]: Operation not permitted
(2022-01-28 17:46:44:642764): [sssd] [main] (0x0020): Cannot read config file /etc/sssd/sssd.conf. Please check that the file is accessible only by the owner and owned by root.root.
```

### Problem Explanation

In the current release of UAS, the `default` Service Account on the `uas` namespace in Kubernetes is bound to a Cluster Role that uses a Pod Security Policy that defines a specific `fsGroup` range and a `MustRunAs` rule instead of simly using the `RunAsAny` rule.  Because of the way Kubernetes handles volumes, when a volume containing a Secret or a ConfigMap is mounted on a Kubernetes pod with an `fsGroup` rule that is not `RunAsAny` in the Pod Security Policy, the requested mode of the volume is adjusted to something Kubernetes deems more appropriate.  In this case, the requested mode (decimal 384 or octal 600) becomes octal 640 instead in the mounted volume.  Unfortunately, SSSD requires that this mode be octal 600 or it will refuse to use the configuration file.

### Workaround

While this problem will be resolved in an upcoming release of UAS, if this behavior occurs, it is necessary to create a new Pod Security Policy and a Cluster Role using that Pod Security Policy, then change the existing Cluster Role Binding to bind the new Cluster Role instead of the one it currently uses.  The following procedure does that.

First, verify that the system is set up the same way as the system on which this workaround was prepared.  To do that, list the Cluster Role Binding named `uas-default-psp` and determine what Cluster Role it is bound to:

```
ncn-m001:~ # kubectl get clusterrolebindings uas-default-psp -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:

...

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

Assuming this configuration is present, it is necessary to create a new Pod Security Policy called `uas-default-psp`, then create a Cluster Role called `uas-default-psp` that uses the new Pod Security Policy and finally a change the Cluster Role Binding called `uas-defaul-psp` to bind the new Cluster Role to the `default` Service Account in the `uas` namespace.  Since Kubernetes does not allow simply updating the existing `uas-default-psp` Cluster Role Binding the existing one must be removed and replaced.  To remove the existing Cluster Role Binding:

```
ncn-m001:~ # kubectl delete clusterrolebindings uas-default-psp
```

Now prepare a YAML file containing the new Kubernetes objects:

```
ncn-m001:~ # cat << EOF > /tmp/uas-default-psp.yaml
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

Finally, apply this new configuration to Kubernetes:

```
ncn-m001:~ # kubectl apply -f /tmp/uas-default-psp.yaml 
```

After this delete and re-create the offending Broker UAI(s) and they should come up and SSSD should run properly.

[Next Topic: Clear UAS Configuration](Reset_the_UAS_Configuration_to_Original_Installed_Settings.md)
