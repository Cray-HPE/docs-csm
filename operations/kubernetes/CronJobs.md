# Kubernetes CronJobs

Kubernetes CronJobs create Kubernetes jobs on a repeating schedule, specified in traditional cron syntax.

### CronJobs Not Scheduled

In some cases, CronJobs can fail to get scheduled (such as the cray-dns-unbound-manager job) if a previously run job did not finish properly. In order to alleviate this condition, CSM deploys a traditional CronJob on one of the master NCNs to perform cleanup such that jobs continue to get rescheduled.

In the event jobs aren't running, ensure the CronJob is specified properly using the following steps.

1. Determine the master NCN hosting the cronjob-kicker (typically `ncn-m001` or `ncn-m002`):

   ```bash
   ncn-m001# ls  /etc/cron.d/cronjob-kicker
   /etc/cron.d/cronjob-kicker
   ```

1. Verify the crontab schedule.

   This CronJob is intended to run once every two hours. However, in some CSM 1.x
   releases, the CronJob schedule can run too frequently, preventing jobs from being
   properly scheuled.  Ensure the schedule looks as follows:

   ```bash
   ncn-m001# cat /etc/cron.d/cronjob-kicker
   0 */2 * * * root KUBECONFIG=/etc/kubernetes/admin.conf /usr/bin/cronjob_kicker.py
   ```

   > **NOTE:** Ensure the first character is `0` and not `*`, which will cause the CronJob
           to run every minute past the second hour, instead of once every two hours.

To learn more in general about Kubernetes CronJobs, refer to [https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/).
