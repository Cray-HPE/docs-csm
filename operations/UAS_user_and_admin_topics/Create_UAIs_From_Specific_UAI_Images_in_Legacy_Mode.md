# Create UAIs From Specific UAI Images in Legacy Mode

A user can create a UAI from a specific UAI image (assuming no default UAI class exists) using a command of the form:

```text
user> cray uas create --publickey <path> --imagename <image-name>
```

`<image-name>` is the name shown above in the list of UAI images.

For example:

```bash
vers>  cray uas images list
default_image = "registry.local/cray/cray-uai-sles15sp2:1.2.4"
image_list = [ "registry.local/cray/cray-uai-sles15sp2:1.2.4", "registry.local/cray/cray-uai-sanity-test:1.2.4", "registry.local/cray/cray-uai-broker:1.2.4",]

vers> cray uas create --publickey ~/.ssh/id_rsa.pub --imagename registry.local/cray/cray-uai-sles15sp2:1.2.4
uai_age = "0m"
uai_connect_string = "ssh vers@34.136.140.107"
uai_host = "ncn-w003"
uai_img = "registry.local/cray/cray-uai-sles15sp2:1.2.4"
uai_ip = "34.136.140.107"
uai_msg = "ContainerCreating"
uai_name = "uai-vers-1ad83473"
uai_status = "Waiting"
username = "vers"

[uai_portmap]
```

[Top: User Access Service (UAS)](index.md)

[Next Topic: UAS and UAI Legacy Mode Health Checks](UAS_and_UAI_Health_Checks.md)
