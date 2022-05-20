# Upgrade Automation

This document describes how we automate upgrade process. In a nutshell, an upgrade is:
1. Upload new artifacts into a running system
1. Rebuild each NCN with the newly uploaded images
1. Deploy new charts after all NCNs are upgraded.

## Prerequisites

Everything we need before upgrading an NCN.
> NOTE:
>
>   The `prerequisites.sh` script is required to run on both `ncn-m001` and `ncn-m002`. If an action is only needed to run once, developers must add logic to avoid running this action both times the script is executed.

## NCN Upgrade

Detailed implementation of how each type of node is being upgraded.

> NOTE:
>
> Depending on the type of node, we have to deal with backup/restore/health check differently. So each type of NCN has its own script for special handling

## CSM Services Upgrade

Everything we do after the NCNs are upgraded. The most important part here is to deploy new charts, but depending on the specific upgrade being performed, there may also be other required actions. For example, the kafka cluster might need some extra logic to upgrade which cannot be done within its helm chart. Such logic is done during this portion of the upgrade.
