# Kyverno policy management

[Kyverno](https://kyverno.io/) is a policy engine designed specifically for Kubernetes.

Kyverno allows cluster administrators to manage environment specific configurations independently of workload configurations and enforce configuration best practices for their clusters.

Kyverno can be used to scan existing workloads for best practices, or can be used to enforce best practices by blocking or mutating API requests.

Kyverno enables administrators to do the following:
* Manage policies as Kubernetes resources.
* Validate, mutate, and generate resource configurations.
* Select resources based on labels and wildcards.
* Block non-conformant resources using admission controls, or report policy violations.
* View policy enforcement as events.
* Scan existing resources for violations.

Kyverno policies implement the various levels of Kubernetes [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/) for CSM services.

The policies are minimally restrictive and enforces the best practices for pods. The policies make sure the following values are set for workloads (if not present).

```text
securityContext:
  allowPrivilegeEscalation: false
  privileged: false
  runAsUser: 65534
  runAsNonRoot: true
  runAsGroup: 65534
```

Currently, [mutation](#mutation) and [validation](#validation) policies are enforced for the network services such as load balancer and virtualservice.

## Mutation

Mutation policies are applied in the admission controller while creating pods.

It mutates the manifest of respective workloads before creating it so that when resource comes up, it will abide by the policy constraints.

### Example

1. Create a sample policy.
	```text
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

2. Create a simple pod.
	```text
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

	List all of the policies with the following command:

	```bash
	kubectl get pol -A

	NAMESPACE            NAME                        BACKGROUND   ACTION   READY
	default              add-default-securitycontext true         audit    true
	…
	```

3. Check the manifest after applying the policy.

	```text
    ...
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
	  ...
	```

4. Edit the policy to add one more field and apply the policy again.
	```text
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

5. Check the pod description when the pod fails to come up.
	```bash
	kubectl get pods

	NAME    READY   STATUS                       RESTARTS   AGE
	nginx   0/1     CreateContainerConfigError   0          5s
	```
	```bash
    kubectl describe pods

	Name:         nginx
	Namespace:    default
	.
	.
	.
	Events:
  	Type     Reason            Age                            From               Message
  	----     ------            ----                           ----               -------
  	Normal   Scheduled         <invalid>                      default-scheduler  Successfully assigned default/nginx to ncn-w003-b7534262
  	Warning  DNSConfigForming  <invalid> (x9 over <invalid>)  kubelet            Search Line limits were exceeded, some search paths have been omitted, the applied search line is: default.svc.cluster.local svc.cluster.local cluster.local vshasta.io us-central1-b.c.vsha-sri-ram-35682334251634485.internal c.vsha-sri-ram-35682334251634485.internal
  	Normal   Pulled            <invalid> (x8 over <invalid>)  kubelet            Container image "nginx:1.14.2" already present on machine
  	Warning  Failed            <invalid> (x8 over <invalid>)  kubelet            Error: container has runAsNonRoot and image will run as root (pod: "nginx_default(0ea1d573-219a-4927-b3c3-c76150d35a7a)", container: nginx)
	```

6. If the previous step failed, delete the policy and restart the workload.
	```bash
	kubectl delete pol -n default add-default-securitycontext
	```

7. Check the pod status after deleting the policy.
	```bash
	kubectl get pods

	NAME    READY   STATUS    RESTARTS   AGE
	nginx   1/1     Running   0          6s
	```

## Validation

Validation policies can be applied any time in `audit` and `enforce` modes.

Violation is only reported in case of `audit` mode and it blocks the resources from coming up when applied in `enforce` mode.

Also, it generates the report of policy violation in respective workloads. The following is an example of the validation policy in `audit` mode.

### Example

1. Add the following policy before applying the [mutation](#mutation) to the workload.
	```text
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

	View the policy report status with the following command:

	```bash
	kubectl get polr -A

	NAMESPACE  NAME                   PASS   FAIL   WARN   ERROR   SKIP   AGE
	default    polr-ns-default        0      1      0      0       0      25d
	…
	```

	View a detailed policy report with the following command:

	```bash
	kubectl get polr -n default polr-ns-default -o yaml

	…
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

2. Apply the mutation policy and restart the following workload.
	```text
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

3. Check the policy report status.
	```bash
	kubectl get polr -A

	NAMESPACE  NAME                   PASS   FAIL   WARN   ERROR   SKIP   AGE
	default    polr-ns-default        1      0      0      0       0      25d
	…
	```

	This shows that the mutation policy for the workload was enforced properly.

	If there are any discrepancies, we can look at the detailed policy report to triage the issue.

## Known issues

1. [False positive audit logs are generated for Validation policy](https://github.com/kyverno/kyverno/issues/3970)
2. [No event is generated incase of mutation policy being apppled to a resource](https://github.com/kyverno/kyverno/issues/2160)
2. [Inaccurate annnotations are created after applying the policy](https://github.com/kyverno/kyverno/issues/3473)