# Clean Up Logs After a BOA Kubernetes Job

> **`NOTE`** This section is for Boot Orchestration Service \(BOS\) v1 only. BOS v2 does not use
> Boot Orchestration Agent \(BOA\) jobs and does not require cleanup.

Delete log entries from previous boot orchestration jobs. BOS launches a BOA Kubernetes job.
BOA then launches a [Configuration Framework Service \(CFS\)](../../glossary.md#configuration-framework-service-cfs) session,
resulting in a CFS-BOA Kubernetes job. Thus, there are two separate sets of jobs that can be removed.

Deleting log entries creates more space and helps improve the usability of viewing logs.

## Prerequisites

- A Boot Orchestration Service \(BOS\) session has finished.

## Procedure

1. (`ncn-mw#`) List the current BOA jobs.

   ```bash
   kubectl get jobs -n services | grep boa
   ```

   Example output:

   ```text
   boa-2c2211aa-9876-4aa7-92e2-c8a64d9bd9a6                    1/1           6m58s      13d
   boa-51918dbd-bde2-4836-9500-2a7bad93787c                    1/1           65s        9d
   boa-6fc198cc-486b-4340-81e0-f17c199a1ec6                    1/1           97s        9d
   boa-8656f64d-baa9-43ea-9e11-2a0b27e89037                    1/1           17m        13d
   boa-86b78489-1d76-4957-9c0e-a7b1d6665c35                    1/1           15m        13d
   boa-a939bd32-9d27-433f-afc2-735e77ec8e58                    1/1           13m        13d
   boa-e9adfa63-24dc-4da6-b870-b3535adf0bcc                    1/1           7m53s      13d
   ```

1. (`ncn-mw#`) Delete any jobs that are no longer needed.

   Do not delete any jobs that are currently running.

   ```bash
   kubectl delete jobs BOA_JOB_ID
   ```
