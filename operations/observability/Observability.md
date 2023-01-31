# Install and Upgrade Observability Framework

The following Install and Upgrade Observability Framework topics are discussed in the following subsections.

- [Overview](#overview)
- [Automation of observability framework](#automation-of-observability-framework)
  - [Features](#automation-framework-features)
  - [Automation workflow](#automation-workflow)
  - [`systemd` services](#systemd-services)
- [IUF timing dashboard](#iuf-timing-dashboard)
  - [Features](#timing-dashboard-features)
  - [Prometheus metrics using Argo workflow](#prometheus-metrics-using-argo-workflow)
  - [Timing dashboard](#timing-dashboard)
- [GOSS tests for PIT and NCN](#goss-tests-for-pit-and-ncn)
  - [Overview](#goss-test-overview)
  - [Workflow](#goss-test-workflow)
  - [Log file format](#goss-test-log-file-format)
  - [Grok-exporter deployment, service and service-monitor](#grok-exporter-deployment-service-and-service-monitor)
  - [Configuration file for the grok-exporter](#configuration-file-for-the-grok-exporter)
  - [Prometheus metrics and Grafana dashboard](#prometheus-metrics-and-grafana-dashboard)
- [Error dashboards](#error-dashboards)
  - [Features](#error-dashboards-features)
  - [Types](#error-dashboards-types)

## Overview

The Install and Upgrade Observability Framework creates unified consistent requirements for each product
including assertions for Goss health checks, as well metrics and dashboards for health checks. The
framework also includes a unified consistent method to automatically track Time to Install (TTI) and
Time to Upgrade (TTU), as well as error and pattern count across clusters and product streams.

1. Establish a consistent framework for health checks/validation, metrics, and reporting for all product streams for install and upgrade observability.
   - Inside-out Views
   - Outside-in Views
   - Product stream health
1. Drill down health dashboard with roll up.
   - Aggregate checks - Problem/OK counts across each product stream.
   - Functional checks - Product stream functional Goss suites for key areas.
     For example, REST APIs, micro-services, Kubernetes, network, and database health for the specific product stream.
   - Granular checks - Individual Goss tests for component level health checks within a functional area of a given product stream.
     For example, management switch configuration verification, routing table checks on OS, gateway tests, and Container Network Interface (CNI) tests.
1. Boot, install, and upgrade duration monitoring.

   > This will do automatic calculation and reporting of both the time a given section of install/upgrade has taken, as well as metrics on how many GOSS tests results show OK versus PROBLEM status.

1. Time, node, product stream, capacity, and other dimension based health and performance insight.
1. Multi-Interval Continuous Health Checks.
   Define and implement regular automatic scheduled health checks to occur both during install and upgrade, as well as after the install or upgrade has been completed.
   The frequency needs to be determined but will likely include every six hours, once a day, and once a week.
1. Automate the deployment, installation, and configuration of the Install and Upgrade Observability framework in a CSM environment.
1. The automatic generation of configurable Grafana dashboards that provide key insights and KPIs into the frequency of errors
   across the complex systems, panels to visualize the outliers, and trends in the complex system  across different dimensions.

## Automation of observability framework

Grok-exporter, Prometheus, and Grafana get instantiated automatically on the Combined Install Media LiveCD for PIT dimension of metrics for error/debug/count.

### Automation framework features

- Prometheus, grok-exporter, and Grafana containers deployed initially on the `csm-pit` remote server for monitoring before systems are installed.
- Define and build IaC repo to store observability configuration.
- Define and build automations to update configuration of observability configuration when the IaC configuration repo is updated.
- Create an RPM with all the three containers and services for `csm-pit` and `csm-shared-pit` using Jenkins pipeline.
- Mount all of the log files from `csm-pit` to the container that the grok-exporter will parse.

### Automation workflow

![Automation framework workflow](../../img/operations/AutomationFrameworkWorkflow.png "Automation framework workflow")

### `systemd` services

Commands to check the status of `pit-observability` services which includes grok-exporter, Prometheus, and Grafana.

#### Check grok-exporter status on PIT node

(`pit#`) Command:

```bash
systemctl status grok-exporter.service
```

Example output:

```text
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

#### Check Prometheus status on PIT node

(`pit#`) Command:

```bash
systemctl status prometheus.service
```

Example output:

```text
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

#### Check Grafana status on PIT node

(`pit#`) Command:

```bash
systemctl status grafana.service
```

Example output:

```text
● grafana.service - Grafana
     Loaded: loaded (/usr/lib/systemd/system/grafana.service; enabled; vendor preset: disabled)
     Active: active (running) since Thu 2023-02-02 05:58:13 UTC; 1 day 12h ago
    Process: 97577 ExecStartPre=/usr/sbin/grafana.sh /run/grafana.service-pid /run/grafana.service-cid grafana (code=exited, status=0/SUCCESS)
    Process: 97720 ExecStart=/usr/bin/podman start grafana (code=exited, status=0/SUCCESS)
   Main PID: 97776 (conmon)
      Tasks: 2
     CGroup: /system.slice/grafana.service
             ├─ 97768 /usr/bin/fuse-overlayfs -o ,lowerdir=/var/lib/containers/storage/overlay/l/UOU2YMGV3WT2CIASNIEDBIY6OK:/var/lib/containers/storage/overlay/l/OTN7MKME4TAMZRF4URPIIIAXNI:/var/lib/>
             └─ 97776 /usr/bin/conmon --api-version 1 -c f45f33ad520fb278776cf528dab1fdf619f0b1323e672d29d866f728ce8e2589 -u f45f33ad520fb278776cf528dab1fdf619f0b1323e672d29d866f728ce8e2589 -r /usr/>

Feb 02 05:58:15 redbull-pit grafana[97776]: logger=live t=2023-02-02T05:58:15.25+0000 lvl=info msg="Initialized channel handler" channel=grafana/dashboard/uid/K-kKuniVk address=grafana/dashboard/uid>
Feb 02 05:58:25 redbull-pit grafana[97776]: logger=context traceID=00000000000000000000000000000000 userId=1 orgId=1 uname=admin t=2023-02-02T05:58:25.52+0000 lvl=info msg="Request Completed" method>
Feb 02 06:02:05 redbull-pit grafana[97776]: logger=live t=2023-02-02T06:02:05.57+0000 lvl=info msg="Initialized channel handler" channel=grafana/dashboard/uid/j3yZA2u7k address=grafana/dashboard/uid>
Feb 02 06:02:36 redbull-pit grafana[97776]: logger=live t=2023-02-02T06:02:36.3+0000 lvl=info msg="Initialized channel handler" channel=grafana/dashboard/uid/1Z_Xj0Cnz address=grafana/dashboard/uid/>
Feb 02 06:06:34 redbull-pit grafana[97776]: logger=live t=2023-02-02T06:06:34.73+0000 lvl=info msg="Initialized channel handler" channel=grafana/dashboard/uid/LATEST address=grafana/dashboard/uid/LA>
Feb 02 07:54:25 redbull-pit grafana[97776]: logger=context traceID=00000000000000000000000000000000 userId=1 orgId=1 uname=admin t=2023-02-02T07:54:25.07+0000 lvl=info msg="Request Completed" method>
Feb 02 14:21:56 redbull-pit grafana[97776]: logger=context traceID=00000000000000000000000000000000 userId=0 orgId=0 uname= t=2023-02-02T14:21:56.37+0000 lvl=info msg="Request Completed" method=GET >
Feb 02 14:34:30 redbull-pit grafana[97776]: logger=context traceID=00000000000000000000000000000000 userId=0 orgId=0 uname= t=2023-02-02T14:34:30.84+0000 lvl=info msg="Request Completed" method=GET >
Feb 02 14:35:01 redbull-pit grafana[97776]: logger=http.server t=2023-02-02T14:35:01.68+0000 lvl=info msg="Successful Login" User=admin@localhost
Feb 02 14:35:07 redbull-pit grafana[97776]: logger=context traceID=00000000000000000000000000000000 userId=1 orgId=1 uname=admin t=2023-02-02T14:35:07.37+0000 lvl=info msg="Request Completed" method>
```

## IUF timing dashboard

### Timing dashboard features

- Use Argo workflows to collect the install/upgrade timing details.
- Create Argo workflows to get metrics from the details available.
- Generate Prometheus install/upgrade timing metrics.
- Create Grafana dashboard using Prometheus metrics.

### Prometheus metrics using Argo workflow

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

## Goss tests for PIT and NCN

### Goss test overview

Goss test logs are scraped using Grok-exporter and visualization using captured data. CSM-testing
repository has Goss testing with all tests, suites and scripts to execute these Goss tests. We are using
the automated scripts to run Goss tests in batches. These batches are based on functionality or the check performed in CSM.

The single Goss test is a YAML file and a collection of these Goss tests can be used together by adding them in another YAML file. These suites can be invoked through the script created to get a log file with results for the tests.

For example, a Goss test to validate expected Kubernetes nodes exists using the `kubectl` command based on node names pulled from `/etc/hosts` file. The log files generated from automated scripts that run a set of test suites are used.

Running the automated scripts using the complete path of script like `/opt/cray/tests/install/ncn/automated/ncn-healthcheck`.

### Goss test workflow

![Goss test workflow](../../img/operations/GossWorkflow.png "Goss Workflow")

### Goss test log file format

Individual lines of logs are in the following format for each node or PIT node, test name, and source:

```json
{
  "log_timestamp": "20230118_094205.821955",
  "Product": "CSM",
  "log_script": "print_goss_json_results.py",
  "log_message": "Test result",
  "Description": "Validates that 'cray --version' is available and executes successfully on the local system.",
  "Execution Time (nanoseconds)": 1312368478,
  "Execution Time (seconds)": 1.312368478,
  "Node": "ncn-m001",
  "Result Code": 0,
  "Result String": "PASS",
  "Source": "http://ncn-m001.hmn:8997/ncn-healthcheck-master",
  "Test Name": "Command 'cray --version' Available",
  "Test Summary": "Command: command_available_1_cray_version: exit-status: matches expectation: [0]"
}
```

### Grok-exporter deployment, service, and service-monitor

The deployment for the grok-exporter was created and set the node affinity to `ncn-m001` for NCN deployment of grok-exporter.
The service for the grok-exporter is created for access at port `9144`. Service-monitor is created for Prometheus to access the metrics that are created by the grok-exporter.

### Configuration file for the grok-exporter

Created the configuration file for the grok-exporter to parse the Goss test log file and make metrics from them.
We are using grok-exporter `config_version` 3 for this task and matching log expressions with `regex`.

The following is the example configuration passed to the grok-exporter to get metrics:

```yaml
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

After the preceding steps the `goss_tests` metrics are seen in Prometheus when Goss tests are run. Using these metrics, Grafana dashboards are created to shows the Goss tests details visually.

Goss test dashboard features:

- The dashboard as drop-downs for product, suite, and tests.
- By default, all products, suites and tests are selected for overall Goss tests result.
- The overall product result, total number of the products, products passed, products failed, and its execution time is seen.
- Suite results and test results are seen from the dashboard.
- Node-wise test result are seen with failed nodes, passed nodes, and the suite/test description.

![Goss test dashboard](../../img/operations/GossTestsDashboard.png "Goss Test Dashboard")

## Error dashboards

Error dashboards provide key glance insights as to where and what is broken and needs attention. This works for both internal HPE environments and clusters as well as is a containerized shippable solution that customers can use as well.

The automatic generation of the desired Prometheus grok-exporter configuration based upon passing in a set of `regex` patterns to detect.
This includes but is not limited to `regex` patterns to match and generate metrics on phases of manual administrator steps, as well as phases of installation scripts and automation.

### Error dashboards features

- Automate Grafana dashboards with error and failure message during CSM upgrade and install.
- Create dashboard for issue comparison across multiple dimensions and clusters.
- Monitor ConMan logs from `csm-pit`.
- Quantify the results and provide easy at-glance reports, and dashboards to give us confidence about the health of a platform at any time.
- Groks log files for errors and surface them
- Create the Trend, Error, and Alert frequency dashboard.

### Error dashboards types

Dashboard tracking different types of errors during install/upgrade.

- Frequency of message about known issues dashboard
- CSM environments install progress dashboard
- USB Device error tracking dashboard
- Boot PXE error tracking dashboard
- Boot DHCP error tracking dashboard

![Error Dashboard](../../img/operations/ErrorDashboard1.png "CSM Environments Install Progress Dashboard")

![Error Dashboard](../../img/operations/ErrorDashboard2.png "Frequency of message about known issues Dashboard")
