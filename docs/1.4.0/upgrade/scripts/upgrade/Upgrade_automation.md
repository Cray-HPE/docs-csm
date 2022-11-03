# Upgrade Automation

This document describes how the CSM upgrade process is automated.

## Overview

In a nutshell, an upgrade is:

1. Upload new artifacts into a running system.
1. Rebuild each NCN with the newly uploaded images.
1. Deploy new charts after all NCNs are upgraded.

## Prerequisites

Everything that is needed before upgrading an NCN.

> NOTE:
>
> The `prerequisites.sh` script is required to run on both `ncn-m001` and `ncn-m002` (at different points in the upgrade process). If an action is only
> needed to run once, developers must add logic to avoid running this action both times the script is executed.

## NCN upgrade

Detailed implementation of how each type of node is being upgraded.

> NOTE:
>
> Depending on the type of node, the backup/restore/health check is handled differently. Because of this, each type of NCN has its own script for special handling.

## CSM services upgrade

This encompasses everything that is done in an upgrade after the NCNs are upgraded.
The most important part is to deploy new charts, but depending on the specific upgrade being performed, there may also be other required actions.
For example, the Kafka cluster may need some extra logic for its upgrade which cannot be done within its Helm chart. Such steps are also done during this portion of the upgrade.
