# Kyverno policy management

* [Mutation](#mutation)
    * [Example mutation policy](#example-mutation-policy)
* [Validation](#validation)
    * [Example validation policy](#example-validation-policy)
* [What is new in the HPE CSM 1.4 release and above](#what-is-new-in-the-hpe-csm-14-release-and-above)
    * [Example to list policy violations at pod level](#example-to-list-policy-violations-at-pod-level)
    * [Example to list all the policy violations](#example-to-list-all-the-policy-violations)
* [What is new in the HPE CSM 1.6 release and above](#what-is-new-in-the-hpe-csm-16-release-and-above)
    * [Container image signature verification Kyverno policy](#container-image-signature-verification-kyverno-policy)
        * [Policy customization](#policy-customization)
* [What is new in the HPE CSM 1.7 release and above](#what-is-new-in-the-hpe-csm-17-release-and-above)
    * [Container image signature verification is enforced using Kyverno policy](#container-image-signature-verification-is-enforced-using-kyverno-policy)
        * [How to identify container image signature verification failures](#how-to-identify-container-image-signature-verification-failures)
            * [Checking existing resources](#checking-existing-resources)
            * [Verification failures investigation](#verification-failures-investigation)
            * [Resolving verification failures](#resolving-verification-failures)
            * [Sign the image and add the public key to the policy](#sign-the-image-and-add-the-public-key-to-the-policy)
            * [Add an exception](#add-an-exception)
        * [Policy customization through redeploying the chart](#policy-customization-through-redeploying-the-chart)
    * [Baseline Pod Security Standards (PSS) enforced using Kyverno policies](#baseline-pod-security-standards-pss-enforced-using-kyverno-policies)
        * [Analyzing PSS policy violations](#analyzing-pss-policy-violations)
        * [Exempting pods from the PSS policy](#exempting-pods-from-the-pss-policy)
        * [Switching between Enforce and Audit mode](#switching-between-enforce-and-audit-mode)
* [Known issues](#known-issues)

[Kyverno](https://kyverno.io/) is a policy engine designed specifically for Kubernetes.

Kyverno allows cluster administrators to manage environment-specific configurations (independently of workload configurations)
and enforce configuration best practices for their clusters.

Kyverno can be used to scan existing workloads for best practices, or it can be used to enforce best practices by blocking or mutating API requests.

Kyverno enables administrators to do the following:

* Manage policies as Kubernetes resources.
* Validate, mutate, and generate resource configurations.
* Select resources based on labels and wildcards.
* Block nonconforming resources using admission controls, or report policy violations.
* View policy enforcement as events.
* Scan existing resources for violations.

Kyverno policies implement the various levels of Kubernetes [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/) for CSM services.

The policies are minimally restrictive and enforce the best practices for pods. The policies make sure that the following values are set for workloads (if not present):

```yaml
securityContext:
  allowPrivilegeEscalation: false
  privileged: false
  runAsUser: 65534
  runAsNonRoot: true
  runAsGroup: 65534
```

[Mutation](#mutation) and [Validation](#validation) policies are enforced for the network services such as load balancer and virtual service.

## Mutation

Mutation policies are applied in the admission controller while creating pods.

It mutates the manifest of respective workloads before creating them so that when the resource comes up, it will abide by the policy constraints.

### Example mutation policy

1. Create a policy definition.

    ```yaml
    apiVersion: kyverno.io/v1
    kind: Policy
    metadata:
      name: add-default-securitycontext
    spec:
    rules:
      - name: set-container-security-context
        match:
          resources:
            kinds:
            - Pod
            selector:
              matchLabels:
                app: nginx
        mutate:
          patchStrategicMerge:
            spec:
              containers:
              - (name): "*"
                securityContext:
                  +(allowPrivilegeEscalation): false
                  +(privileged): false
    ```

1. Create a simple pod definition.

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
    containers:
    - name: nginx
      image: nginx:1.14.2
      ports:
      - containerPort: 80
    ```

1. (`ncn-mw#`) List all of the policies with the following command:

    ```bash
    kubectl get pol -A
    ```

    Example output:

    ```text
    NAMESPACE            NAME                        BACKGROUND   ACTION   READY
    default              add-default-securitycontext true         audit    true
    ```

1. Check the manifest after applying the policy.

    ```yaml
    spec:
      containers:
      - image: nginx:1.14.2
        imagePullPolicy: IfNotPresent
        name: nginx
        ports:
        - containerPort: 80
          protocol: TCP
        resources:
          requests:
            cpu: 10m
            memory: 64Mi
        securityContext:
          allowPrivilegeEscalation: false
          privileged: false
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
          name: default-token-vgggw
          readOnly: true
    ```

1. Edit the policy to add one more field and apply the policy again.

    ```yaml
    apiVersion: kyverno.io/v1
    kind: Policy
    metadata:
      name: add-default-securitycontext
    spec:
    rules:
      - name: set-container-security-context
        match:
          resources:
            kinds:
            - Pod
            selector:
              matchLabels:
                app: nginx
        mutate:
          patchStrategicMerge:
            spec:
              containers:
              - (name): "*"
                securityContext:
                  +(allowPrivilegeEscalation): false
                  +(privileged): false
                  +(runAsNonRoot): true
    ```

    If any of the workloads fail to come up after enforcing the policy, then delete the individual policies and restart the workload.

1. Check the pod description when the pod fails to come up.

    1. (`ncn-mw#`) Obtain the pod name.

        ```bash
        kubectl get pods
        ```

        Example output:

        ```text
        NAME    READY   STATUS                       RESTARTS   AGE
        nginx   0/1     CreateContainerConfigError   0          5s
        ```

    1. (`ncn-mw#`) Describe the pod.

        ```bash
        kubectl describe pod nginx
        ```

        End of example output:

        ```text
        Events:
        Type     Reason            Age                            From               Message
        ----     ------            ----                           ----               -------
        Normal   Scheduled         <invalid>                      default-scheduler  Successfully assigned default/nginx to ncn-w003-b7534262
        Warning  DNSConfigForming  <invalid> (x9 over <invalid>)  kubelet            Search Line limits were exceeded, some search paths have been omitted, the applied search line is: default.svc.cluster.local svc.cluster.local cluster.local vshasta.io us-central1-b.c.vsha-sri-ram-35682334251634485.internal c.vsha-sri-ram-35682334251634485.internal
        Normal   Pulled            <invalid> (x8 over <invalid>)  kubelet            Container image "nginx:1.14.2" already present on machine
        Warning  Failed            <invalid> (x8 over <invalid>)  kubelet            Error: container has runAsNonRoot and image will run as root (pod: "nginx_default(0ea1d573-219a-4927-b3c3-c76150d35a7a)", container: nginx)
        ```

1. (`ncn-mw#`) If the previous step failed, then delete the policy and restart the workload.

    ```bash
    kubectl delete pol -n default add-default-securitycontext
    ```

1. (`ncn-mw#`) Check the pod status after deleting the policy.

    ```bash
    kubectl get pods
    ```

    Example output:

    ```text
    NAME    READY   STATUS    RESTARTS   AGE
    nginx   1/1     Running   0          6s
    ```

## Validation

Validation policies can be applied any time in `audit` and `enforce` modes.

In the case of `audit` mode, violations are only reported. In `enforce` mode, the resources are blocked from coming up.

Also, it generates the report of policy violation in respective workloads. The following is an example of the validation policy in `audit` mode.

### Example validation policy

1. Add the following policy before applying the [mutation](#mutation) to the workload.

    ```yaml
    apiVersion: kyverno.io/v1
    kind: Policy
    metadata:
      name: validate-securitycontext
    spec:
      background: true
      validationFailureAction: audit
      rules:
      - name: container-security-context
        match:
          resources:
            kinds:
            - Pod
            selector:
              matchLabels:
                app: nginx
        validate:
          message: "Non root security context is not set."
          pattern:
            spec:
              containers:
              - (name): "*"
                securityContext:
                  allowPrivilegeEscalation: false
                  privileged: false
    ```

    * (`ncn-mw#`) View the policy report status with the following command:

        ```bash
        kubectl get polr -A
        ```

        Example output:

        ```text
        NAMESPACE  NAME                   PASS   FAIL   WARN   ERROR   SKIP   AGE
        default    polr-ns-default        0      1      0      0       0      25d
        ```

    * (`ncn-mw#`) View a detailed policy report with the following command:

        ```bash
        kubectl get polr -n default polr-ns-default -o yaml
        ```

        Example output:

        ```yaml
        results:
        - message: 'validation error: Non root security context is not set. Rule container-security-context failed at path /spec/containers/0/securityContext/'
          policy: validate-securitycontext
          resources:
          - apiVersion: v1
            kind: Pod
            name: nginx
            namespace: default
            uid: 319e5b09-6027-4d90-b3da-6aa1f14573ff
          result: fail
          rule: container-security-context
          scored: true
          source: Kyverno
          timestamp:
            nanos: 0
            seconds: 1654594319
          summary:
            error: 0
            fail: 1
            pass: 0
            skip: 0
            warn: 0
        ```

1. Apply the mutation policy and restart the following workload.

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
    containers:
    - name: nginx
      image: nginx:1.14.2
      ports:
      - containerPort: 80
    ```

1. (`ncn-mw#`) Check the policy report status.

    ```bash
    kubectl get polr -A
    ```

    Example output:

    ```text
    NAMESPACE  NAME                   PASS   FAIL   WARN   ERROR   SKIP   AGE
    default    polr-ns-default        1      0      0      0       0      25d
    ```

    This shows that the mutation policy for the workload was enforced properly.

    If there are any discrepancies, look at the detailed policy report to triage the issue.

## What is new in the HPE CSM 1.4 release and above

The upstream Baseline profile is now available for customers as part of the HPE CSM 1.4 release.

The Baseline profile is a collection of policies which implement the various levels of Kubernetes [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/).

The Baseline profile is minimally restrictive and denies the most common vulnerabilities. It also follows many of the common security best practices for Kubernetes pods.

[Baseline profile](https://github.com/kyverno/policies/tree/main/pod-security/baseline) consists of 12 policies as listed below.

```bash
kubectl get clusterpolicy -A
```

Example output:

```text
NAME                             BACKGROUND   ACTION   READY
cluster-job-ttl                  true         audit    true
disallow-capabilities            true         audit    true
disallow-host-namespaces         true         audit    true
disallow-host-path               true         audit    true
disallow-host-ports              true         audit    true
disallow-host-process            true         audit    true
disallow-privileged-containers   true         audit    true
disallow-proc-mount              true         audit    true
disallow-selinux                 true         audit    true
restrict-apparmor-profiles       true         audit    true
restrict-seccomp                 true         audit    true
restrict-sysctls                 true         audit    true
```

The violations for each of the Baseline policies is logged in a policy report, similar to the other policies mentioned in Validation section above.
To get more information on each violation, use the following command.

### Example to list policy violations at pod level

```bash
kubectl get polr -A -o json | jq -r -c '["Name","kind","Namespace","policy","message"],(.items[].results // [] | map(select(.result=="fail")) | select(. | length > 0) | .[] | select (.resources[0].kind == "Pod") | [.resources[0].name,.resources[0].kind,.resources[0].namespace,.policy,.message]) | @csv'
```

Example output:

```text
"Name","kind","Namespace","policy","message"
"hms-discovery-28031310-lnvtf","Pod","services","disallow-capabilities","Any capabilities added beyond the allowed list (AUDIT_WRITE, CHOWN, DAC_OVERRIDE, FOWNER, FSETID, KILL, MKNOD, NET_BIND_SERVICE, SETFCAP, SETGID, SETPCAP, SETUID, SYS_CHROOT) are disallowed."
"etcd-backup-pvc-snapshots-to-s3-28031285-ssjfc","Pod","services","disallow-capabilities","Any capabilities added beyond the allowed list (AUDIT_WRITE, CHOWN, DAC_OVERRIDE, FOWNER, FSETID, KILL, MKNOD, NET_BIND_SERVICE, SETFCAP, SETGID, SETPCAP, SETUID, SYS_CHROOT) are disallowed."
"cray-dns-unbound-manager-28031310-wrhvj","Pod","services","disallow-capabilities","Any capabilities added beyond the allowed list (AUDIT_WRITE, CHOWN, DAC_OVERRIDE, FOWNER, FSETID, KILL, MKNOD, NET_BIND_SERVICE, SETFCAP, SETGID, SETPCAP, SETUID, SYS_CHROOT) are disallowed."
"cray-console-data-postgres-1","Pod","services","disallow-capabilities","Any capabilities added beyond the allowed list (AUDIT_WRITE, CHOWN, DAC_OVERRIDE, FOWNER, FSETID, KILL, MKNOD, NET_BIND_SERVICE, SETFCAP, SETGID, SETPCAP, SETUID, SYS_CHROOT) are disallowed."
"hms-discovery-28031292-6cxmz","Pod","services","disallow-capabilities","Any capabilities added beyond the allowed list (AUDIT_WRITE, CHOWN, DAC_OVERRIDE, FOWNER, FSETID, KILL, MKNOD, NET_BIND_SERVICE, SETFCAP, SETGID, SETPCAP, SETUID, SYS_CHROOT) are disallowed."
```

### Example to list all the policy violations

```bash
kubectl get polr -A -o json | jq -r -c '["Name","kind","Namespace","policy","message"],(.items[].results // [] | map(select(.result=="fail")) | select(. | length > 0) | .[] | select (.resources[0].kind) | [.resources[0].name,.resources[0].kind,.resources[0].namespace,.policy,.message]) | @csv'
```

Example output:

```text
"Name","kind","Namespace","policy","message"
"cray-nls","Deployment","argo","disallow-host-path","validation error: HostPath volumes are forbidden. The field spec.volumes[*].hostPath must be unset. Rule autogen-host-path failed at path /spec/template/spec/volumes/4/hostPath/"
"cray-ceph-csi-cephfs-nodeplugin","DaemonSet","ceph-cephfs","disallow-host-ports","validation error: Use of host ports is disallowed. The fields spec.containers[*].ports[*].hostPort , spec.initContainers[*].ports[*].hostPort, and spec.ephemeralContainers[*].ports[*].hostPort must either be unset or set to `0`. Rule autogen-host-ports-none failed at path /spec/template/spec/containers/2/ports/0/hostPort/"
"cray-ceph-csi-cephfs-nodeplugin","DaemonSet","ceph-cephfs","disallow-host-namespaces","validation error: Sharing the host namespaces is disallowed. The fields spec.hostNetwork, spec.hostIPC, and spec.hostPID must be unset or set to `false`. Rule autogen-host-namespaces failed at path /spec/template/spec/hostNetwork/"
"cray-ceph-csi-cephfs-nodeplugin","DaemonSet","ceph-cephfs","disallow-capabilities","Any capabilities added beyond the allowed list (AUDIT_WRITE, CHOWN, DAC_OVERRIDE, FOWNER, FSETID, KILL, MKNOD, NET_BIND_SERVICE, SETFCAP, SETGID, SETPCAP, SETUID, SYS_CHROOT) are disallowed."
"cray-ceph-csi-cephfs-nodeplugin","DaemonSet","ceph-cephfs","disallow-privileged-containers","validation error: Privileged mode is disallowed. The fields spec.containers[*].securityContext.privileged and spec.initContainers[*].securityContext.privileged must be unset or set to `false`. Rule autogen-privileged-containers failed at path /spec/template/spec/containers/0/securityContext/privileged/"
```

## What is new in the HPE CSM 1.6 release and above

* Kyverno is upgraded from 1.9.5 version to 1.10.7 version and is now available for customers as part of the HPE CSM 1.6 release.

   This is a major upgrade with many new features and bug fixes. For a complete list, refer to the external [CHANGELOG](https://github.com/kyverno/kyverno/blob/main/CHANGELOG.md).

* [Container image signature verification Kyverno policy](#container-image-signature-verification-kyverno-policy)

### Container image signature verification Kyverno policy

Container image signing and runtime verification policy by name `check-image` is delivered (through Kyverno
policy engine) as part of CSM 1.6 release in `Audit` only mode. (`Audit` only mode will log the policy violation
warning messages in to the cluster report and as events)

By default, the `check-image` policy is shipped as a `ClusterPolicy` and is configured to work in a sample (non-existent) namespace. To enable the policy, end users must customize it to the targeted namespaces.

CSM runs in an air gapped environment, where the images stored in `artifactory` are mirrored to the local Nexus registry. Kyverno policy engine does not support
this environment for image verification. To enable Kyverno policy for such environments, all `image specs` need to be replaced from `artifactory.algol60.net/csm-docker/stable/image:tag`
to `registry.local/artifactory.algol60.net/csm-docker/stable/image:tag` (prepend `registry.local/` to the image spec). This will force Kyverno to check local Nexus
registry for the images. Without `registry.local/`, Kyverno will try to contact remote registry (`artifactory`) every time, and this may trigger timeouts due to delays,
and eventually lead to policy failure.

Prepending `registry.local/` to the image spec can be achieved either manually or through a mutation policy.

For more information on mutation policy, refer to the [Mutation Policy](https://kyverno.io/policies/other/prepend-image-registry/prepend-image-registry/).

#### Policy customization

If any changes are to be made to the policy, for example, including or excluding certain namespaces and adding
a new public key, then the end user must change the CSM customizations and redeploy the `kyverno-policy` chart.
For more information on customization and redeployment, see [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md).

For more information on policy exception and matchings, refer to the Kyverno documentation at [Policy Exceptions](https://release-1-10-0.kyverno.io/docs/writing-policies/exceptions/)
and [match/exclude](https://release-1-10-0.kyverno.io/docs/writing-policies/match-exclude/).

## What is new in the HPE CSM 1.7 release and above

* Kyverno is upgraded from 1.10.7 version to 1.13.4 version and is now available for customers as part of the HPE CSM 1.7 release.

   This is a major upgrade with many new features and bug fixes. For a complete list, refer to the external [CHANGELOG](https://github.com/kyverno/kyverno/blob/main/CHANGELOG.md).

* [Container image signature verification is enforced using Kyverno policy](#container-image-signature-verification-is-enforced-using-kyverno-policy)

* Pod Security Policies (PSP) are removed and
  [Baseline Pod Security Standards (PSS) are enforced using Kyverno policies](#baseline-pod-security-standards-pss-enforced-using-kyverno-policies).

### Container image signature verification is enforced using Kyverno policy

Container image signing and runtime verification policy by name `check-image` is delivered (through Kyverno
policy engine) as part of CSM 1.7 release in `Enforce` mode. (`Audit` only mode will log the policy violation
warning messages into the cluster report and as events whereas `Enforce` mode will block the resources if they fail signature verification)

By default, the `check-image` policy is shipped as a `ClusterPolicy`. Policy can be customized based on the end users environment.
In CSM 1.7, a cluster-wide mutation policy named `prepend-registry` is provided to prepend `registry.local/` to all the container images that are being used in the Kubernetes resources.
Also, a policy exception named `check-image-exceptions` is provided that can be used to provide exceptions from both `prepend-registry` and `check-image` policy. End users can modify the `check-image-exceptions` to add any exceptions.

For more information on the above mutation policy, refer to the [Mutation Policy](https://kyverno.io/policies/other/prepend-image-registry/prepend-image-registry/).
In CSM 1.7, the container image signature verification policy `check-image` is separated from the `kyverno-policy` Helm chart and is delivered as a new Helm chart named `image-verification-policy`.
This new chart is deployed after the nexus deployment. This change is introduced because Kyverno does not have the intelligence to look into the PIT node (until Nexus is up) for the image signatures.
Kyverno will look into Nexus because of the prepended `registry.local/`.

#### How to identify container image signature verification failures

##### Checking existing resources

Use the following command:

`kubectl get polr -A | awk '$6 > 0'`

This command filters the `Policy Reports (polr)` to list resources with at least one verification failure. Sample output:

```text
NAMESPACE     NAME                                   KIND        NAME                                             PASS   FAIL   WARN   ERROR   SKIP   AGE
ceph-cephfs   1d32041d-5dcd-438f-8cd8-91dc7d240f0f   Pod         cray-ceph-csi-cephfs-nodeplugin-hpflx            1      1      0      0       0      19d
ceph-rbd      878cd835-4a5b-4e2c-97c3-a4da33cfd297   DaemonSet   cray-ceph-csi-rbd-nodeplugin                     0      1      0      0       0      25d
non-existent  12678622-c38b-409c-a372-3b7d2e5688e8   Pod         test-failure-ff8fd69cf-x99qb                     1      1      0      0       0      119s
```

In this example, each listed resource has at least one verification failure (`FAIL` column).

##### Verification failures investigation

To better understand the reason for the failure, inspect the specific Policy Report by describing it:

Example:

```bash
kubectl describe polr 12678622-c38b-409c-a372-3b7d2e5688e8 -n non-existent
```

This command gives detailed information about the verification failure, such as:

```text
Name:         12678622-c38b-409c-a372-3b7d2e5688e8
Namespace:    non-existent
Labels:       app.kubernetes.io/managed-by=kyverno
Annotations:  <none>
API Version:  wgpolicyk8s.io/v1alpha2
Kind:         PolicyReport

Results:
  Message:  failed to verify image registry.local/arti.hpc.amslabs.hpecorp.net/quay-remote/frrouting/frr:8.4.2: 
            .attestors[0].entries[0].keys: no signatures found; 
            .attestors[0].entries[1].keys: no signatures found; 
            .attestors[0].entries[2].keys: no signatures found; 
            .attestors[0].entries[3].keys: no signatures found; 
            .attestors[0].entries[4].keys: no signatures found; 
            .attestors[0].entries[5].keys: no signatures found
  Policy:   check-image
  Result:   fail
  Rule:     check-image
  Scored:   true
  Source:   kyverno
```

This detailed message explicitly states that no valid signatures were found for the specified image.

##### Resolving verification failures

Below two options are available when facing verification failures:

##### Sign the image and add the public key to the policy

Ensure that the container images are properly signed using a signing tool named Cosign. Properly signed images will pass verification policies and deploy successfully.

Refer this official documentation of [Cosign](https://docs.sigstore.dev/quickstart/quickstart-cosign/) to sign the images.

Once, it is signed, the public key must be added to the Kyverno cluster policy `check-image`, and the chart `image-verification-policy` must be redeployed with the base chart `kyverno-policy`.
For more information, see [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md).

(`ncn-mw#`) Changes to `check-image policy` looks as below:

```bash
kubectl get cpol check-image -o yaml
```

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  annotations:
    #...omitted...
  labels:
    app.kubernetes.io/managed-by: Helm
  name: check-image

spec:
  admission: true
  # ...omitted...
  rules:
  - match:
      any:
      - resources:
          kinds:
          - Pod
    name: check-image
    verifyImages:
    - attestors:
      - count: 1
        entries:
        - keys:
            ctlog:
              ignoreSCT: true
            publicKeys: |
              -----BEGIN PUBLIC KEY-----
              # ...omitted...
              -----END PUBLIC KEY-----
              -----BEGIN PUBLIC KEY-----
              # ...omitted...
              -----END PUBLIC KEY-----
              # ...omitted...
            rekor:
              ignoreTlog: true
            # ...omitted...
  validationFailureAction: Enforce
```

Under `keys.publicKeys`, the new public key needs to be added, following the approach documented in
[Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md).

##### Add an exception

If signing the image is not possible or desired, explicitly add the resource that uses this image as an exception in the `check-image-exceptions` policy exception in the Kyverno namespace.

(`ncn-mw#`) `check-image-exceptions` policy exception looks as below:

```bash
kubectl -n kyverno get policyexception check-image-exceptions -o yaml
```

```yaml
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  annotations:
    # ...omitted...
  labels:
    app.kubernetes.io/managed-by: Helm
  name: check-image-exceptions
  namespace: kyverno
spec:
  exceptions:
  - policyName: prepend-registry
    ruleNames:
    - prepend-registry-containers
    - prepend-registry-initcontainers
  - policyName: check-image
    ruleNames:
    - check-image
  match:
    any:
    - resources:
        names:
        - '*sample-resource-name*'
    - resources:
        names:
        - '*samp-1*'
        - '*samp-2*'
        - '*samp-3*'
```

(`ncn-mw#`) Use the following command to add the exception.

> Take a backup before editing.

```bash
kubectl -n kyverno edit policyexception check-image-exceptions
```

```yaml
spec:
  exceptions:
  - policyName: prepend-registry
    ruleNames:
    - prepend-registry-containers
    - prepend-registry-initcontainers
  - policyName: check-image
    ruleNames:
    - check-image
  match:
    any:
    # ...omitted...
    - resources:
        names:
        - '*samp-1*'
        - '*samp-2*'
        - '*samp-3*'
    - resources:
        names:
        - '*updated-resource-name*'
        - '*new-resource-pattern*'
```

Add the exceptions and exit.

Now the resource will be allowed for deployment.
See the [Kyverno documentation](https://release-1-13-0.kyverno.io/docs/writing-policies/exceptions/) on adding exceptions.

#### Policy customization through redeploying the chart

If any changes are to be made in the image verification policy, for example, making it to Audit mode or adding
a new public key, then the end user must change the CSM customizations and redeploy the `image-verification-policy` chart under the base chart `kyverno-policy`.
For more information on customization and redeployment, see [Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md).

For more information on policy exception and matchings, refer to the Kyverno documentation at [Policy Exceptions](https://release-1-13-0.kyverno.io/docs/writing-policies/exceptions/).

### Baseline Pod Security Standards (PSS) enforced using Kyverno policies

Pod Security Policies were removed from Kubernetes 1.25. Instead, Kubernetes introduced [Pod Security Standards (PSS)](https://kubernetes.io/docs/concepts/security/pod-security-standards/) to strengthen the Kubernetes pod security.

Starting in CSM 1.4, upstream discrete PSS baseline policies are shipped in Audit mode.
Starting in CSM 1.7, a single `podsecurity-subrule-baseline` policy is shipped
which takes advantage of Kyverno's `podSecurity` `subrule`, which in turn paves the way for easier implementation of exceptions.

The `podsecurity-subrule-baseline` Kyverno policy has been shipped in **Enforce** Mode starting in CSM 1.7.
This means that pods or pod controllers not adhering to the policy will NOT be admitted to the cluster.
Kyverno will block that admission, unless an exception is issued.

#### Analyzing PSS policy violations

(`ncn-mw#`) To list the failing policy reports for all the Kyverno policies existing in a cluster, the following command can be used:

```bash
kubectl get polr -A | awk '$6 > 0'
```

Example output:

```text
NAMESPACE            NAME                                   KIND          NAME                                                              PASS   FAIL   WARN   ERROR   SKIP   AGE
ceph-cephfs          75d41f86-4141-457b-ad0f-317af7764a36   DaemonSet     cray-ceph-csi-cephfs-nodeplugin                                   0      1      0      0       0      11d
ceph-rbd             26270dc0-0464-45e1-90f7-8cdc8131a00a   DaemonSet     cray-ceph-csi-rbd-nodeplugin                                      0      1      0      0       0      11d
```

The `policyreport` is a `namespaced` resource that is generated by Kyverno for each resource that is matched by a policy.
Inside a `PolicyReport`, there may be multiple results, based on the number of policies that matched the resource,
and a subsequent result field mentioning if it passed or failed.

(`ncn-mw#`) These details can be seen by describing the `policyreport`:

```bash
kubectl describe polr -n ceph-cephfs 75d41f86-4141-457b-ad0f-317af7764a36
```

```yaml
Name:         75d41f86-4141-457b-ad0f-317af7764a36
Namespace:    ceph-cephfs
Labels:       app.kubernetes.io/managed-by=kyverno
Annotations:  <none>
API Version:  wgpolicyk8s.io/v1alpha2
Kind:         PolicyReport
Metadata:
  Owner References:
    API Version:     apps/v1
    Kind:            DaemonSet
    Name:            cray-ceph-csi-cephfs-nodeplugin
Results:
  Message:  Validation rule 'autogen-baseline' failed. It violates PodSecurity "baseline:latest":
  (Forbidden reason: non-default capabilities, field error list: [spec.template.spec.containers[0].securityContext.capabilities.add is forbidden, forbidden values found: [SYS_ADMIN]])
  (Forbidden reason: host namespaces, field error list: [spec.template.spec.hostNetwork is forbidden, forbidden values found: true, spec.template.spec.hostPID is forbidden, forbidden values found: true])
  (Forbidden reason: hostPath volumes, field error list: [spec.template.spec.volumes[0].hostPath is forbidden, forbidden values found: /var/lib/kubelet/plugins/cephfs.csi.ceph.com, spec.template.spec.volumes[1].hostPath is forbidden,
  forbidden values found: /var/lib/kubelet/plugins_registry, spec.template.spec.volumes[2].hostPath is forbidden, forbidden values found: /var/lib/kubelet/pods, spec.template.spec.volumes[3].hostPath is forbidden,
  forbidden values found: /var/lib/kubelet/plugins, spec.template.spec.volumes[4].hostPath is forbidden, forbidden values found: /sys, spec.template.spec.volumes[5].hostPath is forbidden,
  forbidden values found: /etc/selinux, spec.template.spec.volumes[6].hostPath is forbidden, forbidden values found: /run/mount, spec.template.spec.volumes[7].hostPath is forbidden,
  forbidden values found: /lib/modules, spec.template.spec.volumes[8].hostPath is forbidden, forbidden values found: /dev, spec.template.spec.volumes[12].hostPath is forbidden,
  forbidden values found: /var/lib/kubelet/plugins/cephfs.csi.ceph.com/mountinfo])(Forbidden reason: privileged, field error list: [spec.template.spec.containers[0].securityContext.privileged is forbidden,
  forbidden values found: true, spec.template.spec.containers[1].securityContext.privileged is forbidden,
  forbidden values found: true, spec.template.spec.containers[2].securityContext.privileged is forbidden, forbidden values found: true])
  Policy:   podsecurity-subrule-baseline
  Properties:
    Controls:       capabilities_baseline,hostNamespaces,hostPathVolumes,privileged
    Controls JSON:  [{"ID":"capabilities_baseline","Name":"Capabilities","Images":["artifactory.algol60.net/csm-docker/stable/quay.io/cephcsi/cephcsi:v3.14.0"]},{"ID":"hostNamespaces","Name":"Host Namespaces","Images":null},
    {"ID":"hostPathVolumes","Name":"HostPath Volumes","Images":null},
    {"ID":"privileged","Name":"Privileged Containers","Images":["artifactory.algol60.net/csm-docker/stable/quay.io/cephcsi/cephcsi:v3.14.0","artifactory.algol60.net/csm-docker/stable/registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.13.0",
    "artifactory.algol60.net/csm-docker/stable/quay.io/cephcsi/cephcsi:v3.14.0"]}]
    Standard:       baseline
    Version:        latest
  Result:           fail
  Rule:             autogen-baseline
  Scored:           true
  Source:           kyverno
Scope:
  API Version:  apps/v1
  Kind:         DaemonSet
  Name:         cray-ceph-csi-cephfs-nodeplugin
  Namespace:    ceph-cephfs
Summary:
  Error:  0
  Fail:   1
  Pass:   0
  Skip:   0
  Warn:   0
Events:   <none>
ncn-m001:~ # 
```

As seen above, the pod fails the `podsecurity-subrule-baseline` policy because it uses `hostPath` volumes, uses additional capabilities, and allows privileged containers.

#### Exempting pods from the PSS policy

There are situations where certain pods cannot adhere to the Baseline policies due to their functionalities.
Such resources can be exempted by using `PolicyExceptions`. From CSM 1.7,
`PolicyExceptions` are enabled in all namespaces, so that they can be used for resources that are unable to adhere to the policies.
A set of exceptions are issued in the `kyverno` namespace for such pods found within the CSM deployment.

(`ncn-mw#`) View these exceptions.

```bash
kubectl get policyexception -n kyverno
```

If more pods are found to be violating the PSS Policy, more exceptions may be required.
The Kyverno [documentation for `PolicyExceptions`](https://release-1-13-0.kyverno.io/docs/writing-policies/exceptions/)
can be referred if any further exceptions are required. For example, for the earlier policy report from `cray-ceph-csi-cephfs-nodeplugin`,
the following `PolicyException` is added to allow the DaemonSet and its pods to use those resources:

```yaml
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  name: ceph-nodeplugin
  namespace: kyverno
spec:
  exceptions:
  - policyName: podsecurity-subrule-baseline
    ruleNames:
    - baseline
    - autogen-baseline
  match:
    any:
    - resources:
        kinds:
        - Pod
        - DaemonSet
        names:
        - cray-ceph-csi-cephfs-nodeplugin*
        - cray-ceph-csi-rbd-nodeplugin*
        namespaces:
        - ceph-cephfs
        - ceph-rbd
  podSecurity:
  - controlName: Privileged Containers
    images:
    - '*/quay.io/cephcsi/cephcsi:*'
    - '*/registry.k8s.io/sig-storage/csi-node-driver-registrar:*'
    restrictedField: spec.containers[*].securityContext.privileged
    values:
    - "true"
  - controlName: Capabilities
    images:
    - '*/quay.io/cephcsi/cephcsi:*'
    restrictedField: spec.containers[*].securityContext.capabilities.add
    values:
    - SYS_ADMIN
  - controlName: Host Namespaces
    restrictedField: spec.hostNetwork
    values:
    - "true"
  - controlName: Host Namespaces
    restrictedField: spec.hostPID
    values:
    - "true"
  - controlName: Host Ports
    images:
    - '*/quay.io/cephcsi/cephcsi:*'
    restrictedField: spec.containers[*].ports[*].hostPort
    values:
    - "8080"
    - "8081"
  - controlName: HostPath Volumes
    restrictedField: spec.volumes[*].hostPath
    values:
    - /dev
    - /etc/selinux
    - /lib/modules
    - /run/mount
    - /sys
    - /var/lib/kubelet/plugins
    - /var/lib/kubelet/plugins/cephfs.csi.ceph.com
    - /var/lib/kubelet/plugins/cephfs.csi.ceph.com/mountinfo
    - /var/lib/kubelet/plugins/rbd.csi.ceph.com
    - /var/lib/kubelet/plugins_registry
    - /var/lib/kubelet/pods
    - /var/log/ceph
```

As seen above, the `PolicyException` first matches the resource to be exempted from the policy, mentions the policy and its rules to be exempted.
Further, it mentions the `podSecurity` exemptions to allow the use of privileged containers,
additional capabilities, host namespaces, ports, and `hostPath` volumes. Notice that only the required fields and required values are supposed
to be exempted. Make sure not to be too permissive with `PolicyExceptions` because
it ruins the purpose of having a policy in the first place. Further documentation about `PolicyException` specific to PSS policy can be found as part of the
[Kyverno Documentation](https://release-1-13-0.kyverno.io/docs/writing-policies/exceptions/#pod-security-exemptions).

#### Switching between Enforce and Audit mode

As mentioned earlier, pods will NOT be allowed to be admitted to the cluster if they violate the PSS policy, because it is in Enforce mode.
A message similar to the following will appear if a violating pod is attempted to be added to the cluster.

```text
Error from server: error when creating "badpod.yaml": admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Pod/default/badpod01 was blocked due to the following policies 

podsecurity-subrule-baseline:
  baseline: 'Validation rule ''baseline'' failed. It violates PodSecurity "baseline:latest":
    (Forbidden reason: non-default capabilities, field error list: [spec.containers[0].securityContext.capabilities.add
    is forbidden, forbidden values found: [NET_RAW]])'
```

The pods getting admitted are expected to be compliant to the PSS policy. In case the pods are not expected to be compliant, and require to be allowed,
a `PolicyException` can be issued as described above.
If in case Enforce mode must be switched back to Audit mode, then this can be done by redeploying the `cray-kyverno-policies-upstream` chart after
setting the following in the `customizations.yaml`:

```yaml
cray-kyverno-policies-upstream:
    pssFailureAction: Audit
```

Redeploy the `cray-kyverno-policies-upstream` chart under the `platform` manifest by applying the above customization and then following the
[Redeploying a Chart](../CSM_product_management/Redeploying_a_Chart.md) documentation.

## Known issues

* [False positive audit logs are generated for Validation policy](https://github.com/kyverno/kyverno/issues/3970)
* [No event is generated in case of mutation policy being applied to a resource](https://github.com/kyverno/kyverno/issues/2160)
* [Inaccurate annotations are created after applying the policy](https://github.com/kyverno/kyverno/issues/3473)
* [IUF workflows failing because of a really long activity name](https://github.com/argoproj/argo-workflows/issues/11356)

    ```text
    2025-04-16T08:02:20Z | Pod: argo/this-is-a-really-long-activity-name-ilfqr-deploy-productt87tk-shell-script3210929130 | Message: policy podsecurity-subrule-baseline/baseline fail: Validation rule 'baseline' failed. It violates PodSecurity "baseline:latest": (Forbidden reason: hostPath volumes, field error list: [spec.volumes[2].hostPath is forbidden, forbidden values found: /var/lib/ca-certificates, spec.volumes[3].hostPath is forbidden, forbidden values found: /etc/cray/upgrade/csm])
    ```

    The `podsecurity-subrule-baseline` policy's exceptions for IUF workflows rely on matching the naming of IUF Argo pods.
    For a really long activity name as shown in the error above, the Argo workflows might
    truncate the generated `argo` pod names which will cause the policy exceptions to not work. In such a scenario,
    Kyverno will block the pod because it violates the PSS policy; this causes the IUF workflow to fail.
    Retry the workflow with a smaller activity name.
    It is recommended to use an activity name that is at most 16-20 characters. The idea is to have the generated pod
    name under 63 characters according to the Kubernetes standards.

* Unsigned container image restarts are blocked during upgrade to CSM 1.7

    Starting from CSM 1.7, `container image verification policy` is being enforced. During the upgrade to CSM 1.7, if any unsigned
    images need a restart, they will be blocked. The following describes how to work around this issue.

    Customize the `check-image` policy. Change `validationFailureAction` from `Enforce` to `Audit`; then switch the policy back to `Enforce`
    when the upgrade is done. For more information on changing the customizations, see [Policy customization](#policy-customization).

* Incorrectly copying container images to Nexus can block the pods

    When container images are copied to Nexus, their signatures must be copied along with them. Otherwise, the pods that use those images can be blocked.
    To ensure that signatures are copied along with images to Nexus, follow the
    [Adding images](../package_repository_management/Package_Repository_Management_with_Nexus.md#adding-images) procedure.

[operations/kubernetes/Kyverno.md](#known-issues)

[operations/kubernetes/Kyverno.md](#what-is-new-in-the-hpe-csm-17-release-and-above)
