# HSM Roles and Subroles

The [Hardware State Manager (HSM)](../../glossary.md#hardware-state-manager-hsm) contains several pre-defined roles and subroles
that can be assigned to components and used to target specific hardware devices.

Roles and subroles assignments come from the [System Layout Service (SLS)](../../glossary.md#system-layout-service-sls) and are
applied by HSM when a node is discovered.

* [HSM roles](#hsm-roles)
* [HSM subroles](#hsm-subroles)
* [Add custom roles and subroles](#add-custom-roles-and-subroles)

## HSM roles

The following is a list of all pre-defined roles:

* `Management`
* `Compute`
* `Application`
* `Service`
* `System`
* `Storage`

The `Management` role refers to [NCNs](../../glossary.md#non-compute-node-ncn) and will generally have the `Master`, `Worker`, or `Storage` subrole assigned.

The `Compute` role generally refers to compute nodes.

The `Application` role is used for more specific node uses and will generally have the `UAN`, `LNETRouter`, `Visualization`, `Gateway`, or `UserDefined` subrole assigned.

## HSM subroles

The following is a list of all pre-defined subroles:

* `Worker`
* `Master`
* `Storage`
* `UAN`
* `Gateway`
* `LNETRouter`
* `Visualization`
* `UserDefined`

The `Master`, `Worker`, and `Storage` subroles are generally used with the `Management` role to indicate NCN types.

The `UAN`, `LNETRouter`, `Visualization`, `Gateway`, and `UserDefined` subroles are generally used with the `Application` role to indicate specific use nodes.

## Add custom roles and subroles

Custom roles and subroles can also be created and added to the HSM. New roles or subroles can be added anytime after SMD has been deployed.

To add new roles, add them to the `cray-hms-base-config` ConfigMap under `data.hms_config.json.HMSExtendedDefinitions.Role`.
To add new subroles, add them to the `cray-hms-base-config` ConfigMap under `data.hms_config.json.HMSExtendedDefinitions.SubRole`.

(`ncn-mw#`) Edit the ConfigMap with the following command:

```bash
kubectl edit configmap -n services cray-hms-base-config
```

```yaml
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

Deleting roles/subroles from this list will also remove them from HSM. However, deleting any of the pre-defined roles or subroles will have no effect.
