# Install and Upgrade Observability Framework

## Overview

Install and Upgrade Observability Framework creates unified consistent requirements for each product including assertions for Goss health checks, as well metrics and dashboards for health checks. The framework also includes a unified consistent method to automatically track Time to Install (TTI) and Time to Upgrade (TTU), as well as error and pattern count across clusters and product streams.

1. Establish a consistent framework for health checks/validation, metrics, and reporting for all product streams for install and upgrade observability.
   - Inside-out Views
   - Outside-in Views
   - Product stream health

2. Drill down health dashboard with roll up.
   - Aggregate checks - Problem/OK counts across each product stream.
   - Functional checks - Product stream functional Goss suites for key areas.
     For example, REST APIs, micro-services, K8s, network, and database health for the specific product stream.
   - Granular checks - Individual Goss tests for component level health checks within a functional area of a given product stream.
     For example, management switch configuration verification, routing table checks on OS, gateway tests, and Container Network Interface (CNI) tests.

3. Boot, install, and upgrade duration monitoring.
   
   This will do automatic calculation and reporting of both the time a given section of install/upgrade has taken, as well as metrics on how many GOSS tests results show OK versus PROBLEM status.

4. Time, node, product stream, capacity, and other dimension based health and performance insight.

5. Multi-Interval Continuous Health Checks.
   Define and implement regular automatic scheduled health checks to occur both during install and upgrade, as well as after the install or upgrade has been completed.
   The frequency needs to be determined but will likely include every six hours, once a day, and once a week.

6. Automate the deployment, installation, and configuration of the Install and Upgrade Observability framework in a CSM environment. 

7. The automatic generation of configurable Grafana dashboards that provide key insights and KPIs into the frequency of errors across the complex systems, panels to visualize the outliers, and trends in the complex system  across different dimensions.

The following IUF topics are discussed in the following subsections.

- [Automation of Observability framework](#automation-of-observability-framework)
  - [Features](#automation-framework-features)
  - [Automation workflow](#automation-workflow)
  - [Systemd services](#systemd-services)
- [IUF Timing dashboard](#iuf-timing-dashboard)
  - [Features](#timing-dashboard-features)
  - [Prometheus metrics using Argo Workflow](#prometheus-metrics-using-argo-workflow)
  - [Timing Dashboard](#timing-dashboard)
- [GOSS Tests for PIT and NCN](#goss-tests-for-pit-and-ncn)
  - [Overview](#goss-test-overview)
  - [Workflow](#workflow)
  - [Log file format](#log-file-format)
  - [Grok-exporter deployment, service and service-monitor](#grok-exporter-deployment-service-and-service-monitor)
  - [Configuration file for the grok-exporter](#configuration-file-for-the-grok-exporter)
  - [Prometheus metrics and Grafana dashboard](#prometheus-metrics-and-grafana-dashboard)
- [Error Dashboards](#error-dashboard)
  - [Features](#error-dashboards-features)
  - [Error Dashboards](#error-dashboards)

## Automation of Observability framework

Grok-exporter, Prometheus, and Grafana get instantiated automatically on the Combined Install Media LiveDVD for PIT dimension of metrics for error/debug/count.

### Automation framework features

- Prometheus, grok-exporter, and Grafana containers deployed initially on the `csm-pit` remote server for monitoring before systems are installed.
- Define and build IaC repo to store observability configuration.
- Define and build automations to update configuration of observability configuration when the IaC configuration repo is updated.
- Create an RPM with all the three containers and services for `csm-pit` and `csm-shared-pit` using Jenkins pipeline.
- Mount all the log files from CSM-PIT to container which grok-exporter will parse.

### Automation workflow

![Automation framework workflow](../../img/operations/AutomationFrameworkWorkflow.png "Automation framework workflow")

### `systemd` services

Command to check the status of `pit-observability` services which includes grok-exporter, Prometheus, and Grafana.

```bash
systemctl status grok-exporter.service
● grok-exporter.service - Grok-exporter
     Loaded: loaded (/usr/lib/systemd/system/grok-exporter.service; enabled; vendor preset: disabled)
     Active: active (running) since Wed 2023-01-25 00:04:36 UTC; 6h ago
   Main PID: 22381 (conmon)
      Tasks: 2
     CGroup: /system.slice/grok-exporter.service
             ├─ 22373 /usr/bin/fuse-overlayfs -o ,lowerdir=/var/lib/containers/storage/overlay/l/QHMZY5A5LJYDXJ64OE3VRABE3W:/var/lib/containers/storage/over>
             └─ 22381 /usr/bin/conmon --api-version 1 -c 75b89abbe71f1d55033e42305dd69735f952b8b3eb29eb7cf1064dc159c9ae66 -u 75b89abbe71f1d55033e42305dd6973>

Jan 25 00:04:35 redbull-pit grok-exporter.sh[22276]:             "IOMaximumBandwidth": 0,
Jan 25 00:04:35 redbull-pit grok-exporter.sh[22276]:             "CgroupConf": null
Jan 25 00:04:35 redbull-pit grok-exporter.sh[22276]:         }
Jan 25 00:04:35 redbull-pit grok-exporter.sh[22276]:     }
Jan 25 00:04:35 redbull-pit grok-exporter.sh[22276]: ]
Jan 25 00:04:36 redbull-pit podman[22324]: 2023-01-25 00:04:36.016806447 +0000 UTC m=+0.306557966 container init 75b89abbe71f1d55033e42305dd69735f952b8b3eb2>
Jan 25 00:04:36 redbull-pit podman[22324]: 2023-01-25 00:04:36.07000859 +0000 UTC m=+0.359760105 container start 75b89abbe71f1d55033e42305dd69735f952b8b3eb2>
Jan 25 00:04:36 redbull-pit podman[22324]: grok-exporter
Jan 25 00:04:36 redbull-pit grok-exporter[22381]: Starting server on http://redbull-pit:9144/metrics
Jan 25 00:04:36 redbull-pit systemd[1]: Started Grok-exporter.
```

```bash
systemctl status prometheus.service
● prometheus.service - Prometheus
     Loaded: loaded (/usr/lib/systemd/system/prometheus.service; enabled; vendor preset: disabled)
     Active: active (running) since Wed 2023-01-25 00:05:47 UTC; 6h ago
   Main PID: 25680 (conmon)
      Tasks: 2
     CGroup: /system.slice/prometheus.service
             ├─ 25674 /usr/bin/fuse-overlayfs -o ,lowerdir=/var/lib/containers/storage/overlay/l/NZKANI3GOO3KXVE2HIZI33JUTY:/var/lib/containers/storage/over>
             └─ 25680 /usr/bin/conmon --api-version 1 -c 8221fc0337a5bc8ac706ffeb270c18719caf2c02de8402a047670e578010921f -u 8221fc0337a5bc8ac706ffeb270c187>

Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.048Z caller=main.go:993 level=info fs_type=TMPFS_MAGIC
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.048Z caller=main.go:996 level=info msg="TSDB started"
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.048Z caller=main.go:1177 level=info msg="Loading configuration file" filename=/etc/pro>
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.052Z caller=main.go:1214 level=info msg="Completed loading of configuration file" file>
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.052Z caller=main.go:957 level=info msg="Server is ready to receive web requests."
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.052Z caller=manager.go:937 level=info component="rule manager" msg="Starting rule mana>
Jan 25 03:06:09 redbull-pit prometheus[25680]: ts=2023-01-25T03:06:09.240Z caller=compact.go:519 level=info component=tsdb msg="write block" mint=1674605167>
Jan 25 03:06:09 redbull-pit prometheus[25680]: ts=2023-01-25T03:06:09.242Z caller=head.go:840 level=info component=tsdb msg="Head GC completed" duration=1.3>
Jan 25 05:00:09 redbull-pit prometheus[25680]: ts=2023-01-25T05:00:09.261Z caller=compact.go:519 level=info component=tsdb msg="write block" mint=1674612007>
Jan 25 05:00:09 redbull-pit prometheus[25680]: ts=2023-01-25T05:00:09.263Z caller=head.go:840 level=info component=tsdb msg="Head GC completed" duration=1.7
```

```bash
systemctl status prometheus.service
● prometheus.service - Prometheus
     Loaded: loaded (/usr/lib/systemd/system/prometheus.service; enabled; vendor preset: disabled)
     Active: active (running) since Wed 2023-01-25 00:05:47 UTC; 6h ago
   Main PID: 25680 (conmon)
      Tasks: 2
     CGroup: /system.slice/prometheus.service
             ├─ 25674 /usr/bin/fuse-overlayfs -o ,lowerdir=/var/lib/containers/storage/overlay/l/NZKANI3GOO3KXVE2HIZI33JUTY:/var/lib/containers/storage/over>
             └─ 25680 /usr/bin/conmon --api-version 1 -c 8221fc0337a5bc8ac706ffeb270c18719caf2c02de8402a047670e578010921f -u 8221fc0337a5bc8ac706ffeb270c187>

Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.048Z caller=main.go:993 level=info fs_type=TMPFS_MAGIC
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.048Z caller=main.go:996 level=info msg="TSDB started"
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.048Z caller=main.go:1177 level=info msg="Loading configuration file" filename=/etc/pro>
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.052Z caller=main.go:1214 level=info msg="Completed loading of configuration file" file>
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.052Z caller=main.go:957 level=info msg="Server is ready to receive web requests."
Jan 25 00:05:47 redbull-pit prometheus[25680]: ts=2023-01-25T00:05:47.052Z caller=manager.go:937 level=info component="rule manager" msg="Starting rule mana>
Jan 25 03:06:09 redbull-pit prometheus[25680]: ts=2023-01-25T03:06:09.240Z caller=compact.go:519 level=info component=tsdb msg="write block" mint=1674605167>
Jan 25 03:06:09 redbull-pit prometheus[25680]: ts=2023-01-25T03:06:09.242Z caller=head.go:840 level=info component=tsdb msg="Head GC completed" duration=1.3>
Jan 25 05:00:09 redbull-pit prometheus[25680]: ts=2023-01-25T05:00:09.261Z caller=compact.go:519 level=info component=tsdb msg="write block" mint=1674612007>
Jan 25 05:00:09 redbull-pit prometheus[25680]: ts=2023-01-25T05:00:09.263Z caller=head.go:840 level=info component=tsdb msg="Head GC completed" duration=1.7>
```

## IUF Timing dashboard

### Timing dashboard features

- Using argo workflow to collect the install/upgrade timing details.
- Created argo workflow to get metrics from the details available.
- Generated Prometheus install/upgrade timing metrics.
- Created Grafana dashboard using Prometheus metrics.


### Prometheus metrics using Argo Workflow

Able to get the start-time and end-time as Prometheus labels for the operations using Argo metrics approach. Added record time stamp task at the beginning and end of the operation template using timestamp output parameter as an input to the metrics.

Metrics captured for the operations:

- start time
- end time
- duration
- status
- product name
- product version

Metrics captured for the stage:

- stage name
- stage type
- stage start time (derived from min(start time of the all the operations presented in the stage)
- stage end time (derived from max(start time of the all the operations presented in the stage)
- stage duration (stage end time - stage start time)
- stage status (derived from all the operations status)

Metrics captured for the product: 
- product name
- product start time (derived from the start time of the process-media stage)
- product end time (derived from the start time of the post-install-check stage)
- product status (derived from the status of the stage)


### Timing dashboard

- Created dynamic top-down and bottom-up dashboard to track install/upgrade status of any product, stage and operation.
- Dashboard calculates the execution time for the install/ upgrade of any product, stage and operation.
- The status of the install/ upgrade for product, stage and operation are Failed/Succeeded.
- There is dropdown for selection of the product, stage and operation. By default all are selected.
- Separate sections created in dashboard to see the details of product, stage and operation.
- Graph showing duration for each stage & operation is added.

![IUF timing dashboard](../../img/operations/TimingDashboard.png "Timing Dashboard")



## GOSS Tests for PIT and NCN

### Goss test overview

We are scraping goss test logs using grok exporter and visualization using captured data. CSM-testing repository has goss-testing with all tests, suites and scripts to execute these goss tests. We are using the automated scripts to run goss tests in batches. These batches are based on functionality or the check performed in CSM. 

The single goss test is an yaml file and a collection of these goss tests can be used together by adding them in another yaml file. These suites can be invoked through the script created to get a log file with results for the tests.

Example - Goss test to validate expected Kubernetes nodes exist using the kubectl command based on node names pulled from /etc/hosts file. We are using the log files generated from automated scripts which run a set of test suites.

Running the automated scripts using the complete path of script like `/opt/cray/tests/install/ncn/automated/ncn-healthcheck`.


### Workflow

![Goss test workflow](../../img/operations/GossWorkflow.png "Goss Workflow")


### Log file format

Individual lines of logs are in the following format for each node or PIT node, test name, and source:

```bash
{"log_timestamp": "20230118_094205.821955", "Product": "CSM", "log_script": "print_goss_json_results.py", "log_message": "Test result", "Description": "Validates that 'cray --version' is available and executes successfully on the local system.", "Execution Time (nanoseconds)": 1312368478, "Execution Time (seconds)": 1.312368478, "Node": "ncn-m001", "Result Code": 0, "Result String": "PASS", "Source": "http://ncn-m001.hmn:8997/ncn-healthcheck-master", "Test Name": "Command 'cray --version' Available", "Test Summary": "Command: command_available_1_cray_version: exit-status: matches expectation: [0]"}
```


### Grok-exporter deployment, service and service-monitor

We created the deployment for grok-exporter and set the node affinity to ncn-m001 for NCN deployment of grok-exporter. The service for grok-exporter is createdfor access at port `9144`. Service-monitor is created for prometheus to access the metrics that are created by grok-exporter.


### Configuration file for the grok-exporter

Created the config file for the grok-exporter to parse the goss test log file and make metrics from them. 
We are using grok-exporter config version 3 config for this task and matching log expressions with regex.

The following is the example config passed to grok-exporter to get metrics:
```bash
apiVersion: v1
kind: ConfigMap
metadata:
  name: example_name
  namespace: example_namespace
data:
  config.yml: |-
    global:
      config_version: 3
    input:
      type: file
      paths: 
      - /logs/goss_tests/*
      fail_on_missing_logfile: false
    grok_patterns:
      - 'REGEX [regular].*expression'
      - 'EXAMPLE [aA-zZ-].*'
    metrics:
      - type: gauge
        name: example_metric
        help: EXAMPLE METRIC HELP
        match: '{"log_file": "%{REGEX:logfile}", "TEST": "%{EXAMPLE:ex}"}'
        value: '{{`{{.logfile}}`}}'
        labels:
          example_test: '{{`{{.ex}}`}}'
    server:
     port: 9144
```


### Prometheus metrics and Grafana dashboard

After the above steps the `goss_tests` metrics are seen in prometheus when goss tests are run. Using these metrics we created the Grafana dashboard which shows us the goss tests details visually.

Goss test dashboard features
- The dashboard as dropdowns for product, suite, and tests.
- By default, all products, suites and tests are selected for overall Goss tests result.
- The overall product result, total number of the products, products passed, products failed, and its execution time is seen.
- Suite results and test results are seen from the dashboard.
- Node-wise test result are seen with failed nodes, passed nodes, and the suite/test description.

![Goss test dashboard](../../img/operations/GossTestsDashboard.png "Goss Test Dashboard")

## Error dashboards

Error dashboards provide key glance insights as to where and what is broken and needs attention. This works for both internal HPE environments and clusters as well as is a containerized shippable solution that customers can use as well.

The automatic generation of the desired  prometheus grok exporter configuration based upon passing in a set of regex patterns to detect. This includes but is not limited to regex patterns to match and generate metrics on phases of manual Administrator steps, as well as phases of installation scripts and automation. 

### Error dashboards features

- Automate Grafana dashboards with error and failure message during CSM upgrade and install.
- Create Dashboard for Issue Comparison across multiple dimensions and Clusters.
- Monitors conman logs from csm-pit.  
- Quantify the results and provide easy at-glance reports, and dashboards to give us confidence about the health of a platform at any time.
- Groks log files for errors and surface them
- Creation of Trend, Error, and Alert frequency dashboard.

### Error dashboards

Dashboard tracking different types of errors during Install/Upgrade.
- Frequency of message about known issues dashboard
- CSM environments install progress dashboard
- USB Device error tracking dashboard
- Boot PXE error tracking dashboard 
- Boot DHCP error tracking dashboard

![Error Dashboard](../../img/operations/ErrorDashboard1.png "CSM Environments Install Progress Dashboard")

![Error Dashboard](../../img/operations/ErrorDashboard2.png "Frequency of message about known issues Dashboard")
