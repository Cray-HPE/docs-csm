# Enabling Rack Resiliency

Enabling Rack Resiliency is the first step for setting up Rack Resiliency.

**NOTE:**

* By default, the Rack Resiliency feature is disabled.
* Rack Resiliency can be enabled during fresh install of CSM 1.7 or an
  upgrade from CSM 1.6 to CSM 1.7. It can also be enabled as an operational procedure on a
  system running CSM 1.7+, outside of an install or upgrade.
* Rack Resiliency cannot be disabled after it has been enabled.

At the same time that Rack Resiliency is enabled, administrators also have the option
to customize the [Zone names](Zones.md#zone-names) for the zones that will be created
during [Setup of Rack Resiliency](Setup_of_Rack_Resiliency.md). Like with the
decision to enable Rack Resiliency, the decision made here about prefixes
**cannot be changed later**.

## Fresh install of CSM 1.7

During a fresh install of CSM 1.7, if an administrator wishes to enable Rack Resiliency,
they must do so in the
[Enable Rack Resiliency](../../install/prepare_site_init.md#enable-rack-resiliency) step of the
[Prepare Site Init](../../install/prepare_site_init.md) procedure.

## Upgrade from CSM 1.6 to CSM 1.7

During an upgrade from CSM 1.6 to CSM 1.7, if an administrator wishes to enable Rack Resiliency,
they must do so in the
[Rack Resiliency](../../operations/iuf/workflows/product_delivery.md#rack-resiliency) step of the
[Product Delivery](../../operations/iuf/workflows/product_delivery.md) procedure.

## Post install or upgrade

To enable Rack Resiliency anytime after an install or upgrade to CSM 1.7 refer to [Rack Resiliency Enablement](Enable_and_setup_Rack_Resiliency_post_install_upgrade.md#step-1-rack-resiliency-enablement).
