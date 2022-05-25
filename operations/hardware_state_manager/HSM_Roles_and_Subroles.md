# HSM Roles and Subroles

The Hardware State Manager (HSM) contains several pre-defined roles and subroles that can be assigned to components and used to target specific hardware devices.

Roles and subroles assignments come from the System Layout Service (SLS) and are applied by HSM when a node is discovered.

### HSM Roles

The following is a list of all pre-defined roles:

* Management
* Compute
* Application
* Service
* System
* Storage

The _Management_ role refers to NCNs and will generally have the _Master_, _Worker_, or _Storage_ subrole assigned.

The _Compute_ role generally refers to compute nodes.

The _Application_ role is used for more specific node uses and will generally have the _UAN_, _LNETRouter_, _Visualization_, _Gateway_, or _UserDefined_ subrole assigned.

### HSM Subroles

The following is a list of all pre-defined subroles:

* Worker
* Master
* Storage
* UAN
* Gateway
* LNETRouter
* Visualization
* UserDefined

The _Master_, _Worker_, and _Storage_ subroles are generally used with the _Master_ role to indicate NCN types.

The _UAN_, _LNETRouter_, _Visualization_, _Gateway_, and _UserDefined_ subroles are generally used with the _Application_ role to indicate specific use nodes.

### Add Custom Roles and Subroles

Custom roles and subroles can also be created and added to the HSM. New roles or subroles can be added anytime after SMD has been deployed.

To add new roles/subroles, add them to the cray-hms-base-config configmap under data->hms_config.json.HMSExtendedDefinitions.(Sub)Role:

```bash
ncn# kubectl edit configmap -n services cray-hms-base-config

data:
  hms_config.json: |-
    {
       "HMSExtendedDefinitions":{
          "Role":[
             "Compute",
             "Service",
             "System",
             "Application",
             "Storage",
             "Management"
          ],
          "SubRole":[
             "Worker",
             "Master",
             "Storage",
             "UAN",
             "Gateway",
             "LNETRouter",
             "Visualization",
             "UserDefined"
          ]
       }
    }
```

Deleting roles/subroles from this list will also remove them from HSM. However, deleting any of the pre-defined roles or subroles will have no affect.
