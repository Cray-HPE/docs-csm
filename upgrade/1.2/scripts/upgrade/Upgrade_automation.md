# Upgrade automation
This document describes how we automate upgrade process. In a nutshell, an upgrade is to upload new artifacts into a running system, then rebuild each ncn with newer images we uploaded and deploy new charts after storage/k8s nodes are upgraded.

## Prerequisites
Everything we need before upgrade a ncn.
> NOTE:
>
>   The prereq script is required to run on both m001 and m002. If an action is only needed to run once, developers should add logic to avoid running such action again on m002.
## NCN Node upgrade
Detailed implementation of how each type of node is being upgraded.

> NOTE:
>
> Depends on the type of node, we have to deal with backup/restore/health check differently. So each type of ncn has its own script for special handling
## CSM Services Upgrade
Everything we do after storage/k8s nodes are upgraded. The most important part here is to deploy new charts but we also have other actions depends on a particular upgrade here. For example, kafka cluster might need some extra logic to upgrade which cannot be done within helm chart, we will put such logic here and run it before charts upgrade.