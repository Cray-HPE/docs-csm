# List Available UAI Images in Legacy Mode

**NOTE:** UAI is deprecated in CSM 1.5.2 and will be removed in CSM 1.6.

A user can list the UAI images available for creating a UAI with a command of the form:

```bash
user> cray uas images list
```

For example:

```bash
vers>  cray uas images list
default_image = "registry.local/cray/cray-uai-sles15sp2:1.2.4"
image_list = [ "registry.local/cray/cray-uai-sles15sp2:1.2.4", "registry.local/cray/cray-uai-sanity-test:1.2.4", "registry.local/cray/cray-uai-broker:1.2.4",]
```

[Top: User Access Service (UAS)](README.md)

[Next Topic: Create UAIs From Specific UAI Images in Legacy Mode](Create_UAIs_From_Specific_UAI_Images_in_Legacy_Mode.md)
