# cray-kafka-operator chart failing to upgrade

## [Issue description](#issue-description)

If a cluster which was initially installed with CSM 1.3 or earlier, and is now getting upgraded to CSM 1.6.0 or CSM 1.6.1 from CSM 1.5.x, the upgrade of the cray-kafka-operator helm chart would fail as part of the CSM services upgrade process.

Note - This issue would not affect clusters that were freshly installed with CSM 1.4.x or CSM 1.5.x and are being upgraded to CSM 1.6.x version.

## [Error identification](#error-identification)

CSM services upgrade fails when upgrading to CSM 1.6.x with the following error -

```text
2025-03-27T13:50:50Z ERR  error="Some charts did not release successfully, see above and/or the output log file for more info" command=ship
120 /usr/share/doc/csm/upgrade/scripts/upgrade/csm-upgrade.sh
./upgrade.sh

[ERROR] - Unexpected errors, check logs: /root/output.log 
```

```text
2025-03-27T13:50:50Z ERR Error releasing chart cray-kafka-operator v1.2.1: Shell error: Error: UPGRADE FAILED: pre-upgrade hooks failed: timed out waiting for the condition chart=cray-kafka-operator command=ship namespace=operators version=1.2.1
```

There would be failed Kubernetes jobs for Kafka as follows -

```text
ncn-m001:~/cray-kafka-operator # kubectl get job -A|grep kafka
operators   cray-kafka-pre-upgrade-crd-hook   0/1   9m   9m

ncn-m001:~/cray-kafka-operator # kubectl get po -n operators
NAME                                    READY  STATUS   RESTARTS   AGE
cray-kafka-pre-upgrade-crd-hook-7dtcx   0/1    Error    0          9m
```

The `/root/output.log` which stores the upgrade logs contains following type of errors related to Strimzi Kafka Custom Resource Definitions(CRDs) -

```text
Error from server (Invalid): error when applying patch:
{"metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":<last_applied_configuration_values>
to:
Resource: "apiextensions.k8s.io/v1, Resource=customresourcedefinitions", GroupVersionKind: "apiextensions.k8s.io/v1, Kind=CustomResourceDefinition"
Name: "kafkas.kafka.strimzi.io", Namespace: ""
for: "/tmp/strimzi-crds-0.41.0.yaml": CustomResourceDefinition.apiextensions.k8s.io "kafkas.kafka.strimzi.io" is invalid: status.storedVersions[1]: Invalid value: "v1beta1": must appear in spec.versions

Error from server (Invalid): error when applying patch:
{"metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":<last_applied_configuration_values>
to:
Resource: "apiextensions.k8s.io/v1, Resource=customresourcedefinitions", GroupVersionKind: "apiextensions.k8s.io/v1, Kind=CustomResourceDefinition"
Name: "kafkaconnects.kafka.strimzi.io", Namespace: ""
for: "/tmp/strimzi-crds-0.41.0.yaml": CustomResourceDefinition.apiextensions.k8s.io "kafkaconnects.kafka.strimzi.io" is invalid: status.storedVersions[1]: Invalid value: "v1beta1": must appear in spec.versions

Error from server (Invalid): error when applying patch:
{"metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":<last_applied_configuration_values>
to:
Resource: "apiextensions.k8s.io/v1, Resource=customresourcedefinitions", GroupVersionKind: "apiextensions.k8s.io/v1, Kind=CustomResourceDefinition"
Name: "kafkarebalances.kafka.strimzi.io", Namespace: ""
for: "/tmp/strimzi-crds-0.41.0.yaml": CustomResourceDefinition.apiextensions.k8s.io "kafkarebalances.kafka.strimzi.io" is invalid: status.storedVersions[1]: Invalid value: "v1alpha1": must appear in spec.versions
```

Similar type of errors could be seen on other Strimzi CRDs too.

## [Workaround steps](#workaround-steps)

(`ncn-mw#`) To resolve this issue, update the Strimzi CRDs on the cluster by removing references to the older versions - `v1alpha1` and `v1beta1`.
After this update, the Strimzi CRDs (except `kafkatopics` and `kafkausers`) will retain only the latest supported version `v1beta2` which eliminates the upgrade failure.
Run the following script to fix the issue -

[`kafka_crd_fix.sh`](../scripts/kafka_crd_fix.sh)

Example output:

```bash
ncn-m001:~ # ./kafka_crd_fix.sh
Checking for old kafka CRD versions
old version present in kafkabridges.kafka.strimzi.io storedVersions: v1alpha1
old version present in kafkaconnectors.kafka.strimzi.io storedVersions: v1alpha1
old version present in kafkaconnects.kafka.strimzi.io storedVersions: v1beta1
old version present in kafkaconnects2is.kafka.strimzi.io storedVersions: v1beta1
old version present in kafkamirrormaker2s.kafka.strimzi.io storedVersions: v1alpha1
old version present in kafkamirrormakers.kafka.strimzi.io storedVersions: v1beta1
old version present in kafkarebalances.kafka.strimzi.io storedVersions: v1alpha1
old version present in kafkas.kafka.strimzi.io storedVersions: v1beta1
kafkatopics.kafka.strimzi.io: okay
kafkausers.kafka.strimzi.io: okay
strimzipodsets.core.strimzi.io: okay
Removing old kafka CRD versions
serviceaccount/crd-updater created
clusterrole.rbac.authorization.k8s.io/crd-update-access created
clusterrolebinding.rbac.authorization.k8s.io/crd-update-binding created
Using API Server: https://10.252.1.2:6442
Processing CRD: kafkabridges.kafka.strimzi.io
Patching CRD kafkabridges.kafka.strimzi.io status...
Replacing CRD kafkabridges.kafka.strimzi.io
CRD kafkabridges.kafka.strimzi.io updated successfully
Processing CRD: kafkaconnectors.kafka.strimzi.io
Patching CRD kafkaconnectors.kafka.strimzi.io status...
Replacing CRD kafkaconnectors.kafka.strimzi.io
CRD kafkaconnectors.kafka.strimzi.io updated successfully
Processing CRD: kafkaconnects.kafka.strimzi.io
Patching CRD kafkaconnects.kafka.strimzi.io status...
Replacing CRD kafkaconnects.kafka.strimzi.io
CRD kafkaconnects.kafka.strimzi.io updated successfully
Processing CRD: kafkaconnects2is.kafka.strimzi.io
Patching CRD kafkaconnects2is.kafka.strimzi.io status...
Replacing CRD kafkaconnects2is.kafka.strimzi.io
CRD kafkaconnects2is.kafka.strimzi.io updated successfully
Processing CRD: kafkamirrormaker2s.kafka.strimzi.io
Patching CRD kafkamirrormaker2s.kafka.strimzi.io status...
Replacing CRD kafkamirrormaker2s.kafka.strimzi.io
CRD kafkamirrormaker2s.kafka.strimzi.io updated successfully
Processing CRD: kafkamirrormakers.kafka.strimzi.io
Patching CRD kafkamirrormakers.kafka.strimzi.io status...
Replacing CRD kafkamirrormakers.kafka.strimzi.io
CRD kafkamirrormakers.kafka.strimzi.io updated successfully
Processing CRD: kafkarebalances.kafka.strimzi.io
Patching CRD kafkarebalances.kafka.strimzi.io status...
Replacing CRD kafkarebalances.kafka.strimzi.io
CRD kafkarebalances.kafka.strimzi.io updated successfully
Processing CRD: kafkas.kafka.strimzi.io
Patching CRD kafkas.kafka.strimzi.io status...
Replacing CRD kafkas.kafka.strimzi.io
CRD kafkas.kafka.strimzi.io updated successfully
Skipping CRD: kafkatopics.kafka.strimzi.io
Skipping CRD: kafkausers.kafka.strimzi.io
Processing CRD: strimzipodsets.core.strimzi.io
Patching CRD strimzipodsets.core.strimzi.io status...
Replacing CRD strimzipodsets.core.strimzi.io
CRD strimzipodsets.core.strimzi.io updated successfully
clusterrolebinding.rbac.authorization.k8s.io "crd-update-binding" deleted
clusterrole.rbac.authorization.k8s.io "crd-update-access" deleted
serviceaccount "crd-updater" deleted
```

Verify if the fix is applied as expected by re-running the script again.

```bash
ncn-m001:~ # ./kafka_crd_fix.sh
Checking for old kafka CRD versions
kafkabridges.kafka.strimzi.io: okay
kafkaconnectors.kafka.strimzi.io: okay
kafkaconnects.kafka.strimzi.io: okay
kafkaconnects2is.kafka.strimzi.io: okay
kafkamirrormaker2s.kafka.strimzi.io: okay
kafkamirrormakers.kafka.strimzi.io: okay
kafkarebalances.kafka.strimzi.io: okay
kafkas.kafka.strimzi.io: okay
kafkatopics.kafka.strimzi.io: okay
kafkausers.kafka.strimzi.io: okay
strimzipodsets.core.strimzi.io: okay
```
