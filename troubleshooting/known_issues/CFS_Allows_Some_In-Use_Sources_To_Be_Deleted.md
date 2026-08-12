# CFS Allows Some In-Use Sources To Be Deleted

> This [CFS](../../glossary.md#configuration-framework-service-cfs) issue exists in
> CSM 1.5.0, CSM 1.5.1, CSM 1.5.2, and CSM 1.6.0.

CFS has safeguards in place that prevent a [CFS source](../../operations/configuration_management/CFS_Sources.md)
from being deleted while it is still in use. There are three places where a source can be specified in
CFS:

* The [Additional inventory source](../../operations/configuration_management/CFS_Global_Options.md#additional-inventory-source)
  [CFS Global Option](../../operations/configuration_management/CFS_Global_Options.md).
* In the `source` field of a layer of a [CFS configuration](../../operations/configuration_management/CFS_Configurations.md).
* In the `additional_inventory` layer of a CFS configuration.

This issue causes that final safeguard to be overlooked, allowing an administrator to delete
any source that is only used in `additional_inventory` layers of CFS configurations.

## Fix

* This issue did not exist prior to CSM 1.5, because CFS sources were not introduced until CSM 1.5.
* This issue exists in CSM 1.5.0, CSM 1.5.1, CSM 1.5.2, and CSM 1.6.0.
* This issue is fixed in all CSM 1.5 versions starting with CSM 1.5.3.
* This issue is fixed in all CSM 1.6 versions starting with CSM 1.6.1.
* This issue is fixed in all CSM versions starting with CSM 1.7.0.
