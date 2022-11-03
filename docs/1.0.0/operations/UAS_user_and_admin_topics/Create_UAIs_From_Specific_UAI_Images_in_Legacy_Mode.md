# Create UAIs From Specific UAI Images in Legacy Mode

A user can create a UAI from a specific UAI image (assuming no default UAI class exists) using a command of the form:

```
user> cray uas create --publickey <path> --imagename <image-name>
```

`<image-name>` is the name shown above in the list of UAI images.

For example:

```
vers> cray uas images list
default_image = "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest"
image_list = [ "dtr.dev.cray.com/cray/cray-uai-broker:latest", "dtr.dev.cray.com/cray/cray-uas-sles15:latest", "dtr.dev.cray.com/cray/cray-uai-sles15sp1:latest",]

vers> cray uas create --publickey ~/.ssh/id_rsa.pub --imagename dtr.dev.cray.com/cray/cray-uas-sles15:latest
uai_connect_string = "ssh vers@10.103.13.160"
uai_host = "ncn-w001"
uai_img = "dtr.dev.cray.com/cray/cray-uas-sles15:latest"
uai_ip = "10.103.13.160"
uai_msg = ""
uai_name = "uai-vers-b386d655"
uai_status = "Pending"
username = "vers"

[uai_portmap]
```

