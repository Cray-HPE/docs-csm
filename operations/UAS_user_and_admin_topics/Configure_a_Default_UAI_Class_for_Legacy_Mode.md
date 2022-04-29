# Configure a Default UAI Class for Legacy Mode

Using a default UAI class is optional but recommended for any site using the legacy UAI management mode that wants to have some control over UAIs created by users. UAI classes used for this purpose need to have certain minimum configuration in them:

* The `image_id` field set to identify the image used to construct UAIs
* The `volume_list` field set to the list of volumes to mount in UAIs
* The `public_ip` field set to `true`
* The `uai_compute_network` flag set to `true` (if workload management will be used)
* The `default` flag set to `true` to make this the default UAI class

To make UAIs useful, there is a minimum set of volumes that should be defined in the UAS configuration:

* `/etc/localtime` for default timezone information
* The directory on the host nodes that holds persistent end-user storage, typically `/lus`

In addition to this, there may be volumes defined to support a workload manager (Slurm or PBS Professional) or the Cray Programming Environment (PE) or other packages the full extent of these volumes is outside the scope of this document,
but whatever list of these other volumes is needed to get a suitable End-User UAI should be included in the default UAI class configuration.

The [UAI Classes](UAI_Classes.md) section has more information on what goes in End-User UAI classes and, specifically, the Non-Brokered End-User UAI classes used for Legacy mode.

[Top: User Access Service (UAS)](index.md)

[Next Topic: Create and Use Default UAIs in Legacy Mode](Create_and_Use_Default_UAIs_in_Legacy_Mode.md)
