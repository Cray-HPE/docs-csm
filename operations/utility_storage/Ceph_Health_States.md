# Ceph Health States

Ceph reports several different health states depending on the condition of a cluster. These health states can provide a lot of information about the current functionality of the Ceph cluster, what troubleshooting steps needs to be taken, and if a support ticket needs to be filed.

The health of a Ceph cluster can be viewed with the following command:

```bash
ncn-m001# ceph -s
cluster:
  id:     5f3b4031-d6c0-4118-94c0-bffd90b534eb
  health: HEALTH_OK  <<-- Health state

...
```

The following is an overview of potential health states:

- **HEALTH_OK**

    The cluster is operating as expected with no issues.

- **HEALTH_WARN**

    There is a WARNING condition on the cluster. There are lots of potential causes, but this warning does not mean any functionality is lost. For example, this health state could occur if a pool is at its quota. This health state does not mean that the cluster is not servicing data.

    Most HEALTH_WARN states resolve on their own as they pertain to functionality that tends to self correct.

- **HEALTH_ERROR**

    There is an ERROR condition on the cluster. This is typical for a configuration issue or if there is a component that is having issues completing its functions. This does not mean that the cluster is not servicing data. The HEALTH_ERROR state is primarily for individual components experiencing issues.

    Most HEALTH_ERROR states may not be covered by troubleshooting documentation and should result in a ticket to customer support for guidance.

- **HEALTH_CRITICAL**

    There is a CRITICAL condition on the cluster. This means that cluster functions have stopped or have gone into read-only mode to protect data. When this is present, the cluster is not servicing data properly, or even at all in order to protect data integrity. This will be dependent on the configuration and the reason behind the CRITICAL health state.

    All HEALTH_CRITICAL states should result in an immediate ticket to customer support for guidance on returning the cluster back to service.

For a list of possible states, refer to [https://docs.ceph.com/docs/master/rados/operations/health-checks/](https://docs.ceph.com/docs/master/rados/operations/health-checks/).

