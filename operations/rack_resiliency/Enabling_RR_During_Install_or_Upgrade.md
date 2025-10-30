# Enabling Rack Resiliency During Install or Upgrade

## Overview

* Rack Resiliency **should not** be used in a production environment. For more details, see
  [Rack Resiliency is experimental](README.md#attention-rr-is-experimental).
* By default, Rack Resiliency is disabled.
* This page documents the procedures for enabling and configuring Rack Resiliency during
  a CSM install or upgrade. For information on how to do this outside of an install or upgrade context, see
  [Enabling Rack Resiliency on a Running System](Enabling_RR_on_running_system.md).
* Rack Resiliency cannot be disabled after it has been enabled.

At the same time that Rack Resiliency is enabled, administrators also have the option
to customize the [Zone names](Zones.md#zone-names) for the zones that will be created
during [Setup of Rack Resiliency](Setup_of_Rack_Resiliency.md). The decisions made here
about prefixes **cannot be changed later**.

## Fresh install of CSM 1.7

During a fresh install of CSM 1.7, if an administrator wishes to enable Rack Resiliency, they must do so in the
[Enable Rack Resiliency (experimental)](../../install/prepare_site_init.md#enable-rack-resiliency-experimental)
step of the [Prepare Site Init](../../install/prepare_site_init.md) procedure.

## Upgrade from CSM 1.6 to CSM 1.7

During an upgrade from CSM 1.6 to CSM 1.7, if an administrator wishes to enable Rack Resiliency, they must do so in the
[Rack Resiliency (experimental)](../../operations/iuf/workflows/product_delivery.md#rack-resiliency-experimental)
step of the [Product Delivery](../../operations/iuf/workflows/product_delivery.md) procedure.
