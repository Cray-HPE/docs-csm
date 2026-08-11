# Cannot Create CFS V3 Configuration Layers With Special Parameters

In CSM 1.5.0, [CFS](../../glossary.md#configuration-framework-service-cfs) V3 does
not allow [configuration](../../operations/configuration_management/CFS_Configurations.md) layers
that include the `special_parameters` field. Attempts to create such configuration layers using CFS V3
fail.

This issue can be worked around by using CFS V2, which allows layers that include the `specialParameters` field.
This issue is fixed in CSM 1.5.1 and above.

For more information on the differences between CFS V2 and V3, see
[Differences Between the V2 and V3 CFS APIs](../../operations/configuration_management/Differences_Between_the_V2_and_V3_CFS_APIs.md).
