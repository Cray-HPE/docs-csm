
## HSM Subroles

The Hardware State Manager (HSM) contains several pre-defined subroles that can be used to target specific hardware devices.

The following is a list of all pre-defined subroles:

* Worker
* Master
* Storage
* UAN
* Gateway
* LNETRouter
* Visualization
* UserDefined

### Add Custom Subroles

Custom subroles can also be created and added to the HSM. New roles or subroles can be added anytime after SMD has been deployed. 

To add new roles/subroles, add them to the cray-hms-base-config configmap:

```bash
ncn# kubectl edit configmap -n services cray-hms-base-config
```