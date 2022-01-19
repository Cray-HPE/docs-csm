#Wait_for_unbound or cray-dns-unbound-manager hangs



* Run the following command:

    ```bash
    kubectl get jobs -n services | grep cray-dns-unbound-manager
    ```
	
	
	```bash
    services            cray-dns-unbound-manager-1635352560                  0/1           26h        26h
    services            cray-dns-unbound-manager-1635448680                  1/1           35s        8m37s
    services            cray-dns-unbound-manager-1635448860                  1/1           51s        5m36s
    services            cray-dns-unbound-manager-1635449040                  1/1           61s        2m35s
	```

* If you see one of the jobs show `0/1` for more than 10 minutes and there are other runs with `1/1`.  That means that job is hung. You can delete the job with:


	```bash
	kubectl delete jobs -n services $job_with_0/1
	```

* Alternative is copy and paste following code block:

	```bash
    unbound_manager_jobs=$(kubectl get jobs -n services |awk '{ print $1 }'|grep unbound-manager)

    for job in $unbound_manager_jobs; do
        job_entry=$(kubectl get jobs -n services $job|sed 1d)
            echo $job_entry
        job_id=$(echo $job_entry| awk '{ print $1 }')
            echo $job_id
            job_status=$(echo $job_entry| awk '{ print $2 }')
            echo $job_status
    	if [[ "$job_status" -eq "0/1" ]];then
            echo "deleting stale job"
    		kubectl delete jobs -n services $job_id
            echo "kubectl delete jobs -n services $job_id"
        fi
    done
	```