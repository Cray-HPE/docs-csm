# Upgrade CSM and additional products

This procedure is used when performing an upgrade of Cray System Management (CSM) along with
additional HPE Cray EX software products at the same time. This procedure would be used when
upgrading from one HPC CSM Software Recipe release to another.

This procedure is _not_ used to perform an initial install or upgrade of HPE Cray EX software products
when CSM itself is not being upgraded. See
[Install or upgrade additional products with IUF](install_or_upgrade_additional_products_with_iuf.md) for that procedure.

This procedure streamlines the rollout of new images to management nodes. These images are based
on the new images provided by the CSM product and customized by the additional HPE Cray EX software
products, including the [User Services Software (USS)](../../../glossary.md#user-services-software-uss)
and [Slingshot Host Software (SHS)](../../../glossary.md#slingshot-host-software-shs).

There are two options to upgrade CSM and additional HPE Cray EX software products:

1. This option is for upgrading CSM and additional HPE Cray EX software products using IUF. See
[Upgrade CSM and additional products with IUF](upgrade_csm_iuf_additional_products_with_iuf.md)
for that procedure.

1. This option alternates between CSM upgrade instructions that do not utilize IUF
and instructions for upgrading additional HPE Cray EX software products whose installation is
managed by the IUF. See
[Upgrade CSM manually and additional products with IUF](upgrade_csm_manual_and_additional_products_with_iuf.md) for that procedure.
