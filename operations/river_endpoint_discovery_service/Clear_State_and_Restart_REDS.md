## Clear State and Restart REDS

Many solutions to common River Endpoint Discovery Service \(REDS\) errors require that the REDS state be deleted and the service restarted. Use this procedure if an error has occurred that requires a restart of REDS.

### Prerequisites

-   The Cray command line interface \(CLI\) tool is initialized and configured on the system. 

### Procedure


1.  Stop all processes in the REDS container and delete all non-persistent state.

    ```bash
    ncn-m001# kubectl scale -n services --replicas=0 deployment cray-reds
    ```

2.  Wait for the first command to finish.

    ```bash
    ncn-m001# while [ -n "$(kubectl -n services get pods | grep reds | \
    grep -v -e etcd -e loader -e init )" ]; do sleep 1; done
    ```

3.  Delete all persistent state.

    ```bash
    ncn-m001# kubectl exec -it -n services $(kubectl get pods -n services | grep reds-etcd \
    | head -n 1 | awk '{print $1}') -- /bin/sh -c 'ETCDCTL_API=3 etcdctl del "" --from-key=true'
    ```

4.  Restart the REDS container, which will have no saved state.

    ```bash
    ncn-m001# kubectl scale -n services --replicas=1 deployment cray-reds
    ```

5.  Wait for REDS to fully come up.

    ```bash
    ncn-m001# while [ -z "$(kubectl get pods -n services | grep reds | grep Running)" ] ; do sleep 1; done
    ```

6.  Verify that the status of REDS is `Running`.

    ```bash
    $ kubectl get pods -n services | grep reds | grep Running
    ```

    If no results are returned, REDS is not running.

7.  Upload the current REDS mapping file.

    When state information is deleted, mapping data is deleted as well, so it is necessary to upload the current mapping file to restore that data.

    ```bash
    ncn-m001# cray reds port_xname_map update --map-file MAP_FILENAME
    ```


REDS has been restarted and has current mapping data.



