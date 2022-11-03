# PKI Certificate Authority \(CA\)

An instance of HashiCorp Vault, deployed via the Bitnami Bank-vaults operator, stores private and public Certificate Authority \(CA\) material, and serves APIs through a Public Key Infrastructure \(PKI\) engine instance.

CA material is injected as a start-up secret into Vault through a SealedSecret that translates into a Kubernetes Secret.

### CA Certificate Distribution

Trusted CA certificates are distributed via two channels:

-   Cloud-init metadata
-   Kubernetes ConfigMaps

Kubernetes-native workloads generally leverage ConfigMap-based distribution. The Cloud-init based method is used for non-compute node \(NCN\) OS distribution.

On NCNs, trusted certificates are installed by Cloud-init in the /etc/pki/trust/anchors/platform-ca-certs.crt file. Refer to [Make HTTPS Requests from Sources Outside the Management Kubernetes Cluster](Make_HTTPS_Requests_from_Sources_Outside_the_Management_Kubernetes_Cluster.md) for more information for clients that are outside the system's management cluster.

On compute nodes \(CNs\), trusted certificates are installed at image build time by the Image Management Service \(IMS\), and are located in the /etc/cray/ca/certificate\_authority.crt file.

For NCNs and CNs, the trusted certificates are added to the base OS trust store. The TrustedCerts Kubernetes Operator manages updates to trusted CA material across the noted channels.

